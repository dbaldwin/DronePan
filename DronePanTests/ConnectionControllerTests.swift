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
}

class ConnectionControllerTests: XCTestCase {
    var connectionController : ConnectionController?
    
    override func setUp() {
        super.setUp()
        
        self.connectionController = ConnectionController()
    }

    func testFailToRegister() {
        let spyDelegate = ConnectionControllerSpyDelegate()
        connectionController!.delegate = spyDelegate
        
        let expectation = expectationWithDescription("Expect that failure to register will call failedToRegister")
        spyDelegate.asyncExpectation = expectation
        
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
        let spyDelegate = ConnectionControllerSpyDelegate()
        connectionController!.delegate = spyDelegate
        
        let expectation = expectationWithDescription("Expect that registration will call registered")
        spyDelegate.asyncExpectation = expectation
        
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

}