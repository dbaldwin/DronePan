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

class MainViewControllerTests: XCTestCase {
    var controller = ViewController()
    
    func testYawAnglesForCount10WithHeading0() {
        let value = controller.yawAnglesForCount(10, withHeading: 0) as! [Int]
        
        XCTAssertEqual([36, 72, 108, 144, 180, 216, 252, 288, 324, 360], value, "Incorrect angles for count 10 heading 0 \(value)")
    }

    func testYawAnglesForCount6WithHeading0() {
        let value = controller.yawAnglesForCount(6, withHeading: 0) as! [Int]
        
        XCTAssertEqual([60, 120, 180, 240, 300, 360], value, "Incorrect angles for count 6 heading 0 \(value)")
    }

    func testYawAnglesForCount10WithHeading84() {
        let value = controller.yawAnglesForCount(10, withHeading: 84) as! [Int]
        
        XCTAssertEqual([120, 156, 192, 228, 264, 300, 336, 12, 48, 84], value, "Incorrect angles for count 10 heading 84 \(value)")
    }
    
    func testYawAnglesForCount6WithHeadingNeg84() {
        let value = controller.yawAnglesForCount(6, withHeading: -84) as! [Int]
        
        XCTAssertEqual([-24, 36, 96, 156, 216, 276], value, "Incorrect angles for count 6 heading -84 \(value)")
    }

    func testPitchesForTypeNoSkyRowAircraft() {
        let value = controller.pitchesForLoopWithSkyRow(false, forType: PT_AIRCRAFT, andRowCount: 3) as! [Int]
        
        XCTAssertEqual([0, -30, -60], value, "Incorrect pitches for no sky row for aircraft \(value)")
    }

    func testPitchesForTypeSkyRowAircraft() {
        let value = controller.pitchesForLoopWithSkyRow(true, forType: PT_AIRCRAFT, andRowCount: 3) as! [Int]
        
        XCTAssertEqual([30, 0, -30, -60], value, "Incorrect pitches for sky row for aircraft \(value)")
    }

    func testPitchesForTypeSkyRowAircraft5Rows() {
        let value = controller.pitchesForLoopWithSkyRow(true, forType: PT_AIRCRAFT, andRowCount: 5) as! [Int]
        
        XCTAssertEqual([30, 12, -6, -24, -42, -60], value, "Incorrect pitches for sky row for aircraft row count 5 \(value)")
    }

    func testPitchesForTypeNoSkyRowHandheld() {
        let value = controller.pitchesForLoopWithSkyRow(false, forType: PT_HANDHELD, andRowCount: 3) as! [Int]
        
        XCTAssertEqual([-60, -30, 0], value, "Incorrect pitches for no sky row for handheld \(value)")
    }

    func testPitchesForTypeSkyRowHandheld() {
        let value = controller.pitchesForLoopWithSkyRow(true, forType: PT_HANDHELD, andRowCount: 3) as! [Int]
        
        XCTAssertEqual([-60, -30, 0, 30], value, "Incorrect pitches for sky row for handheld \(value)")
    }
    
}
