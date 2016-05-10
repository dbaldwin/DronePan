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

class CameraControllerSpyDelegate: CameraControllerDelegate {
    
    var completed: Bool? = .None
    var shotTaken: Bool? = .None
    var aborted: Bool? = .None
    var abortReason : String? = .None
    
    var asyncExpectation: XCTestExpectation?

    func cameraControllerReset() {
        // NOP
    }
    
    func cameraControllerOK(fromError: Bool) {
        // NOP
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
    
    func cameraControllerInError(reason: String) {
        // NOP
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

    class ModeStateMock : DJICameraSystemState {
        
        var internalMode : DJICameraMode
        
        init(mode: DJICameraMode) {
            self.internalMode = mode
        }
        
        override var mode: DJICameraMode {
            get {
                return internalMode
            }
        }
    }

    func testSetPhotoMode() {
        class CameraMock : DJICamera {
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
        
        waitForExpectationsWithTimeout(3) { error in
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
        class CameraMock : DJICamera {
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
        
        waitForExpectationsWithTimeout(5) { error in
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
        class CameraMock : DJICamera {
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
        
        waitForExpectationsWithTimeout(15) { error in
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
    
    func testSetPhotoModeError() {
        class CameraMock : DJICamera {
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
        
        waitForExpectationsWithTimeout(13) { error in
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
}
