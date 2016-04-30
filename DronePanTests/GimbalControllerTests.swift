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

class GimbalControllerTests: XCTestCase {
    var gimbalController : GimbalController?

    override func setUp() {
        super.setUp()

        let gimbal = DJIGimbal()

        self.gimbalController = GimbalController(gimbal: gimbal)
    }

    func compare(angle: Float, heading: Float) {
        let value = gimbalController!.gimbalAngleForHeading(heading)

        XCTAssertEqual(angle, value, "Incorrect angle \(value) for heading \(heading)")
    }

    func testGimbalAngleForHeading() {
        compare(   0, heading:    0)
        compare(  90, heading:   90)
        compare( 180, heading:  180)
        compare(-179, heading:  181)
        compare( -90, heading:  270)
        compare(  -1, heading:  359)
        compare(   0, heading:  360)
        compare( -90, heading:  -90)
        compare(-180, heading: -180)
        compare( 179, heading: -181)
        compare(  90, heading: -270)
        compare(   1, heading: -359)
        compare(   0, heading:  720)
        compare(   0, heading: -720)
        compare(   1, heading:  721)
        compare(  -1, heading: -721)
        compare(-144, heading:  216)
    }
    
    func testInRange() {
        let value = gimbalController!.inRange(10, range: 9..<11, available: true)
        
        XCTAssertTrue(value, "In range was out of range")
    }
    
    func testInRangeNotAvailable() {
        let value = gimbalController!.inRange(10, range: 9..<11, available: false)
        
        XCTAssertFalse(value, "In range was in range when not available")
    }

    func testBelowRange() {
        let value = gimbalController!.inRange(7, range: 9..<11, available: true)
        
        XCTAssertFalse(value, "Below range was in range")
    }

    func testBelowRangeNotAvailable() {
        let value = gimbalController!.inRange(7, range: 9..<11, available: false)
        
        XCTAssertFalse(value, "Below range was in range when not available")
    }

    func testAboveRange() {
        let value = gimbalController!.inRange(13, range: 9..<11, available: true)
        
        XCTAssertFalse(value, "Above range was in range")
    }
    
    func testAboveRangeNotAvailable() {
        let value = gimbalController!.inRange(13, range: 9..<11, available: false)
        
        XCTAssertFalse(value, "Above range was in range when not available")
    }

    func testNoRange() {
        let value = gimbalController!.inRange(13, range: nil, available: true)
        
        XCTAssertFalse(value, "No range was in range")
    }
    
    func testValueInRange() {
        let value = gimbalController!.valueInRange(true, value: 10, currentValue: 10)
        
        XCTAssertTrue(value, "Value was not in range")
    }

    func testValueBelowRange() {
        let value = gimbalController!.valueInRange(true, value: 10 - gimbalController!.allowedOffset - 0.1, currentValue: 10)
        
        XCTAssertFalse(value, "Value was not out of range")
    }

    func testValueAboveRange() {
        let value = gimbalController!.valueInRange(true, value: 10 + gimbalController!.allowedOffset + 0.1, currentValue: 10)
        
        XCTAssertFalse(value, "Value was not out of range")
    }
    
    func testCheck() {
        gimbalController!.currentPitch = 90
        gimbalController!.currentYaw = 120
        gimbalController!.currentRoll = 110
        
        let value = gimbalController!.check(pitch: 9, yaw: 12, roll: 11)

        XCTAssertTrue(value, "Test gimbal has no capabilities but still checked range")

    }
}


