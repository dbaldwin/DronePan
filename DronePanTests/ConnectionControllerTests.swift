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


class ConnectionControllerSpyDelegate: ConnectionControllerDelegate {
    
    var failureReason: String? = .None
    var registered: Bool? = .None
    var component: DJIBaseComponent? = .None
    var componentRemoved: Bool? = .None

    var asyncExpectation: XCTestExpectation?

    @objc func failedToRegister(reason: String) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        failureReason = reason
        expectation.fulfill()
    }
    
    @objc func sdkRegistered() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        registered = true
        expectation.fulfill()
    }
    
    @objc func connectedToBattery(battery: DJIBattery) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        component = battery
        expectation.fulfill()
    }

    
    @objc func connectedToCamera(camera: DJICamera) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        component = camera
        expectation.fulfill()
    }
    
    @objc func connectedToGimbal(gimbal: DJIGimbal) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        component = gimbal
        expectation.fulfill()
    }
    
    @objc func connectedToRemote(remote: DJIRemoteController) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        component = remote
        expectation.fulfill()
    }
    
    @objc func connectedToFlightController(flightController: DJIFlightController) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        component = flightController
        expectation.fulfill()
    }
    
    @objc func disconnectedFromBattery() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        componentRemoved = true
        expectation.fulfill()
    }
    
    @objc func disconnectedFromCamera() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        componentRemoved = true
        expectation.fulfill()
    }

    @objc func disconnectedFromGimbal() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        componentRemoved = true
        expectation.fulfill()
    }

    @objc func disconnectedFromRemote() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        componentRemoved = true
        expectation.fulfill()
    }

    @objc func disconnectedFromFlightController() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegateSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        componentRemoved = true
        expectation.fulfill()
    }
}

class ConnectionControllerTests: XCTestCase {
    var connectionController : ConnectionController?
    
    override func setUp() {
        super.setUp()
        
        self.connectionController = ConnectionController()
    }

    func getSpy(reason: String) -> ConnectionControllerSpyDelegate {
        let spyDelegate = ConnectionControllerSpyDelegate()
        connectionController!.delegate = spyDelegate
        
        let expectation = expectationWithDescription(reason)
        spyDelegate.asyncExpectation = expectation
        
        return spyDelegate
    }
    
    func testFailToRegister() {
        let spyDelegate = getSpy("Expect that failure to register will call failedToRegister")
        
        connectionController!.sdkManagerDidRegisterAppWithError(NSError(domain: "Test", code: 20, userInfo: ["Testing": "Testing"]))
        
        waitForExpectationsWithTimeout(1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
            
            guard let reason = spyDelegate.failureReason else {
                XCTFail("Expected delegate to be called")
                return
            }
            
            XCTAssertEqual("Unable to register application - make sure you run at least once with internet access", reason, "Incorrect failure reason")
        }
    }

    func testRegister() {
        let spyDelegate = getSpy("Expect that registration will call registered")

        connectionController!.sdkManagerDidRegisterAppWithError(nil)
        
        waitForExpectationsWithTimeout(1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
            
            guard let registered = spyDelegate.registered else {
                XCTFail("Expected delegate to be called")
                return
            }
            
            XCTAssertTrue(registered, "Registration didn't call register")
        }
    }

    func testRegisterSimulator() {
        let spyDelegate = getSpy("Expect that registration will call registered")

        connectionController!.connectToSimulator = true
        
        connectionController!.sdkManagerDidRegisterAppWithError(nil)
        
        waitForExpectationsWithTimeout(1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
            
            guard let registered = spyDelegate.registered else {
                XCTFail("Expected delegate to be called")
                return
            }
            
            XCTAssertTrue(registered, "Registration didn't call register")
        }
    }

    func newComponent(key: String, component: DJIBaseComponent) {
        let spyDelegate = getSpy("Expect that a new \(key) will be passed on")
        
        connectionController!.componentWithKey(key, changedFrom: nil, to: component)
        
        waitForExpectationsWithTimeout(1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
            
            guard let newComponent = spyDelegate.component else {
                XCTFail("Expected delegate to be called")
                return
            }
            
            XCTAssertEqual(component, newComponent, "Didn't see \(key)")
        }
        
    }
    
    func testBatterySeen() {
        newComponent(DJIBatteryComponentKey, component: DJIBattery())
    }
    
    func testCameraSeen() {
        newComponent(DJICameraComponentKey, component: DJICamera())
    }
    
    func testGimbalSeen() {
        newComponent(DJIGimbalComponentKey, component: DJIGimbal())
    }
    
    func testRemoteSeen() {
        newComponent(DJIRemoteControllerComponentKey, component: DJIRemoteController())
    }
    
    func testFlightControllerSeen() {
        newComponent(DJIFlightControllerComponentKey, component: DJIFlightController())
    }

    func loseComponent(key: String) {
        let spyDelegate = getSpy("Expect that a loss of \(key) will be passed on")
        
        connectionController!.componentWithKey(key, changedFrom: nil, to: nil)
        
        waitForExpectationsWithTimeout(1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
            
            guard let componentRemoved = spyDelegate.componentRemoved else {
                XCTFail("Expected delegate to be called")
                return
            }
            
            XCTAssertTrue(componentRemoved, "Wasn't told that \(key) was lost")
        }
    }
    
    func testBatteryLost() {
        loseComponent(DJIBatteryComponentKey)
    }
    
    func testCameraLost() {
        loseComponent(DJICameraComponentKey)
    }
    
    func testGimbalLost() {
        loseComponent(DJIGimbalComponentKey)
    }
    
    func testRemoteLost() {
        loseComponent(DJIRemoteControllerComponentKey)
    }
    
    func testFlightControllerLost() {
        loseComponent(DJIFlightControllerComponentKey)
    }
}