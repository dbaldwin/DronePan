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

@testable import DronePan

// This file tests dispatch group handling. It is the responsbility of the tests to make sure that we are correctly paired enter/leave

class ActiveAwareDispatchGroupTests: XCTestCase {

    func testSetsName() {
        let group = ActiveAwareDispatchGroup(name: "Testing")
        
        XCTAssertEqual(group.name, "Testing", "Incorrect name \(group.name)")
        
    }

    func testEnterLeave() {
        let group = ActiveAwareDispatchGroup(name: "Testing")

        group.enter()
        
        XCTAssertTrue(group.active, "Enter didn't set active")
        
        let result = group.leave()

        XCTAssertFalse(group.active, "Leave didn't reset")
        
        XCTAssertTrue(result, "Leave didn't actually leave")
    }
    
    func testEnterLeaveIfActive() {
        let group = ActiveAwareDispatchGroup(name: "Testing")
        
        group.enter()
        
        XCTAssertTrue(group.active, "Enter didn't set active")
        
        let result = group.leaveIfActive()
        
        XCTAssertFalse(group.active, "Leave didn't reset")
        
        XCTAssertTrue(result, "Leave didn't actually leave")
    }

    func testLeaveIfActive() {
        let group = ActiveAwareDispatchGroup(name: "Testing")
        
        dispatch_group_enter(group.group)
        
        XCTAssertFalse(group.active, "Active without enter")
        
        let result = group.leave()
        
        XCTAssertFalse(result, "Leave reset active")
    }

    func testLeave() {
        let group = ActiveAwareDispatchGroup(name: "Testing")

        dispatch_group_enter(group.group)
        
        XCTAssertFalse(group.active, "Active without enter")
        
        let result = group.leaveIfActive()
        
        XCTAssertFalse(result, "Leave reset active")

        dispatch_group_leave(group.group)
    }

    func testWait() {
        let group = ActiveAwareDispatchGroup(name: "Testing")

        group.enter()
        
        let expectation = expectationWithDescription("wait should exit when leave called")

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            group.wait()
        
            expectation.fulfill()
        })

        group.leave()
        
        waitForExpectationsWithTimeout(2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
            
            XCTAssertFalse(group.active, "Group left in active state")

        }
    }
    
}
