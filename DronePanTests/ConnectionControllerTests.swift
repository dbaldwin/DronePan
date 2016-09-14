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
    var product: DJIBaseProduct? = .None
    var productRemoved: Bool? = .None
    var component: DJIBaseComponent? = .None
    var componentRemoved: Bool? = .None

    var asyncExpectation: XCTestExpectation?

    func failedToRegister(reason: String) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        failureReason = reason
        expectation.fulfill()
    }

    func sdkRegistered() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        registered = true
        expectation.fulfill()
    }

    func connectedToBattery(battery: DJIBattery) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        component = battery
        expectation.fulfill()
    }


    func connectedToCamera(camera: DJICamera) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        component = camera
        expectation.fulfill()
    }

    func connectedToGimbal(gimbal: DJIGimbal) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        component = gimbal
        expectation.fulfill()
    }

    func connectedToRemote(remote: DJIRemoteController) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        component = remote
        expectation.fulfill()
    }

    func connectedToFlightController(flightController: DJIFlightController) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        component = flightController
        expectation.fulfill()
    }

    func disconnectedFromBattery() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        componentRemoved = true
        expectation.fulfill()
    }

    func disconnectedFromCamera() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        componentRemoved = true
        expectation.fulfill()
    }

    func disconnectedFromGimbal() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        componentRemoved = true
        expectation.fulfill()
    }

    func disconnectedFromRemote() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        componentRemoved = true
        expectation.fulfill()
    }

    func disconnectedFromFlightController() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        componentRemoved = true
        expectation.fulfill()
    }
    
    func firmwareVersion(version: String) {
        
    }
    

    func connectedToProduct(product: DJIBaseProduct) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.product = product
        expectation.fulfill()
    }

    func disconnected() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.productRemoved = true
        expectation.fulfill()
    }
}

class ConnectionControllerDiagnosticsSpyDelegate: ConnectionControllerDiagnosticsDelegate {

    var code: Int? = .None
    var reason: String? = .None
    var solution: String? = .None

    var asyncExpectation: XCTestExpectation?

    func diagnosticsSeen(code code: Int, reason: String, solution: String?) {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.code = code
        self.reason = reason
        self.solution = solution

        expectation.fulfill()
    }
}

class ConnectionControllerTests: XCTestCase {
    var connectionController: ConnectionController?

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

        waitForExpectationsWithTimeout(1) {
            error in
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

        waitForExpectationsWithTimeout(1) {
            error in
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

        connectionController!.runInBridgeMode = true

        connectionController!.sdkManagerDidRegisterAppWithError(nil)

        waitForExpectationsWithTimeout(1) {
            error in
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

        waitForExpectationsWithTimeout(1) {
            error in
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
        newComponent(DJIBatteryComponent, component: DJIBattery())
    }

    func testCameraSeen() {
        newComponent(DJICameraComponent, component: DJICamera())
    }

    func testGimbalSeen() {
        newComponent(DJIGimbalComponent, component: DJIGimbal())
    }

    func testRemoteSeen() {
        newComponent(DJIRemoteControllerComponent, component: DJIRemoteController())
    }

    func testFlightControllerSeen() {
        newComponent(DJIFlightControllerComponent, component: DJIFlightController())
    }

    func loseComponent(key: String) {
        let spyDelegate = getSpy("Expect that a loss of \(key) will be passed on")

        connectionController!.componentWithKey(key, changedFrom: nil, to: nil)

        waitForExpectationsWithTimeout(1) {
            error in
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
        loseComponent(DJIBatteryComponent)
    }

    func testCameraLost() {
        loseComponent(DJICameraComponent)
    }

    func testGimbalLost() {
        loseComponent(DJIGimbalComponent)
    }

    func testRemoteLost() {
        loseComponent(DJIRemoteControllerComponent)
    }

    func testFlightControllerLost() {
        loseComponent(DJIFlightControllerComponent)
    }

    func testConnected() {
        let spyDelegate = getSpy("Expect that a new product will cause connection")

        let newProduct = DJIBaseProduct()

        connectionController!.sdkManagerProductDidChangeFrom(nil, to: newProduct)

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let product = spyDelegate.product else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual(product, newProduct, "Wasn't told that connection was made")
        }
    }

    func testDisconnected() {
        let spyDelegate = getSpy("Expect that a loss of product will cause disconnection")

        connectionController!.sdkManagerProductDidChangeFrom(nil, to: nil)

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let productRemoved = spyDelegate.productRemoved else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(productRemoved, "Wasn't told that connection was lost")
        }
    }

    func testDiagnostic() {
        let spyDelegate = ConnectionControllerDiagnosticsSpyDelegate()
        connectionController!.diagnosticsDelegate = spyDelegate

        let expectation = expectationWithDescription("Diagnostics should be passed on")
        spyDelegate.asyncExpectation = expectation

        class DiagnosticMock: DJIDiagnostics {
            override var code: Int {
                get {
                    return 1
                }
            }

            override var reason: String {
                get {
                    return "Test Reason"
                }
            }

            override var solution: String? {
                get {
                    return "Test Solution"
                }
            }
        }

        connectionController!.product(DJIBaseProduct(), didUpdateDiagnosticsInformation: [DiagnosticMock()])

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let code = spyDelegate.code else {
                XCTFail("Expected delegate to be called with code")
                return
            }

            XCTAssertEqual(code, 1, "Code was incorrect, \(code)")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called with reason")
                return
            }

            XCTAssertEqual(reason, "Test Reason", "Reason was incorrect \(reason)")

            guard let solution = spyDelegate.solution else {
                XCTFail("Expected delegate to be called with solution")
                return
            }

            XCTAssertEqual(solution, "Test Solution", "Solution was incorrect \(solution)")
        }
    }
    
    func testBridgeModeSetting() {
        // This test is to flag if we commit the ConnectionController with bridge mode set true after testing
        
        let controller = ConnectionController()
        
        XCTAssertFalse(controller.runInBridgeMode, "Connection Controller is set up for bridge mode")
    }
}