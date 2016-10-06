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

class CameraControllerVideoSpyDelegate: VideoControllerDelegate {

    var videoReceived: Bool? = .None

    var asyncExpectation: XCTestExpectation?

    func cameraReceivedVideo(videoBuffer: UnsafeMutablePointer<UInt8>, size: Int) {
        guard let expectation = asyncExpectation else {
            XCTFail("CameraControllerVideoSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        videoReceived = true

        expectation.fulfill()
    }
}

class CameraControllerSpyDelegate: CameraControllerDelegate {

    var completed: Bool? = .None
    var shotTaken: Bool? = .None
    var aborted: Bool? = .None
    var abortReason: String? = .None
    var stopped: Bool? = .None
    var errored: Bool? = .None
    var errorReason: String? = .None
    var ok: Bool? = .None
    var okFromError: Bool? = .None

    var asyncExpectation: XCTestExpectation?

    func cameraControllerReset() {
        // NOP
    }

    func cameraControllerOK(fromError: Bool) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        ok = true
        okFromError = fromError

        expectation.fulfill()
    }

    func cameraControllerAborted(reason: String) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        aborted = true
        abortReason = reason

        expectation.fulfill()
    }

    func cameraControllerStopped() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        stopped = true

        expectation.fulfill()
    }

    func cameraControllerInError(reason: String) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        errored = true
        errorReason = reason

        expectation.fulfill()
    }

    func cameraControllerCompleted(shotTaken: Bool) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        completed = true
        self.shotTaken = shotTaken

        expectation.fulfill()
    }

    func cameraControllerNewMedia(filename: String) {
        // NOP
    }
    
    func cameraExposureModeUpdated(mode: DJICameraExposureMode) {
        // NOP
    }
    
    func cameraExposureValuesUpdated(iso iso: UInt, aperture: DJICameraAperture, shutter: DJICameraShutterSpeed, compensation: DJICameraExposureCompensation) {
        // NOP
    }
}

class ModeStateMock: DJICameraSystemState {

    var internalMode: DJICameraMode

    init(mode: DJICameraMode) {
        self.internalMode = mode
    }

    override var mode: DJICameraMode {
        get {
            return internalMode
        }
    }
}

class StoringStateMock: DJICameraSystemState {
    var internalStoring: Bool

    init(storing: Bool) {
        self.internalStoring = storing
    }

    override var isStoringPhoto: Bool {
        get {
            return internalStoring
        }
    }
}

class CameraErrorStateMock: DJICameraSystemState {

    var internalError: Bool
    var internalOverheated: Bool

    init(error: Bool, overheated: Bool) {
        self.internalError = error
        self.internalOverheated = overheated
    }

    override var isCameraError: Bool {
        get {
            return internalError
        }
    }

    override var isCameraOverHeated: Bool {
        get {
            return internalOverheated
        }
    }
}

class FileNameMediaMock: DJIMedia {
    var internalFileName: String

    init(filename: String) {
        self.internalFileName = filename
    }

    override var fileName: String {
        get {
            return internalFileName
        }
    }
}

class CameraControllerTests: XCTestCase {
    func testSpaceForShotOK() {
        let controller = CameraController(camera: DJICamera())

        controller.availableCaptureCount = 20

        let value = controller.hasSpaceForPano(15)

        XCTAssertTrue(value, "No space for shot when space available")
    }

    func testSpaceForShotNotOK() {
        let controller = CameraController(camera: DJICamera())

        controller.availableCaptureCount = 20

        let value = controller.hasSpaceForPano(25)

        XCTAssertFalse(value, "Space for shot when no space available")
    }

    func testSpaceForShotEqual() {
        let controller = CameraController(camera: DJICamera())

        controller.availableCaptureCount = 20

        let value = controller.hasSpaceForPano(20)

        XCTAssertTrue(value, "No space for shot when equal space available")
    }

    func testSpaceForShot0() {
        let controller = CameraController(camera: DJICamera())

        let value = controller.hasSpaceForPano(20)

        XCTAssertTrue(value, "No space for shot when available count unknown")
    }

    func testSetPhotoMode() {

        class CameraMock: DJICamera {
            override func setCameraMode(mode: DJICameraMode, withCompletion block: DJICompletionBlock?) {
                let state = ModeStateMock(mode: mode)

                self.delegate?.camera?(self, didUpdateSystemState: state)
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Setting mode should complete in normal situation")
        spyDelegate.asyncExpectation = expectation

        controller.setPhotoMode()

        waitForExpectationsWithTimeout(3) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Mode not set")

            guard let shotTaken = spyDelegate.shotTaken else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertFalse(shotTaken, "Mode setting should not take photo")

        }
    }

    func testSetPhotoModeSlow() {

        class CameraMock: DJICamera {
            override func setCameraMode(mode: DJICameraMode, withCompletion block: DJICompletionBlock?) {
                let state = ModeStateMock(mode: mode)

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.delegate?.camera?(self, didUpdateSystemState: state)
                }
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Setting mode should complete even if slow")
        spyDelegate.asyncExpectation = expectation

        controller.setPhotoMode()

        waitForExpectationsWithTimeout(5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Mode not set")
        }
    }

    func testSetPhotoModeTooSlow() {

        class CameraMock: DJICamera {
            override func setCameraMode(mode: DJICameraMode, withCompletion block: DJICompletionBlock?) {
                let state = ModeStateMock(mode: mode)

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(13 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.delegate?.camera?(self, didUpdateSystemState: state)
                }
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Setting mode should not complete if too slow")
        spyDelegate.asyncExpectation = expectation

        controller.setPhotoMode()

        waitForExpectationsWithTimeout(15) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Mode set did not timeout")
        }
    }

    func testSetPhotoModeStopping() {

        class CameraMock: DJICamera {
            override func setCameraMode(mode: DJICameraMode, withCompletion block: DJICompletionBlock?) {
                let state = ModeStateMock(mode: mode)

                self.delegate?.camera?(self, didUpdateSystemState: state)
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Setting mode should not complete if stopping")
        spyDelegate.asyncExpectation = expectation

        controller.setPhotoMode()
        controller.status = .Stopping

        waitForExpectationsWithTimeout(3) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let stopped = spyDelegate.stopped else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(stopped, "Mode set completed when stopping")
        }
    }

    func testSetPhotoModeError() {

        class CameraMock: DJICamera {
            override func setCameraMode(mode: DJICameraMode, withCompletion block: DJICompletionBlock?) {
                let error = NSError(domain: "Test", code: 1001, userInfo: nil)
                block?(error)
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Setting mode should not complete if error setting mode")
        spyDelegate.asyncExpectation = expectation

        controller.setPhotoMode()

        waitForExpectationsWithTimeout(13) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Mode set with error")
        }
    }

    func testSetPhotoModeCameraError() {

        class CameraMock: DJICamera {
            override func setCameraMode(mode: DJICameraMode, withCompletion block: DJICompletionBlock?) {
                let state = CameraErrorStateMock(error: true, overheated: false)

                self.delegate?.camera?(self, didUpdateSystemState: state)
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Setting mode should not complete if camera goes into error state")
        spyDelegate.asyncExpectation = expectation

        controller.setPhotoMode()

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Mode set did not error when camera was in error mode")
        }
    }

    func testTakeASnap() {

        class CameraMock: DJICamera {
            override func startShootPhoto(shootMode: DJICameraShootPhotoMode, withCompletion block: DJICompletionBlock?) {
                let media = FileNameMediaMock(filename: "TestFile")

                self.delegate?.camera?(self, didGenerateNewMediaFile: media)
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Taking a photo should complete in normal situation")
        spyDelegate.asyncExpectation = expectation

        controller.takeASnap()

        waitForExpectationsWithTimeout(3) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Photo not taken")

            guard let shotTaken = spyDelegate.shotTaken else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(shotTaken, "Photo taking should take photo")

        }
    }

    func testTakeASnapSlow() {

        class CameraMock: DJICamera {
            override func startShootPhoto(shootMode: DJICameraShootPhotoMode, withCompletion block: DJICompletionBlock?) {
                let media = FileNameMediaMock(filename: "TestFile")

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.delegate?.camera?(self, didGenerateNewMediaFile: media)
                }
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Taking a photo should complete in normal situation")
        spyDelegate.asyncExpectation = expectation

        controller.takeASnap()

        waitForExpectationsWithTimeout(5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Photo not taken")

            guard let shotTaken = spyDelegate.shotTaken else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(shotTaken, "Photo taking should take photo")

        }
    }

    func testTakeASnapTooSlow() {

        class CameraMock: DJICamera {
            override func startShootPhoto(shootMode: DJICameraShootPhotoMode, withCompletion block: DJICompletionBlock?) {
                let media = FileNameMediaMock(filename: "TestFile")

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(13 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.delegate?.camera?(self, didGenerateNewMediaFile: media)
                }
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Taking a photo should complete in normal situation")
        spyDelegate.asyncExpectation = expectation

        controller.takeASnap()

        waitForExpectationsWithTimeout(13) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Photo taken")
        }
    }

    func testTakeASnapSlowSDCard() {

        class CameraMock: DJICamera {
            override func startShootPhoto(shootMode: DJICameraShootPhotoMode, withCompletion block: DJICompletionBlock?) {
                let state = StoringStateMock(storing: true)

                self.delegate?.camera?(self, didUpdateSystemState: state)
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Taking a photo should not complete if SD card takes too long")
        spyDelegate.asyncExpectation = expectation

        controller.takeASnap()

        waitForExpectationsWithTimeout(15) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Photo taken when SD card taking too long")
        }
    }


    func testTakeASnapStopping() {

        class CameraMock: DJICamera {
            override func startShootPhoto(shootMode: DJICameraShootPhotoMode, withCompletion block: DJICompletionBlock?) {
                let media = FileNameMediaMock(filename: "TestFile")

                self.delegate?.camera?(self, didGenerateNewMediaFile: media)
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Taking photo should not complete if stopping")
        spyDelegate.asyncExpectation = expectation

        controller.takeASnap()
        controller.status = .Stopping

        waitForExpectationsWithTimeout(3) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let stopped = spyDelegate.stopped else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(stopped, "Photo taken when stopping")
        }
    }

    func testTakeASnapError() {

        class CameraMock: DJICamera {
            override func startShootPhoto(shootMode: DJICameraShootPhotoMode, withCompletion block: DJICompletionBlock?) {
                let error = NSError(domain: "Test", code: 1001, userInfo: nil)
                block?(error)
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Taking a photo should not complete if error setting mode")
        spyDelegate.asyncExpectation = expectation

        controller.takeASnap()

        waitForExpectationsWithTimeout(13) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Photo taken with error")
        }
    }

    func testTaleASnapCameraError() {

        class CameraMock: DJICamera {
            override func startShootPhoto(shootMode: DJICameraShootPhotoMode, withCompletion block: DJICompletionBlock?) {
                let state = CameraErrorStateMock(error: false, overheated: true)

                self.delegate?.camera?(self, didUpdateSystemState: state)
            }
        }

        let controller = CameraController(camera: CameraMock())

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Take a photo should not complete if camera goes into error state")
        spyDelegate.asyncExpectation = expectation

        controller.takeASnap()

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Photo taken when camera was in error mode")
        }
    }

    func testVideo() {
        let camera = DJICamera()
        let controller = CameraController(camera: camera)

        let spyDelegate = CameraControllerVideoSpyDelegate()
        controller.videoDelegate = spyDelegate

        let expectation = expectationWithDescription("Video should be passed on")
        spyDelegate.asyncExpectation = expectation

        controller.camera(camera, didReceiveVideoData: nil, length: 0)

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let videoReceived = spyDelegate.videoReceived else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(videoReceived, "Video data was not passed on")
        }
    }

    func cameraControllerSDError(state: DJICameraSDCardState, reason: String) {
        let camera = DJICamera()

        let controller = CameraController(camera: camera)

        controller.status = .Normal

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("SD Card State change to error should be signalled")
        spyDelegate.asyncExpectation = expectation

        controller.camera(camera, didUpdateSDCardState: state)

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let errored = spyDelegate.errored else {
                XCTFail("Expected delegate to be called")
                return
            }

            guard let errorReason = spyDelegate.errorReason else {
                XCTFail("Expected reason not available")
                return
            }

            XCTAssertTrue(errored, "Error state was not passed on")
            XCTAssertEqual(errorReason, reason, "Error reason was not passed on")
            XCTAssertEqual(controller.status, ControllerStatus.Error, "Controller not in Error status \(controller.status)")
        }
    }

    func testSDCardError() {

        class MockSDCardState: DJICameraSDCardState {
            override var hasError: Bool {
                get {
                    return true
                }
            }
        }

        cameraControllerSDError(MockSDCardState(), reason: "SD Card in error state")
    }

    func testSDCardReadOnly() {

        class MockSDCardState: DJICameraSDCardState {
            override var isReadOnly: Bool {
                get {
                    return true
                }
            }
        }

        cameraControllerSDError(MockSDCardState(), reason: "SD Card is read only")
    }

    func testSDCardInvalidFormat() {

        class MockSDCardState: DJICameraSDCardState {
            override var isInvalidFormat: Bool {
                get {
                    return true
                }
            }
        }

        cameraControllerSDError(MockSDCardState(), reason: "SD Card has invalid format")
    }

    func testSDCardFull() {

        class MockSDCardState: DJICameraSDCardState {
            override var isFull: Bool {
                get {
                    return true
                }
            }
        }

        cameraControllerSDError(MockSDCardState(), reason: "SD Card full")
    }

    func testSDCardMissing() {

        class MockSDCardState: DJICameraSDCardState {
            override var isInserted: Bool {
                get {
                    return false
                }
            }
        }

        cameraControllerSDError(MockSDCardState(), reason: "SD Card missing")
    }

    func testSDCardUnformatted() {

        class MockSDCardState: DJICameraSDCardState {
            override var isInserted: Bool {
                get {
                    return true
                }
            }

            override var isFormatted: Bool {
                get {
                    return false
                }
            }
        }

        cameraControllerSDError(MockSDCardState(), reason: "SD Card requires formatting")
    }

    func testSDCardFormatting() {

        class MockSDCardState: DJICameraSDCardState {
            override var isInserted: Bool {
                get {
                    return true
                }
            }

            override var isFormatted: Bool {
                get {
                    return true
                }
            }

            override var isFormatting: Bool {
                get {
                    return true
                }
            }
        }

        cameraControllerSDError(MockSDCardState(), reason: "SD Card is currently formatting")
    }

    func testSDCardInitializing() {

        class MockSDCardState: DJICameraSDCardState {
            override var isInserted: Bool {
                get {
                    return true
                }
            }

            override var isFormatted: Bool {
                get {
                    return true
                }
            }

            override var isInitializing: Bool {
                get {
                    return true
                }
            }
        }

        cameraControllerSDError(MockSDCardState(), reason: "SD Card is currently initializing")
    }


    func testCameraControllerSDOK() {
        let camera = DJICamera()

        let controller = CameraController(camera: camera)

        controller.status = .Error

        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("SD Card State change to normal should be signalled")
        spyDelegate.asyncExpectation = expectation

        class MockSDCardState: DJICameraSDCardState {
            override var isInserted: Bool {
                get {
                    return true
                }
            }

            override var isFormatted: Bool {
                get {
                    return true
                }
            }
        }

        controller.camera(camera, didUpdateSDCardState: MockSDCardState())

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let ok = spyDelegate.ok else {
                XCTFail("Expected delegate to be called")
                return
            }

            guard let okFromError = spyDelegate.okFromError else {
                XCTFail("Expected reason not available")
                return
            }

            XCTAssertTrue(ok, "Camera did not return to OK")
            XCTAssertTrue(okFromError, "Camera didn't state that it was changing back from Error")
            XCTAssertEqual(controller.status, ControllerStatus.Normal, "Controller not in Normal status \(controller.status)")
        }
    }
}
