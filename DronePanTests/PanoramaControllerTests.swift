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

class PanoramaControllerTests: XCTestCase {
    let panoramaController = PanoramaController()
    
    func testPitchesForTypeNoSkyRowAircraft() {
        let value = panoramaController.pitchesForLoop(skyRow: false, type: .Aircraft, rowCount: 3)

        XCTAssertEqual([0, -30, -60], value, "Incorrect pitches for no sky row for aircraft \(value)")
    }

    func testPitchesForTypeSkyRowAircraft() {
        let value = panoramaController.pitchesForLoop(skyRow: true, type: .Aircraft, rowCount: 3)

        XCTAssertEqual([30, 0, -30, -60], value, "Incorrect pitches for sky row for aircraft \(value)")
    }

    func testPitchesForTypeSkyRowAircraft5Rows() {
        let value = panoramaController.pitchesForLoop(skyRow: true, type: .Aircraft, rowCount: 5)

        XCTAssertEqual([30, 12, -6, -24, -42, -60], value, "Incorrect pitches for sky row for aircraft row count 5 \(value)")
    }

    func testPitchesForTypeNoSkyRowHandheld() {
        let value = panoramaController.pitchesForLoop(skyRow: false, type: .Handheld, rowCount: 3)

        XCTAssertEqual([-60, -30, 0], value, "Incorrect pitches for no sky row for handheld \(value)")
    }

    func testPitchesForTypeSkyRowHandheld() {
        let value = panoramaController.pitchesForLoop(skyRow: true, type: .Handheld, rowCount: 3)

        XCTAssertEqual([-60, -30, 0, 30], value, "Incorrect pitches for sky row for handheld \(value)")
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
}
