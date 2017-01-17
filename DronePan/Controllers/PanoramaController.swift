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

    func panoCompleted(panorama: Panorama)
    
    func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float)

    func aircraftYawChanged(yaw: Float)

    func aircraftSatellitesChanged(count: Int)

    func aircraftDistanceChanged(distance: CLLocationDistance)

    func aircraftAltitudeChanged(altitude: Float)

    func panoCountChanged(count: Int, total: Int)

    func panoAvailable(available: Bool)
}

protocol PanoramaCameraControlsDelegate {
    func cameraExposureModeUpdated(mode: DJICameraExposureMode)
    
    func cameraISOUpdated(ISO: UInt)
    
    func cameraApertureUpdated(aperture: DJICameraAperture)
    
    func cameraShutterSpeedUpdated(shutterSpeed: DJICameraShutterSpeed)
    
    func cameraExposureCompensationUpdated(comp: DJICameraExposureCompensation)
}

class PanoramaController: Analytics {
    var delegate: PanoramaControllerDelegate?
    var cameraControlsDelegate: PanoramaCameraControlsDelegate?

    var cameraController: CameraController?
    var remoteController: RemoteController?
    var gimbalController: GimbalController?
    var flightController: FlightController?

    var lastGimbalPitch: Float = 0.0
    var lastGimbalYaw: Float = 0.0
    var lastGimbalRoll: Float = 0.0
    var lastACYaw: Float = 0.0
    
    var currentPanorama : Panorama?

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

    let droneCommandsQueue = dispatch_queue_create("com.dronepan.queue", DISPATCH_QUEUE_SERIAL)

    let gimbalDispatchGroup = ActiveAwareDispatchGroup(name: "gimbal")
    let cameraDispatchGroup = ActiveAwareDispatchGroup(name: "camera")

    var totalCount = 0

    var currentCount = 0 {
        didSet {
            self.delegate?.panoCountChanged(currentCount, total: totalCount)
        }
    }

    var currentHeading = 0.0
    var yawDestination = 0.0
    var yawSpeed = 0.0

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

    func yawAnglesForNadir(count count: Int, heading: Double) {
        
    }

    func headingTo360(heading: Double) -> Double {
        return heading >= 0 ? heading : heading + 360.0
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
            let panoCount = ModelSettings.numberOfImagesForCurrentSettings(model)

            if (!cameraController.hasSpaceForPano(panoCount)) {
                DDLogDebug("Not enough space for \(panoCount) images")

                self.delegate?.postUserMessage("Not enough space on card for \(panoCount) images")

                return false
            }

            return true
        }

        return false
    }

    // TODO: Refactor all of this since SDK 3.5 changes switch modes from F-A-P to 1-2-3
    private func checkRCMode() -> Bool {
        if let type = self.type, model = self.model, remoteController = self.remoteController {
            if (type == .Aircraft) {
                let (correctMode, userMessage) = ModelConfig.correctMode(model, position: remoteController.mode)
                
                if (!correctMode) {
                    DDLogDebug("Not in correct mode - saw \(remoteController.mode) for model \(model)")
                    
                    self.delegate?.postUserMessage(userMessage!)

                    return false
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

    func start() {
        if (!checkProduct()) {
            return
        }

        if (!checkSpace()) {
            return
        }

        if (!checkCamera()) {
            return
        }

        if (!checkGimbal()) {
            return
        }

        if (!checkFC()) {
            return
        }

        if (!checkRCMode()) {
            return
        }

        trackEvent(category: "Panorama", action: "Range Extension", label: "Starting panoarama with model \(self.model), camera \(self.cameraController?.camera.displayName) range extension \(self.gimbalController?.supportsRangeExtension) and max pitch \(self.gimbalController?.getMaxPitch())")
        
        self.panoRunning = (state: true, ok: true)

        self.delegate?.postUserMessage("Panorama starting")
        
        self.currentPanorama = Panorama()

        if (self.type! == .Aircraft) {
            self.flightController?.setControlModes()
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(ModelSettings.startDelay(self.model!)) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                self.doPanoLoop()
            }
        }
    }

    func stop() {
        self.delegate?.postUserMessage("Panorama stopping. Please wait ...")
        
        self.panoRunning = (state: false, ok: true)
    }

    func doPanoLoop() {
        if let model = self.model, type = self.type {
            if type == .Unknown {
                DDLogError("Panorama started with unknown type")

                return
            }

            let pitches = self.pitchesForLoop(maxPitch: Double(ModelSettings.maxPitch(model)),
                                              maxPitchEnabled: ModelSettings.maxPitchEnabled(model),
                                              type: type, rowCount: ModelSettings.numberOfRows(model))

            // TODO: needs fixing when we enable AC to have gimbal yaw
            let aircraftYaw = type == .Aircraft

            if type == .Handheld {
                // TODO: should also be done for gimbal yaw of AC when that is in place
                self.currentHeading = 0
            }

            let yaws = self.yawAngles(count: ModelSettings.photosPerRow(model), heading: self.headingTo360(self.currentHeading))
            let nadirYaws = self.yawAngles(count: ModelSettings.nadirCount(model), heading:  self.headingTo360(self.currentHeading))
            let photoDelayTime: Double = Double(ModelSettings.photoDelay(model)) / 10
            
            self.totalCount = ModelSettings.numberOfImagesForCurrentSettings(model)
            self.currentCount = 0

            DDLogDebug("PanoLoop: starting")

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                // Set camera mode
                DDLogDebug("PanoLoop: setPhotoMode")
                self.setPhotoMode()

                // Reset gimbal - this will reset the gimbal yaw in case the user has changed it outside of DronePan
                DDLogDebug("PanoLoop: resetGimbal")
                self.resetGimbal()

                // Loop through the yaws
                for yaw in yaws {
                    DDLogDebug("PanoLoop: YawLoop: \(yaw)")

                    // If the user has stopped the pano we'll break
                    if !self.panoRunning.state {
                        DDLogDebug("PanoLoop: YawLoop: \(yaw) -  pano not in progress")

                        break
                    }

                    // Loop through the gimbal pitches
                    for pitch in pitches {
                        DDLogDebug("PanoLoop: YawLoop: \(yaw), PitchLoop: \(pitch)")

                        // If the user has stopped the pano we'll break
                        if !self.panoRunning.state {
                            DDLogDebug("PanoLoop: YawLoop: \(yaw), PitchLoop: \(pitch) - pano not in progress")

                            break
                        }

                        DDLogDebug("PanoLoop: YawLoop: \(yaw), PitchLoop: \(pitch)- set pitch")
                        self.setPitch(pitch)

                        DDLogDebug("PanoLoop: YawLoop: \(yaw), PitchLoop: \(pitch)- take photo")
                        self.takeASnap(photoDelayTime)

                    }
                    // End the gimbal pitch loop

                    // Now we yaw after a column of photos has been taken
                    if (aircraftYaw) {
                        DDLogDebug("PanoLoop: YawLoop: \(yaw) - AC yaw")

                        self.yawSpeed = 30 // This represents 30m/sec
                        self.yawDestination = yaw

                        // Calling this on a timer as it improves the accuracy of aircraft yaw
                        dispatch_sync(self.droneCommandsQueue, {
                            let timer = NSTimer.scheduledTimerWithTimeInterval(0.1,
                                    target: self,
                                    selector: #selector(PanoramaController.yawAircraftUsingVelocity(_:)),
                            userInfo: nil,
                            repeats: true)

                            NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
                            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 5))

                            timer.invalidate()
                        })
                    } else {
                        DDLogDebug("PanoLoop: YawLoop: \(yaw) - gimbal yaw")
                        self.setYaw(yaw)
                    }
                } // End yaw loop

                // Take the final zenith/nadir shots and then reset the gimbal back
                // or we cancel the pano and still reset the gimbal
                if (self.panoRunning.state) {
                    DDLogDebug("PanoLoop: Zenith/Nadir - set pitch")
                    self.setPitch(-90.0)

                    for yaw in nadirYaws {
                        // Now we yaw after a column of photos has been taken
                        if (aircraftYaw) {
                            DDLogDebug("PanoLoop: NadirYawLoop: \(yaw) - AC yaw")
                            
                            self.yawSpeed = 30 // This represents 30m/sec
                            self.yawDestination = yaw
                            
                            // Calling this on a timer as it improves the accuracy of aircraft yaw
                            dispatch_sync(self.droneCommandsQueue, {
                                let timer = NSTimer.scheduledTimerWithTimeInterval(0.1,
                                    target: self,
                                    selector: #selector(PanoramaController.yawAircraftUsingVelocity(_:)),
                                    userInfo: nil,
                                    repeats: true)
                                
                                NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
                                NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 5))
                                
                                timer.invalidate()
                            })
                        } else {
                            DDLogDebug("PanoLoop: NadirYawLoop: \(yaw) - gimbal yaw")
                            self.setYaw(yaw)
                        }

                        DDLogDebug("PanoLoop: NadirYawLoop: \(yaw) - take photo")
                        self.takeASnap(photoDelayTime)
                    }

                    self.currentPanorama?.finish()
                    
                    // Add this back in when we have the pano overview ready when pano is completed
                    /*if let panorama = self.currentPanorama {
                     self.delegate?.panoCompleted(panorama)
                     } else {
                     self.delegate?.postUserMessage("Completed pano")
                     }*/
                    
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

                DDLogDebug("PanoLoop: reset gimbal")
                self.resetGimbal()

                DDLogDebug("PanoLoop: END")
                
                self.currentPanorama = nil
            })
        }
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

    @objc func yawAircraftUsingVelocity(timer: NSTimer) {
        if let c = self.flightController {
            c.yaw(self.yawSpeed)
        }
    }

    func takeASnap(photoDelayTime: Double) {
        DDLogDebug("Take a snap");

        if let c = self.cameraController {
            self.cameraDispatchGroup.enter()
            DDLogDebug("Take a snap - send")
            c.takeASnap(photoDelayTime)
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
            self.cameraController!.model = self.model!
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

        dispatch_async(droneCommandsQueue) {
            self.cameraDispatchGroup.leave()
        }
    }

    func cameraControllerAborted(reason: String) {
        DDLogWarn("Camera signalled abort \(reason)")

        self.delegate?.postUserMessage(reason)

        dispatch_async(droneCommandsQueue) {
            self.trackEvent(category: "Panorama", action: "Camera", label: "Aborted \(reason)")

            self.panoRunning = (state: false, ok: false)

            self.cameraDispatchGroup.leave()
        }
    }

    func cameraControllerStopped() {
        dispatch_async(droneCommandsQueue) {
            self.cameraDispatchGroup.leaveIfActive()
        }
    }

    func cameraControllerInError(reason: String) {
        DDLogWarn("Camera signalled error \(reason)")

        self.trackEvent(category: "Panorama", action: "Camera", label: "Error \(reason)")

        self.delegate?.postUserMessage(reason)

        if panoRunning.state {
            dispatch_async(self.droneCommandsQueue, {
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

        dispatch_async(droneCommandsQueue) {
            self.cameraDispatchGroup.leave()
        }
    }

    func cameraControllerNewMedia(filename: String) {
        DDLogInfo("Shot taken: \(filename) ACY: \(lastACYaw) GP: \(lastGimbalPitch) GY: \(lastGimbalYaw) GR: \(lastGimbalRoll)")
        
        self.currentPanorama?.addFilename(filename)
    }
    
    func cameraExposureModeUpdated(mode: DJICameraExposureMode) {
        self.cameraControlsDelegate?.cameraExposureModeUpdated(mode)
    }
    
    func cameraExposureValuesUpdated(iso iso: UInt, aperture: DJICameraAperture, shutter: DJICameraShutterSpeed, compensation: DJICameraExposureCompensation) {
        self.cameraControlsDelegate?.cameraISOUpdated(iso)
        self.cameraControlsDelegate?.cameraApertureUpdated(aperture)
        self.cameraControlsDelegate?.cameraShutterSpeedUpdated(shutter)
        self.cameraControlsDelegate?.cameraExposureCompensationUpdated(compensation)
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
        self.currentHeading = self.headingTo360(compassHeading)

        var diff = 0.0

        if (self.yawDestination > self.currentHeading) {
            diff = fabs(self.yawDestination) - fabs(self.currentHeading)
            self.yawSpeed = diff * 0.5
        } else {
            // This happens when the current heading is 340 and destination is 40, for example
            diff = fabs(self.currentHeading) - fabs(self.yawDestination)
            self.yawSpeed = fmod(360.0, diff) * 0.5
        }

        self.lastACYaw = Float(self.currentHeading)
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
        self.doPanoLoop()
    }

    func flightControllerUnableToYaw(reason: String) {
        self.delegate?.postUserMessage(reason)
    }
}

// MARK: - Gimbal Controller Delegate

extension PanoramaController: GimbalControllerDelegate {
    func setGimbal(gimbal: DJIGimbal?) {
        if let gimbal = gimbal {
            self.gimbalController = GimbalController(gimbal: gimbal,
                                                     gimbalYawIsRelativeToAircraft: ControllerUtils.gimbalYawIsRelativeToAircraft(self.model),
                                                     allowsAboveHorizon: ModelConfig.allowsAboveHorizon(self.model ?? ""))
            
            self.gimbalController!.delegate = self
            
            if let model = self.model, maxPitch = self.gimbalController?.getMaxPitch() {
                ModelSettings.updateSettings(model, settings: [.MaxPitch: maxPitch])
            }
        } else {
            self.gimbalController = nil
        }
    }

    func gimbalControllerCompleted() {
        DDLogDebug("Gimbal signalled complete")

        dispatch_async(droneCommandsQueue) {
            self.gimbalDispatchGroup.leave()
        }
    }

    func gimbalControllerAborted(reason: String) {
        DDLogWarn("Gimbal signalled abort \(reason)")

        self.trackEvent(category: "Panorama", action: "Gimbal", label: "Aborted \(reason)")

        self.delegate?.postUserMessage(reason)

        dispatch_async(droneCommandsQueue) {
            self.panoRunning = (state: false, ok: false)

            self.gimbalDispatchGroup.leave()
        }
    }

    func gimbalMoveOutOfRange(reason: String) {
        DDLogDebug("Gimbal signalled out of range \(reason)")

        self.trackEvent(category: "Panorama", action: "Gimbal", label: "Out of range \(reason)")

        self.delegate?.postUserMessage(reason)

        dispatch_async(droneCommandsQueue) {
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
        dispatch_async(droneCommandsQueue) {
            self.gimbalDispatchGroup.leaveIfActive()
        }
    }
}
