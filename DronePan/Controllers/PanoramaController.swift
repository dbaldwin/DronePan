/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

import DJISDK
import CocoaLumberjackSwift

protocol PanoramaControllerDelegate {
    func postUserMessage(message: String)

    func postUserWarning(warning: String)

    func panoStarting()

    func panoStopping()

    func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float)

    func aircraftYawChanged(yaw: Float)

    func aircraftSatellitesChanged(count: Int)

    func aircraftDistanceChanged(distance: CLLocationDistance)

    func aircraftAltitudeChanged(altitude: Float)

    func panoCountChanged(count: Int, total: Int)

    func panoAvailable(available: Bool)
}

class PanoramaController: Analytics, SystemUtils, ModelUtils, ModelSettings {
    var delegate: PanoramaControllerDelegate?

    var cameraController: CameraController?
    var remoteController: RemoteController?
    var gimbalController: GimbalController?
    var flightController: FlightController?

    var lastGimbalPitch: Float = 0.0
    var lastGimbalYaw: Float = 0.0
    var lastGimbalRoll: Float = 0.0
    var lastACYaw: Float = 0.0

    var panoRunning: (state:Bool, ok:Bool) = (state: false, ok: true) {
        didSet {
            if panoRunning.state {
                self.delegate?.panoStarting()
            } else {
                self.gimbalController?.status = .Stopping

                self.cameraController?.status = .Stopping

                self.delegate?.panoStopping()
            }
        }
    }

    var model: String?
    var type: ProductType?

    var product: DJIBaseProduct? {
        didSet {
            self.model = product!.model

            if product! is DJIAircraft {
                self.type = .Aircraft
            } else if product! is DJIHandheld {
                self.type = .Handheld
            } else {
                self.type = .Unknown
            }
        }
    }

    let gimbalDispatchGroup = ActiveAwareDispatchGroup(name: "gimbal")
    let cameraDispatchGroup = ActiveAwareDispatchGroup(name: "camera")
    let aircraftDispatchGroup = ActiveAwareDispatchGroup(name: "aircraft")

    var totalCount = 0

    var currentCount = 0 {
        didSet {
            self.delegate?.panoCountChanged(currentCount, total: totalCount)
        }
    }

    var currentHeading = 0.0

    func pitchesForLoop(maxPitch maxPitch: Double, maxPitchEnabled: Bool, type: ProductType, rowCount: Int) -> Array<Double> {
        let min: Double = -90
        let max: Double = maxPitchEnabled ? maxPitch : 0
        let count = rowCount

        let interval = (max - min) / Double(count)
        
        let values = (0 ..< count).map({
            max - (Double($0) * interval)
        })

        return type == .Aircraft ? values : values.reverse()
    }

    func yawAngles(count count: Int, heading: Double) -> [Double] {
        let yaw_angle = 360.0 / Double(count)

        return (0 ..< count).map({
            heading + (yaw_angle * Double($0 + 1))
        }).map({
            (angle: Double) -> Double in
            angle > 360 ? angle - 360.0 : angle
        })
    }
}

// MARK: - Main Logic

extension PanoramaController {
    private func checkProduct() -> Bool {
        if let _ = self.product, _ = self.model, _ = self.type {
            return true
        } else {
            DDLogWarn("Pano started without product")

            self.delegate?.postUserMessage("Unable to find DJI Product")
        }

        return false
    }

    private func checkSpace() -> Bool {
        if let cameraController = self.cameraController, model = self.model {
            let panoCount = numberOfImagesForCurrentSettings(model)

            if (!cameraController.hasSpaceForPano(panoCount)) {
                DDLogDebug("Not enough space for \(panoCount) images")

                self.delegate?.postUserMessage("Not enough space on card for \(panoCount) images")

                return false
            }

            return true
        }

        return false
    }

    private func checkRCMode() -> Bool {
        if let type = self.type, model = self.model, remoteController = self.remoteController {
            if (!gimbalYawSelected(model, type: type)) {
                if (!isPhantom4(model)) {
                    if (!(remoteController.mode == .Function)) {
                        DDLogDebug("Not in F mode")

                        self.delegate?.postUserMessage("Please set RC Flight Mode to F first")

                        return false
                    }
                } else {
                    if (!(remoteController.mode == .Positioning)) {
                        DDLogDebug("Not in P mode")
                        
                        self.delegate?.postUserMessage("Please set RC Flight Mode to P first")
                        
                        return false
                    }
                }
            }
        }

        return true
    }

    private func checkGimbal() -> Bool {
        if let _ = self.gimbalController {
            return true
        } else {
            DDLogWarn("Pano started without gimbal")

            self.delegate?.postUserMessage("Unable to find a gimbal")
        }

        return false
    }

    private func checkCamera() -> Bool {
        if let _ = self.cameraController {
            return true
        } else {
            DDLogWarn("Pano started without camera")
            
            self.delegate?.postUserMessage("Unable to find a camera")
        }
        
        return false
    }
    
    private func checkRemote() -> Bool {
        if let type = self.type {
            if type == .Aircraft {
                if let _ = self.remoteController {
                    return true
                } else {
                    DDLogWarn("Pano started without remote")
            
                    self.delegate?.postUserMessage("Unable to find a remote control")

                    return false
                }
            }
        }
        
        return true
    }
    
    private func checkFC() -> Bool {
        if let type = self.type {
            if (type == .Aircraft) {
                if let _ = self.flightController {
                    return true
                } else {
                    DDLogWarn("Pano started without FC")

                    self.delegate?.postUserMessage("Unable to find a flight controller")
                }

                return false
            }
        }

        return true
    }

    func gimbalYawSelected(model: String, type: ProductType) -> Bool {
        // Only aircraft support ac yaw
        if type != .Aircraft {
            return true
        }
        
        // Only inspire supports gimbal yaw
        if !isInspire(model) {
            return false
        }
            
        return acGimbalYaw(model)
    }
    
    func start() {
        if (!checkProduct()) {
            return
        }

        if (!checkCamera()) {
            return
        }
        
        if (!checkSpace()) {
            return
        }

        if (!checkGimbal()) {
            return
        }

        if (!checkFC()) {
            return
        }
        
        if (!checkRemote()) {
            return
        }
        
        if (!checkRCMode()) {
            return
        }

        trackEvent(category: "Panorama", action: "Range Extension", label: "Starting panoarama with model \(self.model), camera \(self.cameraController?.camera.displayName) range extension \(self.gimbalController?.supportsRangeExtension) and max pitch \(self.gimbalController?.getMaxPitch())")
        
        self.panoRunning = (state: true, ok: true)

        self.delegate?.postUserMessage("Panorama starting")

        if let type = self.type, model = self.model {
            let gimbalYaw = gimbalYawSelected(model, type: type)
            
            if (!gimbalYaw) {
                self.flightController?.setControlModes()
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(startDelay(self.model!)) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.doPanoLoop(gimbalYaw)
                }
            }
        }
    }

    func stop() {
        self.delegate?.postUserMessage("Panorama stopping. Please wait ...")

        self.panoRunning = (state: false, ok: true)
    }

    // Marked objc to allow override from test - can only override methods that are in extensions when they are marked objc in swift for now
    @objc func doPanoLoop(gimbalYaw: Bool) {
        if let model = self.model, type = self.type {
            if type == .Unknown {
                DDLogError("Panorama started with unknown type")

                return
            }

            let pitches = self.pitchesForLoop(maxPitch: Double(maxPitch(model)),
                                              maxPitchEnabled: maxPitchEnabled(model),
                                              type: type, rowCount: numberOfRows(model))

            if type == .Handheld {
                // TODO: should also be done for gimbal yaw of AC when that is in place
                self.currentHeading = 0
            }

            let headingForYaws = gimbalYaw ? 0 : headingTo360(self.currentHeading)
            
            let yaws = self.yawAngles(count: photosPerRow(model), heading: headingForYaws)
            let nadirYaws = self.yawAngles(count: nadirCount(model), heading: headingForYaws)

            DDLogInfo("Starting with yaws: \(yaws)")

            self.totalCount = numberOfImagesForCurrentSettings(model)
            self.currentCount = 0

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                self.setupForLoop()

                // Loop through the yaws
                DDLogDebug("PanoLoop: YawLoop - main")
                self.runYawLoop(yaws, pitches: pitches, gimbalYaw: gimbalYaw)

                // Loop through the zenith/nadir yaws
                DDLogDebug("PanoLoop: YawLoop - nadir")
                self.runYawLoop(nadirYaws, pitches: [-90.0], gimbalYaw: gimbalYaw)

                // Check state and inform user
                self.informUserEndOfLoop()

                self.resetAfterLoop()
            })
        }
    }
    
    func setupForLoop() {
        DDLogDebug("PanoLoop: starting")

        // Set camera mode
        DDLogDebug("PanoLoop: setPhotoMode")
        self.setPhotoMode()
        
        // Reset gimbal - this will reset the gimbal yaw in case the user has changed it outside of DronePan
        DDLogDebug("PanoLoop: resetGimbal")
        self.resetGimbal()
    }
    
    func resetAfterLoop() {
        DDLogDebug("PanoLoop: reset gimbal")
        self.resetGimbal()
        
        DDLogDebug("PanoLoop: END")
    }

    func informUserEndOfLoop() {
        if (self.panoRunning.state) {
            self.delegate?.postUserMessage("Completed pano")
            
            self.panoRunning = (state: false, ok: true)
        } else {
            // The panorama has been aborted
            DDLogDebug("PanoLoop: was stopped OK");
            
            if (self.panoRunning.ok) {
                self.delegate?.postUserMessage("Pano stopped successfully")
            } else {
                self.trackEvent(category: "Panorama", action: "Running", label: "Stopped by system")
                
                self.delegate?.postUserMessage("Pano stopped")
            }
        }
    }
    
    func runPitchForYaw(yaw: Double, pitch: Double) {
        if !self.panoRunning.state {
            return
        }
        
        DDLogDebug("PanoLoop: YawLoop: \(yaw), PitchLoop: \(pitch)- set pitch")
        self.setPitch(pitch)
        
        if !self.panoRunning.state {
            return
        }
        
        DDLogDebug("PanoLoop: YawLoop: \(yaw), PitchLoop: \(pitch)- take photo")
        self.takeASnap()
    }
    
    func runPitchesForYaw(yaw: Double, pitches: [Double]) {
        if !self.panoRunning.state {
            return
        }

        for pitch in pitches {
            DDLogDebug("PanoLoop: YawLoop: \(yaw), PitchLoop: \(pitch)")
            
            self.runPitchForYaw(yaw, pitch: pitch)
        }
    }
    
    func runYawLoop(yaws: [Double], pitches: [Double], gimbalYaw: Bool) {
        if !self.panoRunning.state {
            return
        }

        for yaw in yaws {
            DDLogDebug("PanoLoop: YawLoop: \(yaw)")
    
            self.runPitchesForYaw(yaw, pitches: pitches)

            if (!gimbalYaw) {
                DDLogDebug("PanoLoop: YawLoop: \(yaw) - AC yaw")
                self.setAcYaw(yaw)
            } else {
                DDLogDebug("PanoLoop: YawLoop: \(yaw) - gimbal yaw")
                self.setYaw(yaw)
            }
        } // End yaw loop
    }

    func setPhotoMode() {
        DDLogDebug("Set photo mode")

        if let c = self.cameraController {
            self.cameraDispatchGroup.enter()
            DDLogDebug("Set photo mode - send")
            c.setPhotoMode()
            self.cameraDispatchGroup.wait()
            DDLogDebug("Set photo mode - done")
        }
    }

    func resetGimbal() {
        DDLogDebug("Reset gimbal")

        if let c = self.gimbalController {
            self.gimbalDispatchGroup.enter()
            DDLogDebug("Reset gimbal - send")
            c.reset()
            self.gimbalDispatchGroup.wait()
            DDLogDebug("Reset gimbal - done")
        }
    }

    func setPitch(pitch: Double) {
        DDLogDebug("Set pitch \(pitch)")

        if let c = self.gimbalController {
            self.gimbalDispatchGroup.enter()
            DDLogDebug("Set pitch \(pitch) - send")
            c.setPitch(Float(pitch))
            self.gimbalDispatchGroup.wait()
            DDLogDebug("Set pitch \(pitch) - done")
        }
    }

    func setAcYaw(yaw: Double) {
        DDLogDebug("Set AC yaw \(yaw)")
        
        if let c = self.flightController {
            self.aircraftDispatchGroup.enter()
            DDLogDebug("Set AC yaw \(yaw) - send")
            c.yawTo(yaw)
            self.aircraftDispatchGroup.wait()
            DDLogDebug("Set AC yaw \(yaw) - done")
        }
    }

    func setYaw(yaw: Double) {
        DDLogDebug("Set yaw \(yaw)")

        if let c = self.gimbalController {
            self.gimbalDispatchGroup.enter()
            DDLogDebug("Set yaw \(yaw) - send")
            c.setYaw(Float(yaw))
            self.gimbalDispatchGroup.wait()
            DDLogDebug("Set yaw \(yaw) - done")
        }
    }

    func takeASnap() {
        DDLogDebug("Take a snap");

        if let c = self.cameraController {
            self.cameraDispatchGroup.enter()
            DDLogDebug("Take a snap - send")
            c.takeASnap()
            self.cameraDispatchGroup.wait()
            DDLogDebug("Take a snap - done")
        }
    }
}

// MARK: - Camera Controller Delegate

extension PanoramaController: CameraControllerDelegate {
    func setCamera(camera: DJICamera?, preview: VideoControllerDelegate? = nil) {
        if let camera = camera {
            self.cameraController = CameraController(camera: camera)
            self.cameraController!.delegate = self

            if let preview = preview {
                self.cameraController!.videoDelegate = preview
            }
        } else {
            self.cameraController = nil
        }
    }

    func cameraControllerCompleted(shotTaken: Bool) {
        DDLogDebug("Camera signalled complete with shot taken \(shotTaken)")

        if (shotTaken) {
            self.currentCount += 1
        }

        dispatch_async(droneCommandsQueue()) {
            self.cameraDispatchGroup.leave()
        }
    }

    func cameraControllerAborted(reason: String) {
        DDLogWarn("Camera signalled abort \(reason)")

        self.delegate?.postUserMessage(reason)

        dispatch_async(droneCommandsQueue()) {
            self.trackEvent(category: "Panorama", action: "Camera", label: "Aborted \(reason)")

            self.panoRunning = (state: false, ok: false)

            self.cameraDispatchGroup.leave()
        }
    }

    func cameraControllerStopped() {
        dispatch_async(droneCommandsQueue()) {
            self.cameraDispatchGroup.leaveIfActive()
        }
    }

    func cameraControllerInError(reason: String) {
        DDLogWarn("Camera signalled error \(reason)")

        self.trackEvent(category: "Panorama", action: "Camera", label: "Error \(reason)")

        self.delegate?.postUserMessage(reason)

        if panoRunning.state {
            dispatch_async(droneCommandsQueue(), {
                self.panoRunning = (state: false, ok: false)
            })
        }

        self.delegate?.panoAvailable(false)
    }

    func cameraControllerOK(fromError: Bool) {
        DDLogDebug("Camera signalled OK")

        if (fromError) {
            self.delegate?.postUserMessage("Camera is ready")
        }

        self.delegate?.panoAvailable(true)
    }

    func cameraControllerReset() {
        DDLogDebug("Camera signalled reset")

        dispatch_async(droneCommandsQueue()) {
            self.cameraDispatchGroup.leave()
        }
    }

    func cameraControllerNewMedia(filename: String) {
        DDLogInfo("Shot taken: \(filename) ACY: \(lastACYaw) GP: \(lastGimbalPitch) GY: \(lastGimbalYaw) GR: \(lastGimbalRoll)")
    }
}

// MARK: - Remote Controller Delegate

extension PanoramaController: RemoteControllerDelegate {
    func setRemote(remote: DJIRemoteController?) {
        if let remote = remote {
            self.remoteController = RemoteController(remote: remote)
            self.remoteController!.delegate = self
        } else {
            self.remoteController = nil
        }
    }

    func remoteControllerBatteryPercentUpdated(batteryPercent: Int) {
        if (batteryPercent < 10) {
            self.delegate?.postUserWarning("Remote Controller Battery Low: \(batteryPercent)%")
        }
    }
}

// MARK: - Flight Controller Delegate

extension PanoramaController: FlightControllerDelegate {
    func setFC(fc: DJIFlightController?) {
        if let fc = fc {
            self.flightController = FlightController(fc: fc)
            self.flightController!.delegate = self
        } else {
            self.flightController = nil
        }
    }

    func flightControllerUpdateHeading(compassHeading: Double) {
        self.currentHeading = compassHeading
        
        self.lastACYaw = Float(compassHeading)
        self.delegate?.aircraftYawChanged(lastACYaw)
        self.gimbalController?.setACYaw(self.lastACYaw)
    }

    func flightControllerUpdateAltitude(altitude: Float) {
        self.delegate?.aircraftAltitudeChanged(altitude)
    }

    func flightControllerUpdateSatelliteCount(satelliteCount: Int) {
        self.delegate?.aircraftSatellitesChanged(satelliteCount)

    }

    func flightControllerUpdateDistance(distance: CLLocationDistance) {
        self.delegate?.aircraftDistanceChanged(distance)
    }

    func flightControllerUnableToSetControlMode() {
        self.delegate?.postUserMessage("Unable to set virtual stick control mode")

        self.panoRunning = (state: false, ok: false)
    }

    func flightControllerSetControlMode() {
        self.doPanoLoop(false)
    }

    func flightControllerUnableToYaw(reason: String) {
        self.delegate?.postUserMessage(reason)

        self.trackEvent(category: "Panorama", action: "Aircraft", label: "Aborted \(reason)")

        dispatch_async(droneCommandsQueue()) {
            self.panoRunning = (state: false, ok: false)

            self.aircraftDispatchGroup.leave()
        }
    }
    
    func flightControllerDidYaw() {
        dispatch_async(droneCommandsQueue()) {
            self.aircraftDispatchGroup.leave()
        }

    }
}

// MARK: - Gimbal Controller Delegate

extension PanoramaController: GimbalControllerDelegate {
    func setGimbal(gimbal: DJIGimbal?) {
        if let gimbal = gimbal {
            self.gimbalController = GimbalController(gimbal: gimbal, gimbalYawIsRelativeToAircraft: gimbalYawIsRelativeToAircraft(self.model))
            self.gimbalController!.delegate = self
            
            if let model = self.model, maxPitch = self.gimbalController?.getMaxPitch() {
                updateSettings(model, settings: [.MaxPitch: maxPitch])
            }
        } else {
            self.gimbalController = nil
        }
    }

    func gimbalControllerCompleted() {
        DDLogDebug("Gimbal signalled complete")

        dispatch_async(droneCommandsQueue()) {
            self.gimbalDispatchGroup.leave()
        }
    }

    func gimbalControllerAborted(reason: String) {
        DDLogWarn("Gimbal signalled abort \(reason)")

        self.trackEvent(category: "Panorama", action: "Gimbal", label: "Aborted \(reason)")

        self.delegate?.postUserMessage(reason)

        dispatch_async(droneCommandsQueue()) {
            self.panoRunning = (state: false, ok: false)

            self.gimbalDispatchGroup.leave()
        }
    }

    func gimbalMoveOutOfRange(reason: String) {
        DDLogDebug("Gimbal signalled out of range \(reason)")

        self.trackEvent(category: "Panorama", action: "Gimbal", label: "Out of range \(reason)")

        self.delegate?.postUserMessage(reason)

        dispatch_async(droneCommandsQueue()) {
            self.gimbalDispatchGroup.leave()
        }
    }

    func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float) {
        lastGimbalPitch = pitch
        lastGimbalYaw = yaw
        lastGimbalRoll = roll

        self.delegate?.gimbalAttitudeChanged(pitch: pitch, yaw: yaw, roll: roll)
    }

    func gimbalControllerStopped() {
        dispatch_async(droneCommandsQueue()) {
            self.gimbalDispatchGroup.leaveIfActive()
        }
    }
}