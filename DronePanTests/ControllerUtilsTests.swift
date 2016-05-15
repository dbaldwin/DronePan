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

class ControllerUtilsTests: XCTestCase {
    override func setUp() {
        super.setUp()

        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
    }

    func testIsInspire() {
        XCTAssertTrue(ControllerUtils.isInspire(DJIAircraftModelNameInspire1), "\(DJIAircraftModelNameInspire1) was not inspire")
        XCTAssertTrue(ControllerUtils.isInspire(DJIAircraftModelNameInspire1RAW), "\(DJIAircraftModelNameInspire1RAW) was not inspire")
        XCTAssertTrue(ControllerUtils.isInspire(DJIAircraftModelNameInspire1Pro), "\(DJIAircraftModelNameInspire1Pro) was not inspire")

        XCTAssertFalse(ControllerUtils.isInspire(DJIAircraftModelNamePhantom4), "\(DJIAircraftModelNamePhantom4) was inspire")
        XCTAssertFalse(ControllerUtils.isInspire(DJIAircraftModelNamePhantom3Professional), "\(DJIAircraftModelNamePhantom3Professional) was inspire")
        XCTAssertFalse(ControllerUtils.isInspire(DJIAircraftModelNamePhantom3Standard), "\(DJIAircraftModelNamePhantom3Standard) was inspire")
        XCTAssertFalse(ControllerUtils.isInspire(DJIAircraftModelNamePhantom3Advanced), "\(DJIAircraftModelNamePhantom3Advanced) was inspire")
        XCTAssertFalse(ControllerUtils.isInspire(DJIAircraftModelNamePhantom34K), "\(DJIAircraftModelNamePhantom34K) was inspire")
    }

    func testIsPhantom3() {
        XCTAssertFalse(ControllerUtils.isPhantom3(DJIAircraftModelNameInspire1), "\(DJIAircraftModelNameInspire1) was phantom 3")
        XCTAssertFalse(ControllerUtils.isPhantom3(DJIAircraftModelNameInspire1RAW), "\(DJIAircraftModelNameInspire1RAW) was phantom 3")
        XCTAssertFalse(ControllerUtils.isPhantom3(DJIAircraftModelNameInspire1Pro), "\(DJIAircraftModelNameInspire1Pro) was phantom 3")

        XCTAssertFalse(ControllerUtils.isPhantom3(DJIAircraftModelNamePhantom4), "\(DJIAircraftModelNamePhantom4) was phantom 3")

        XCTAssertTrue(ControllerUtils.isPhantom3(DJIAircraftModelNamePhantom3Professional), "\(DJIAircraftModelNamePhantom3Professional) was not phantom 3")
        XCTAssertTrue(ControllerUtils.isPhantom3(DJIAircraftModelNamePhantom3Standard), "\(DJIAircraftModelNamePhantom3Standard) was not phantom 3")
        XCTAssertTrue(ControllerUtils.isPhantom3(DJIAircraftModelNamePhantom3Advanced), "\(DJIAircraftModelNamePhantom3Advanced) was not phantom 3")
        XCTAssertTrue(ControllerUtils.isPhantom3(DJIAircraftModelNamePhantom34K), "\(DJIAircraftModelNamePhantom34K) was not phantom 3")
    }

    func testIsPhantom4() {
        XCTAssertFalse(ControllerUtils.isPhantom4(DJIAircraftModelNameInspire1), "\(DJIAircraftModelNameInspire1) was phantom 4")
        XCTAssertFalse(ControllerUtils.isPhantom4(DJIAircraftModelNameInspire1RAW), "\(DJIAircraftModelNameInspire1RAW) was phantom 4")
        XCTAssertFalse(ControllerUtils.isPhantom4(DJIAircraftModelNameInspire1Pro), "\(DJIAircraftModelNameInspire1Pro) was phantom 4")

        XCTAssertTrue(ControllerUtils.isPhantom4(DJIAircraftModelNamePhantom4), "\(DJIAircraftModelNamePhantom4) was not phantom 4")

        XCTAssertFalse(ControllerUtils.isPhantom4(DJIAircraftModelNamePhantom3Professional), "\(DJIAircraftModelNamePhantom3Professional) was phantom 4")
        XCTAssertFalse(ControllerUtils.isPhantom4(DJIAircraftModelNamePhantom3Standard), "\(DJIAircraftModelNamePhantom3Standard) was phantom 4")
        XCTAssertFalse(ControllerUtils.isPhantom4(DJIAircraftModelNamePhantom3Advanced), "\(DJIAircraftModelNamePhantom3Advanced) was phantom 4")
        XCTAssertFalse(ControllerUtils.isPhantom4(DJIAircraftModelNamePhantom34K), "\(DJIAircraftModelNamePhantom34K) was phantom 4")
    }

    func testIsPhantom() {
        XCTAssertFalse(ControllerUtils.isPhantom(DJIAircraftModelNameInspire1), "\(DJIAircraftModelNameInspire1) was phantom")
        XCTAssertFalse(ControllerUtils.isPhantom(DJIAircraftModelNameInspire1RAW), "\(DJIAircraftModelNameInspire1RAW) was phantom")
        XCTAssertFalse(ControllerUtils.isPhantom(DJIAircraftModelNameInspire1Pro), "\(DJIAircraftModelNameInspire1Pro) was phantom")

        XCTAssertTrue(ControllerUtils.isPhantom(DJIAircraftModelNamePhantom4), "\(DJIAircraftModelNamePhantom4) was not phantom")

        XCTAssertTrue(ControllerUtils.isPhantom(DJIAircraftModelNamePhantom3Professional), "\(DJIAircraftModelNamePhantom3Professional) was not phantom")
        XCTAssertTrue(ControllerUtils.isPhantom(DJIAircraftModelNamePhantom3Standard), "\(DJIAircraftModelNamePhantom3Standard) was not phantom")
        XCTAssertTrue(ControllerUtils.isPhantom(DJIAircraftModelNamePhantom3Advanced), "\(DJIAircraftModelNamePhantom3Advanced) was not phantom")
        XCTAssertTrue(ControllerUtils.isPhantom(DJIAircraftModelNamePhantom34K), "\(DJIAircraftModelNamePhantom34K) was not phantom")
    }

    func testGimbalYawIsRelativeToAircraft() {
        XCTAssertTrue(ControllerUtils.gimbalYawIsRelativeToAircraft(DJIAircraftModelNameInspire1), "\(DJIAircraftModelNameInspire1) gimbal yaw was not relative")
        XCTAssertTrue(ControllerUtils.gimbalYawIsRelativeToAircraft(DJIAircraftModelNameInspire1RAW), "\(DJIAircraftModelNameInspire1RAW) gimbal yaw was not relative")
        XCTAssertTrue(ControllerUtils.gimbalYawIsRelativeToAircraft(DJIAircraftModelNameInspire1Pro), "\(DJIAircraftModelNameInspire1Pro) gimbal yaw was not relative")

        XCTAssertTrue(ControllerUtils.gimbalYawIsRelativeToAircraft(DJIAircraftModelNamePhantom4), "\(DJIAircraftModelNamePhantom4) gimbal yaw was not relative")

        XCTAssertFalse(ControllerUtils.gimbalYawIsRelativeToAircraft(DJIAircraftModelNamePhantom3Professional), "\(DJIAircraftModelNamePhantom3Professional) gimbal yaw was relative")
        XCTAssertFalse(ControllerUtils.gimbalYawIsRelativeToAircraft(DJIAircraftModelNamePhantom3Standard), "\(DJIAircraftModelNamePhantom3Standard) gimbal yaw was relative")
        XCTAssertFalse(ControllerUtils.gimbalYawIsRelativeToAircraft(DJIAircraftModelNamePhantom3Advanced), "\(DJIAircraftModelNamePhantom3Advanced) gimbal yaw was relative")
        XCTAssertFalse(ControllerUtils.gimbalYawIsRelativeToAircraft(DJIAircraftModelNamePhantom34K), "\(DJIAircraftModelNamePhantom34K) gimbal yaw was relative")

        XCTAssertFalse(ControllerUtils.gimbalYawIsRelativeToAircraft(DJIHandheldModelNameOsmo), "\(DJIHandheldModelNameOsmo) gimbal yaw was relative")
        XCTAssertFalse(ControllerUtils.gimbalYawIsRelativeToAircraft(DJIHandheldModelNameOsmoPro), "\(DJIHandheldModelNameOsmoPro) gimbal yaw was relative")

        XCTAssertFalse(ControllerUtils.gimbalYawIsRelativeToAircraft(nil), "Missing model gimbal yaw was relative")
    }

    func testDefaultDisplayIsInMeters() {
        let value = ControllerUtils.displayDistance(10)

        XCTAssertEqual(value, "10m", "Incorrect display \(value)")
    }

    func testDisplayIsInMeters() {
        ControllerUtils.setMetricUnits(true)

        let value = ControllerUtils.displayDistance(10)

        XCTAssertEqual(value, "10m", "Incorrect display \(value)")
    }

    func testDisplayIsInFeet() {
        ControllerUtils.setMetricUnits(false)

        let value = ControllerUtils.displayDistance(10)

        XCTAssertEqual(value, "33'", "Incorrect display \(value)")
    }
}
