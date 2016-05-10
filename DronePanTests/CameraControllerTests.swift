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
    
    var asyncExpectation: XCTestExpectation?

    func cameraControllerReset() {
        // NOP
    }
    
    func cameraControllerOK(fromError: Bool) {
        // NOP
    }
    
    func cameraControllerAborted(reason: String) {
        // NOP
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
    
    func testSetPhotoMode() {
        class CameraMock : DJICamera {
            override func setCameraMode(mode: DJICameraMode, withCompletion block: DJICompletionBlock?) {
                class StateMock : DJICameraSystemState {

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
                
                let state = StateMock(mode: mode)

                self.delegate?.camera?(self, didUpdateSystemState: state)
            }
        }
        
        let controller = CameraController(camera: CameraMock())
        
        let spyDelegate = CameraControllerSpyDelegate()
        controller.delegate = spyDelegate
            
        let expectation = expectationWithDescription("Setting mode should complete")
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
        }
    }
}
