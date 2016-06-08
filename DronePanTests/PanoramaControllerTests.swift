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

import XCTest
import DJISDK

@testable import DronePan

class PanoramaControllerDelegateAdapter : PanoramaControllerDelegate {
    var asyncExpectation: XCTestExpectation?

    func panoStarting() {
    }
    
    func panoStopping() {
    }
    
    func panoCountChanged(count: Int, total: Int) {
    }
    
    func panoAvailable(available: Bool) {
    }
    
    func postUserMessage(message: String) {
    }
    
    func postUserWarning(warning: String) {
    }

    func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float) {
    }
    
    func aircraftYawChanged(yaw: Float) {
    }
    
    func aircraftSatellitesChanged(count: Int) {
    }
    
    func aircraftDistanceChanged(distance: CLLocationDistance) {
    }
    
    func aircraftAltitudeChanged(altitude: Float) {
    }
    
    func panoProgress(progress: Float) {
    }
}

class PanoramaControllerDelegateTest : PanoramaControllerDelegateAdapter {
    var message : String = ""
    var callCount : Int = 0
    
    var panoStarted : Bool = false
    
    override func postUserMessage(message: String) {
        callCount += 1
        self.message = message
    }
    
    override func panoStarting() {
        panoStarted = true
    }
    
    override func panoStopping() {
        panoStarted = false
    }
}

class CameraControllerTest : CameraController {
    var callCount : Int = 0
    var shotCount : Int = 0
    
    var hasSpace : Bool = true
    
    
    override func hasSpaceForPano(shotCount: Int) -> Bool {
        callCount += 1
        self.shotCount = shotCount
        return hasSpace
    }
}

class PanoramaControllerTest : PanoramaController {
    override func doPanoLoop(gimbalYaw: Bool) {
    }
}

class PanoramaControllerTests: XCTestCase, ModelSettings {
    let panoramaController = PanoramaController()

    func testPitchesForAircraftMaxPitch0False() {
        let value = panoramaController.pitchesForLoop(maxPitch: 0, maxPitchEnabled: false, type: .Aircraft, rowCount: 3)

        XCTAssertEqual([0, -30, -60], value, "Incorrect pitches for max pitch 0 ac false \(value)")
    }

    func testPitchesForAircraftMaxPitch0True() {
        let value = panoramaController.pitchesForLoop(maxPitch: 0, maxPitchEnabled: true, type: .Aircraft, rowCount: 3)
        
        XCTAssertEqual([0, -30, -60], value, "Incorrect pitches for max pitch 0 ac true \(value)")
    }

    func testPitchesForAircraftMaxPitch30False() {
        let value = panoramaController.pitchesForLoop(maxPitch: 30, maxPitchEnabled: false, type: .Aircraft, rowCount: 3)
        
        XCTAssertEqual([0, -30, -60], value, "Incorrect pitches for max pitch 30 ac false \(value)")
    }

    func testPitchesForAircraftMaxPitch30True() {
        let value = panoramaController.pitchesForLoop(maxPitch: 30, maxPitchEnabled: true, type: .Aircraft, rowCount: 3)
        
        XCTAssertEqual([30, -10, -50], value, "Incorrect pitches for max pitch 30 ac true \(value)")
    }

    func testPitchesForAircraftMaxPitch305Rows() {
        let value = panoramaController.pitchesForLoop(maxPitch: 30, maxPitchEnabled: true, type: .Aircraft, rowCount: 5)

        XCTAssertEqual([30, 6, -18, -42, -66], value, "Incorrect pitches for max pitch 30 row count 5 ac \(value)")
    }

    func testPitchesForHandheldMaxPitch30() {
        let value = panoramaController.pitchesForLoop(maxPitch: 30, maxPitchEnabled: true, type: .Handheld, rowCount: 4)

        XCTAssertEqual([-60, -30, 0, 30], value, "Incorrect pitches for max pitch 30 handheld \(value)")
    }

    func testYawAnglesForCount10WithHeading0() {
        let value = panoramaController.yawAngles(count: 10, heading: 0)

        XCTAssertEqual([36, 72, 108, 144, 180, 216, 252, 288, 324, 360], value, "Incorrect angles for count 10 heading 0 \(value)")
    }

    func testYawAnglesForCount6WithHeading0() {
        let value = panoramaController.yawAngles(count: 6, heading: 0)

        XCTAssertEqual([60, 120, 180, 240, 300, 360], value, "Incorrect angles for count 6 heading 0 \(value)")
    }

    func testYawAnglesForCount10WithHeading84() {
        let value = panoramaController.yawAngles(count: 10, heading: 84)

        XCTAssertEqual([120, 156, 192, 228, 264, 300, 336, 12, 48, 84], value, "Incorrect angles for count 10 heading 84 \(value)")
    }

    func testYawAnglesForCount6WithHeadingNeg84() {
        let value = panoramaController.yawAngles(count: 6, heading: -84)

        XCTAssertEqual([-24, 36, 96, 156, 216, 276], value, "Incorrect angles for count 6 heading -84 \(value)")
    }

    func testHeadingTo360() {
        let value = panoramaController.headingTo360(0)

        XCTAssertEqual(0, value, "Incorrect heading for 0 \(value)")
    }

    func testHeadingTo360Negative() {
        let value = panoramaController.headingTo360(-117)

        XCTAssertEqual(243, value, "Incorrect heading for -117 \(value)")
    }

    func testHeadingTo360Positive() {
        let value = panoramaController.headingTo360(117)

        XCTAssertEqual(117, value, "Incorrect heading for 117 \(value)")
    }
    
    func testGimbalYawHandheld() {
        let value = panoramaController.gimbalYawSelected(DJIHandheldModelNameOsmo, type: .Handheld)
        
        XCTAssertTrue(value, "Handheld got ac yaw")
    }

    func testGimbalYawHandheldWrongModel() {
        let value = panoramaController.gimbalYawSelected(DJIAircraftModelNameInspire1, type: .Handheld)
        
        XCTAssertTrue(value, "Handheld got ac yaw")
    }
    
    func testGimbalYawPhantom() {
        let value = panoramaController.gimbalYawSelected(DJIAircraftModelNamePhantom4, type: .Aircraft)
        
        XCTAssertFalse(value, "Phantom got gimbal yaw")
    }

    func testGimbalYawInspireDefault() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        let value = panoramaController.gimbalYawSelected(DJIAircraftModelNameInspire1, type: .Aircraft)
        
        XCTAssertFalse(value, "Inspire 1 got gimbal yaw by default")
    }

    func testGimbalYawInspireSet() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        updateSettings(DJIAircraftModelNameInspire1, settings: [SettingsKeys.ACGimbalYaw: true])
        
        let value = panoramaController.gimbalYawSelected(DJIAircraftModelNameInspire1, type: .Aircraft)
        
        XCTAssertTrue(value, "Inspire 1 got ac yaw when gimbal yaw was selected")
    }
    
    func testProductRequiredForStart() {
        let delegate = PanoramaControllerDelegateTest()
        
        panoramaController.delegate = delegate
        
        panoramaController.model = DJIAircraftModelNameInspire1
        
        panoramaController.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Unable to find DJI Product", "User not warned of missing product")
    }

    func testCameraRequiredForStart() {
        let delegate = PanoramaControllerDelegateTest()
        
        panoramaController.delegate = delegate
        
        panoramaController.product = DJIBaseProduct()
        
        panoramaController.cameraController = nil
        
        panoramaController.model = DJIAircraftModelNameInspire1
        
        panoramaController.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Unable to find a camera", "User not warned of missing camera")
    }

    func testCardSpaceRequiredForStart() {
        let delegate = PanoramaControllerDelegateTest()
        
        panoramaController.delegate = delegate

        let cameraController = CameraControllerTest(camera: DJICamera())
        cameraController.hasSpace = false
        panoramaController.cameraController = cameraController

        panoramaController.product = DJIBaseProduct()
        
        panoramaController.model = DJIAircraftModelNameInspire1

        panoramaController.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Not enough space on card for \(cameraController.shotCount) images", "User not warned of missing camera")
        
        XCTAssertEqual(cameraController.callCount, 1, "Too many calls to camera controller")
    }

    func testGimbalRequiredForStart() {
        let delegate = PanoramaControllerDelegateTest()
        
        panoramaController.delegate = delegate
        
        let cameraController = CameraControllerTest(camera: DJICamera())
        panoramaController.cameraController = cameraController
        
        panoramaController.product = DJIBaseProduct()
        
        panoramaController.model = DJIAircraftModelNameInspire1
        
        panoramaController.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Unable to find a gimbal", "User not warned of missing gimbal")
    }

    func testFCRequiredForStartAircraft() {
        let delegate = PanoramaControllerDelegateTest()
        
        panoramaController.delegate = delegate
        
        let cameraController = CameraControllerTest(camera: DJICamera())
        panoramaController.cameraController = cameraController
        
        panoramaController.gimbalController = GimbalController(gimbal: DJIGimbal())
        
        panoramaController.product = DJIBaseProduct()
        
        panoramaController.model = DJIAircraftModelNameInspire1
        panoramaController.type = .Aircraft
        
        panoramaController.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Unable to find a flight controller", "User not warned of missing flight controller")
    }

    func testRCRequiredForStartAircraft() {
        let delegate = PanoramaControllerDelegateTest()
        
        panoramaController.delegate = delegate
        
        let cameraController = CameraControllerTest(camera: DJICamera())
        panoramaController.cameraController = cameraController
        
        panoramaController.gimbalController = GimbalController(gimbal: DJIGimbal())
        
        panoramaController.flightController = FlightController(fc: DJIFlightController())
        
        panoramaController.product = DJIBaseProduct()
        
        panoramaController.model = DJIAircraftModelNameInspire1
        panoramaController.type = .Aircraft
        
        panoramaController.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Unable to find a remote control", "User not warned of missing remote controller")
    }

    func testFModeRequiredForStartAircraftNotP4ACYaw() {
        let delegate = PanoramaControllerDelegateTest()
        
        panoramaController.delegate = delegate
        
        let cameraController = CameraControllerTest(camera: DJICamera())
        panoramaController.cameraController = cameraController
        
        panoramaController.gimbalController = GimbalController(gimbal: DJIGimbal())
        
        panoramaController.flightController = FlightController(fc: DJIFlightController())
        
        let remoteController = RemoteController(remote: DJIRemoteController())
        remoteController.mode = .Attitude
        panoramaController.remoteController = remoteController
        
        panoramaController.product = DJIBaseProduct()
        
        panoramaController.model = DJIAircraftModelNameInspire1
        panoramaController.type = .Aircraft
        
        updateSettings(DJIAircraftModelNameInspire1, settings: [.ACGimbalYaw: false])
        
        panoramaController.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Please set RC Flight Mode to F first", "User not warned to set F mode")
    }
    
    func testStartHandheld() {
        let controller = PanoramaControllerTest()
        
        let delegate = PanoramaControllerDelegateTest()
        
        controller.delegate = delegate
        
        let cameraController = CameraControllerTest(camera: DJICamera())
        controller.cameraController = cameraController
        
        controller.gimbalController = GimbalController(gimbal: DJIGimbal())
        
        controller.product = DJIHandheld()
        
        controller.model = DJIHandheldModelNameOsmo
        
        updateSettings(DJIAircraftModelNameInspire1, settings: [.ACGimbalYaw: false, .StartDelay: 0])
        
        controller.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Panorama starting", "User not told pano starting")
        
        XCTAssertTrue(controller.panoRunning.state, "Panorama didn't start")
        XCTAssertTrue(controller.panoRunning.ok, "Panorama didn't start ok")
        XCTAssertTrue(delegate.panoStarted, "Panorama didn't inform start")
    }

    func testStartAircraftGimbalYaw() {
        let controller = PanoramaControllerTest()
        
        let delegate = PanoramaControllerDelegateTest()
        
        controller.delegate = delegate
        
        let cameraController = CameraControllerTest(camera: DJICamera())
        controller.cameraController = cameraController
        
        controller.gimbalController = GimbalController(gimbal: DJIGimbal())
        
        controller.product = DJIAircraft()
        
        let remoteController = RemoteController(remote: DJIRemoteController())
        remoteController.mode = .Attitude
        controller.remoteController = remoteController
        
        let flightController = FlightController(fc: DJIFlightController())
        controller.flightController = flightController
        
        controller.model = DJIAircraftModelNameInspire1
        
        updateSettings(DJIAircraftModelNameInspire1, settings: [.ACGimbalYaw: true])
        
        controller.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Panorama starting", "User not told pano starting")
        
        XCTAssertTrue(controller.panoRunning.state, "Panorama didn't start")
        XCTAssertTrue(controller.panoRunning.ok, "Panorama didn't start ok")
        XCTAssertTrue(delegate.panoStarted, "Panorama didn't inform start")
    }
    
    func testStartAircraftNotGimbalYaw() {
        let controller = PanoramaControllerTest()
        
        let delegate = PanoramaControllerDelegateTest()
        
        controller.delegate = delegate
        
        let cameraController = CameraControllerTest(camera: DJICamera())
        controller.cameraController = cameraController
        
        controller.gimbalController = GimbalController(gimbal: DJIGimbal())
        
        controller.product = DJIAircraft()
        
        let remoteController = RemoteController(remote: DJIRemoteController())
        remoteController.mode = .Function
        controller.remoteController = remoteController
        
        let flightController = FlightController(fc: DJIFlightController())
        controller.flightController = flightController
        
        controller.model = DJIAircraftModelNameInspire1
        
        updateSettings(DJIAircraftModelNameInspire1, settings: [.ACGimbalYaw: false])
        
        controller.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Panorama starting", "User not told pano starting")
        
        XCTAssertTrue(controller.panoRunning.state, "Panorama didn't start")
        XCTAssertTrue(controller.panoRunning.ok, "Panorama didn't start ok")
        XCTAssertTrue(delegate.panoStarted, "Panorama didn't inform start")
    }
    
    func testStartAircraftNotGimbalYawP4() {
        let controller = PanoramaControllerTest()
        
        let delegate = PanoramaControllerDelegateTest()
        
        controller.delegate = delegate
        
        let cameraController = CameraControllerTest(camera: DJICamera())
        controller.cameraController = cameraController
        
        controller.gimbalController = GimbalController(gimbal: DJIGimbal())
        
        controller.product = DJIAircraft()
        
        // P4 should ignore the mode - so set attitude for test
        let remoteController = RemoteController(remote: DJIRemoteController())
        remoteController.mode = .Attitude
        controller.remoteController = remoteController
        
        let flightController = FlightController(fc: DJIFlightController())
        controller.flightController = flightController
        
        controller.model = DJIAircraftModelNamePhantom4
        
        updateSettings(DJIAircraftModelNamePhantom4, settings: [.ACGimbalYaw: false])
        
        controller.start()
        
        XCTAssertEqual(delegate.callCount, 1, "Too many calls to delegate")
        XCTAssertEqual(delegate.message, "Panorama starting", "User not told pano starting")
        
        XCTAssertTrue(controller.panoRunning.state, "Panorama didn't start")
        XCTAssertTrue(controller.panoRunning.ok, "Panorama didn't start ok")
        XCTAssertTrue(delegate.panoStarted, "Panorama didn't inform start")
    }
    
    func testUserStop() {
        let controller = PanoramaControllerTest()
        
        let delegate = PanoramaControllerDelegateTest()
        
        controller.delegate = delegate
        
        let cameraController = CameraControllerTest(camera: DJICamera())
        controller.cameraController = cameraController
        
        controller.gimbalController = GimbalController(gimbal: DJIGimbal())
        
        controller.product = DJIAircraft()
        
        let remoteController = RemoteController(remote: DJIRemoteController())
        remoteController.mode = .Function
        controller.remoteController = remoteController
        
        let flightController = FlightController(fc: DJIFlightController())
        controller.flightController = flightController
        
        controller.model = DJIAircraftModelNameInspire1
        
        updateSettings(DJIAircraftModelNameInspire1, settings: [.ACGimbalYaw: false])
        
        controller.start()

        controller.stop()
        
        XCTAssertEqual(delegate.message, "Panorama stopping. Please wait ...", "User not told pano stopping")
        
        XCTAssertFalse(controller.panoRunning.state, "Panorama didn't stop")
        XCTAssertTrue(controller.panoRunning.ok, "Panorama didn't stop ok")
        XCTAssertFalse(delegate.panoStarted, "Panorama didn't inform stop")
    }
    
    func testNewCamera() {
        let camera = DJICamera()
        
        panoramaController.setCamera(camera)
        
        XCTAssertEqual(panoramaController.cameraController!.camera, camera, "Incorrect camera")
    }

    func testNewCameraWithVideo() {
        let camera = DJICamera()
        
        class VPDelegate : VideoControllerDelegate {
            func cameraReceivedVideo(videoBuffer: UnsafeMutablePointer<UInt8>, size: Int) {
            }
        }
        
        let video = VPDelegate()
        
        panoramaController.setCamera(camera, preview: video)
        
        XCTAssertEqual(panoramaController.cameraController!.camera, camera, "Incorrect camera")
        
        guard let videoDelegate = panoramaController.cameraController!.videoDelegate as? VPDelegate else {
            XCTFail("Didn't find correct video delegate")
            return
        }
        
        XCTAssertTrue(videoDelegate === video, "Incorrect video delegate found")
    }
    
    func testRemoveCamera() {
        panoramaController.setCamera(nil)
        
        XCTAssertNil(panoramaController.cameraController, "Camera found")
    }
    
    func testNewGimbal() {
        let gimbal = DJIGimbal()
        
        panoramaController.setGimbal(gimbal)
        
        XCTAssertEqual(panoramaController.gimbalController!.gimbal, gimbal, "Incorrect gimbal")
    }
    
    func testRemoveGimbal() {
        panoramaController.setGimbal(nil)
        
        XCTAssertNil(panoramaController.gimbalController, "Gimbal found")
    }
    
    func testNewRemote() {
        let remote = DJIRemoteController()
        
        panoramaController.setRemote(remote)
        
        XCTAssertEqual(panoramaController.remoteController!.remote, remote, "Incorrect remote")
    }
    
    func testRemoveRemote() {
        panoramaController.setRemote(nil)
        
        XCTAssertNil(panoramaController.remoteController, "Remote found")
    }
    
    func testNewFC() {
        let fc = DJIFlightController()
        
        panoramaController.setFC(fc)
        
        XCTAssertEqual(panoramaController.flightController!.fc, fc, "Incorrect FC")
    }
    
    func testRemoveFC() {
        panoramaController.setFC(nil)
        
        XCTAssertNil(panoramaController.flightController, "FC found")
    }
    
    func testFCBatteryLow() {
        class PanoramaDelegateMock : PanoramaControllerDelegateAdapter {
            var reason: String? = .None
            
            override func postUserWarning(warning: String) {
                guard let expectation = asyncExpectation else {
                    XCTFail("PanoramaControllerDelegateAdapter was not setup correctly. Missing XCTExpectation reference")
                    return
                }
                
                self.reason = warning
                
                expectation.fulfill()
            }
        }

        let spyDelegate = PanoramaDelegateMock()
        
        let expectation = expectationWithDescription("Low battery should trigger a warning")
        spyDelegate.asyncExpectation = expectation
        
        panoramaController.delegate = spyDelegate
        
        panoramaController.remoteControllerBatteryPercentUpdated(9)
        
        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
            
            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called")
                return
            }
            
            XCTAssertEqual(reason, "Remote Controller Battery Low: 9%", "No warning on low battery")
        }
    }

    func isAircraftYawStep(step: DJIMissionStep?) {
        guard let _ = step as? DJIAircraftYawStep else {
            XCTFail("Incorrect step")
            
            return
        }
    }
    
    func isGimbalAttitudeStep(step: DJIMissionStep?) {
        guard let _ = step as? DJIGimbalAttitudeStep else {
            XCTFail("Incorrect step")
            
            return
        }
    }

    func isShootPhotoStep(step: DJIMissionStep?) {
        guard let _ = step as? DJIShootPhotoStep else {
            XCTFail("Incorrect step")
            
            return
        }
    }
    
    func testAircraftYawMission() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        let controller = PanoramaController()
        
        controller.product = DJIAircraft()
        controller.model = DJIAircraftModelNameInspire1
        
        if let steps = controller.buildMissionSteps(false) {
            XCTAssertEqual(steps.count, 47, "Incorrect number of mission steps")

            isAircraftYawStep(steps[8])
            isGimbalAttitudeStep(steps[13])
            isShootPhotoStep(steps[42])
        } else {
            XCTFail("Failed to build mission")
        }
    }
    
    func testAircraftGimbalYawMission() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        let controller = PanoramaController()
        
        controller.product = DJIAircraft()
        controller.model = DJIAircraftModelNameInspire1
        
        if let steps = controller.buildMissionSteps(true) {
            XCTAssertEqual(steps.count, 40, "Incorrect number of mission steps")
            
            isGimbalAttitudeStep(steps[13])
            isShootPhotoStep(steps[36])
        } else {
            XCTFail("Failed to build mission")
        }
    }
}
