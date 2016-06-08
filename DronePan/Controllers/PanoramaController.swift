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
    
    func panoProgress(progress: Float)
}

class PanoramaController: NSObject, Analytics, SystemUtils, ModelUtils, ModelSettings {
    var delegate: PanoramaControllerDelegate?

    var cameraController: CameraController?
    var remoteController: RemoteController?
    var gimbalController: GimbalController?
    var flightController: FlightController?

    var missionManager : DJIMissionManager? = nil

    var lastGimbalPitch: Float = 0.0
    var lastGimbalYaw: Float = 0.0
    var lastGimbalRoll: Float = 0.0
    var lastACYaw: Float = 0.0

    var panoRunning: (state:Bool, ok:Bool) = (state: false, ok: true) {
        didSet {
            if panoRunning.state {
                self.delegate?.panoStarting()
            } else {
                // TODO - check if mission is actually running?
                if let missionManager = DJIMissionManager.sharedInstance() {
                    missionManager.stopMissionExecutionWithCompletion({ (error) in
                        if let error = error {
                            self.delegate?.postUserMessage("Unable to stop mission \(error)")
                        }
                    })
                }
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
            
            if (type == .Aircraft) {
                self.doPanoLoop(gimbalYaw)
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

    func buildAttitudeStep(pitch: Double, yaw: Double = 0.0) -> DJIMissionStep {
        var attitude = DJIGimbalAttitude()
        attitude.pitch = Float(pitch)
        attitude.roll = 0
        attitude.yaw = Float(yaw)
        
        // TODO - if this fails to create (returns optional nil) then the ! will cause an app crash - needs handling
        return DJIGimbalAttitudeStep(attitude: attitude)!
    }
    
    func buildColumn(shoot: DJIMissionStep, pitches: [Double], yaw: Double = 0.0) -> [DJIMissionStep] {
        return pitches.map {
            (pitch) in
            
            [
                buildAttitudeStep(pitch, yaw: yaw),
                shoot
            ]
        }.flatMap{$0}
    }
    
    func buildMissionSteps(gimbalYaw: Bool) -> [DJIMissionStep]? {
        if let model = self.model, type = self.type {
            let cols = photosPerRow(model)
            let nadirs = nadirCount(model)
            
            let yaw_angle = 360.0 / Double(cols)
            let yaw_angles = yawAngles(count: cols, heading: 0.0)
            
            let nadir_yaw_angle = 360.0 / Double(nadirs)
            let nadir_yaw_angles = yawAngles(count: nadirs, heading: 0.0)
            
            guard let shoot = DJIShootPhotoStep(singleShootPhoto:()) else {
                self.delegate?.postUserMessage("Couldn't create shoot photo mission step")
                
                return nil
            }
            
            let pitches : [Double] = self.pitchesForLoop(maxPitch: Double(maxPitch(model)),
                                                         maxPitchEnabled: maxPitchEnabled(model),
                                                         type: type, rowCount: numberOfRows(model))
            
            if (gimbalYaw) {
                let mainMissionSteps = yaw_angles.map {
                    (yaw) in
                    buildColumn(shoot, pitches: pitches, yaw: yaw)
                }.flatMap{$0}
                
                let nadirMissionSteps = nadir_yaw_angles.map {
                    (yaw) in
                    buildColumn(shoot, pitches: [-90.0], yaw: yaw)
                }.flatMap{$0}
                
                let missionSteps = [
                    [buildAttitudeStep(0)], // Reset gimbal
                    mainMissionSteps,
                    nadirMissionSteps,
                    [buildAttitudeStep(0)] // Reset gimbal
                ].flatMap{$0}
                
                return missionSteps
            } else {
                guard let yaw = DJIAircraftYawStep(relativeAngle: yaw_angle, andAngularVelocity: 50) else {
                    self.delegate?.postUserMessage("Couldn't create aircraft yaw mission step")
                    
                    return nil
                }
                
                guard let nadirYaw = DJIAircraftYawStep(relativeAngle: nadir_yaw_angle, andAngularVelocity: 50) else {
                    self.delegate?.postUserMessage("Couldn't create aircraft yaw mission step for nadir")
                    
                    return nil
                }
                
                let mainMissionSteps = yaw_angles.map {
                    (_) in
                    
                    [
                        [yaw],
                        buildColumn(shoot, pitches: pitches)
                    ].flatMap{$0}
                }.flatMap{$0}
                
                let nadirMissionSteps = nadir_yaw_angles.map {
                    (_) in
                    
                    [
                        [nadirYaw],
                        buildColumn(shoot, pitches: [-90.0])
                    ].flatMap{$0}
                }.flatMap{$0}
                
                let missionSteps = [
                    [buildAttitudeStep(0)], // Reset gimbal
                    mainMissionSteps,
                    nadirMissionSteps,
                    [buildAttitudeStep(0)] // Reset gimbal
                ].flatMap{ $0 }
                
                return missionSteps
            }
        }
        
        return nil
    }
    
    func buildMission(gimbalYaw: Bool) -> DJIMission? {
        if let steps = buildMissionSteps(gimbalYaw) {
            return DJICustomMission(steps: steps)
        }
        
        return nil
    }
    
    // Marked objc to allow override from test - can only override methods that are in extensions when they are marked objc in swift for now
    @objc func doPanoLoop(gimbalYaw: Bool) {
        if let model = self.model, type = self.type {
            if type == .Unknown {
                DDLogError("Panorama started with unknown type")

                return
            }

            if type == .Handheld {
                // TODO: should also be done for gimbal yaw of AC when that is in place
                self.currentHeading = 0
            }

            self.totalCount = numberOfImagesForCurrentSettings(model)
            self.currentCount = 0

            guard let missionManager = DJIMissionManager.sharedInstance() else {
                self.delegate?.postUserWarning("Unable to get mission manager")
                
                return
            }
            
            missionManager.delegate = self
            
            guard let mission = buildMission(gimbalYaw) else {
                self.delegate?.postUserWarning("Unable to build mission")
                
                return
            }
            
            missionManager.prepareMission(mission, withProgress: { (progress) in
                self.delegate?.panoProgress(progress)
            }, withCompletion: { (error) in
                if let error = error {
                    DDLogDebug("Error preparing mission: \(error)")
                    
                    self.delegate?.postUserWarning("Could not prepare mission: \(error)")
                    
                    return
                }
            })

            missionManager.startMissionExecutionWithCompletion({ (error) in
                if let error = error {
                    DDLogDebug("Error starting mission: \(error)")
                    
                    self.delegate?.postUserWarning("Could not start mission: \(error)")
                    
                    return
                }
            })
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

    func cameraControllerInError(reason: String) {
        DDLogWarn("Camera signalled error \(reason)")

        self.trackEvent(category: "Panorama", action: "Camera", label: "Error \(reason)")

        self.delegate?.postUserMessage(reason)

        if panoRunning.state {
            self.panoRunning = (state: false, ok: false)
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

    func cameraControllerNewMedia(filename: String) {
        DDLogInfo("Shot taken: \(filename) ACY: \(lastACYaw) GP: \(lastGimbalPitch) GY: \(lastGimbalYaw) GR: \(lastGimbalRoll)")
        
        self.currentCount += 1
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

    func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float) {
        lastGimbalPitch = pitch
        lastGimbalYaw = yaw
        lastGimbalRoll = roll

        self.delegate?.gimbalAttitudeChanged(pitch: pitch, yaw: yaw, roll: roll)
    }
}

// MARK: - DJI Mission Delegate

extension PanoramaController : DJIMissionManagerDelegate {
    func missionManager(manager: DJIMissionManager, didFinishMissionExecution error: NSError?) {
        if let error = error {
            self.panoRunning = (state: false, ok: false)
            
            DDLogError("Panorama mission aborted \(error)")
            
            self.delegate?.postUserMessage("Panorama mission aborted")
        } else {
            self.panoRunning = (state: false, ok: true)
            
            self.delegate?.postUserMessage("Panorama mission completed")
        }
    }
    
    func missionManager(manager: DJIMissionManager, missionProgressStatus missionProgress: DJIMissionProgressStatus) {
        // TODO
    }
}