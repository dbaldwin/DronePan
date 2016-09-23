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
        let results = [
            DJIAircraftModelNameInspire1: true,
            DJIAircraftModelNameInspire1Pro: true,
            DJIAircraftModelNameInspire1RAW: true,
            DJIAircraftModelNamePhantom3Professional: false,
            DJIAircraftModelNamePhantom3Advanced: false,
            DJIAircraftModelNamePhantom3Standard: false,
            DJIAircraftModelNamePhantom34K: false,
            DJIAircraftModelNameMatrice100: false,
            DJIAircraftModelNamePhantom4: false,
            DJIAircraftModelNameMatrice600: false,
            DJIAircraftModelNameA3: false
        ]
        
        for (aircraft, result) in results {
            XCTAssertTrue(ControllerUtils.isInspire(aircraft) == result, "\(aircraft) incorrect result for inspire")
        }
    }

    func testIsPhantom3() {
        let results = [
            DJIAircraftModelNameInspire1: false,
            DJIAircraftModelNameInspire1Pro: false,
            DJIAircraftModelNameInspire1RAW: false,
            DJIAircraftModelNamePhantom3Professional: true,
            DJIAircraftModelNamePhantom3Advanced: true,
            DJIAircraftModelNamePhantom3Standard: true,
            DJIAircraftModelNamePhantom34K: true,
            DJIAircraftModelNameMatrice100: false,
            DJIAircraftModelNamePhantom4: false,
            DJIAircraftModelNameMatrice600: false,
            DJIAircraftModelNameA3: false
        ]
        
        for (aircraft, result) in results {
            XCTAssertTrue(ControllerUtils.isPhantom3(aircraft) == result, "\(aircraft) incorrect result for phantom 3")
        }
    }

    func testIsPhantom4() {
        let results = [
            DJIAircraftModelNameInspire1: false,
            DJIAircraftModelNameInspire1Pro: false,
            DJIAircraftModelNameInspire1RAW: false,
            DJIAircraftModelNamePhantom3Professional: false,
            DJIAircraftModelNamePhantom3Advanced: false,
            DJIAircraftModelNamePhantom3Standard: false,
            DJIAircraftModelNamePhantom34K: false,
            DJIAircraftModelNameMatrice100: false,
            DJIAircraftModelNamePhantom4: true,
            DJIAircraftModelNameMatrice600: false,
            DJIAircraftModelNameA3: false
        ]
        
        for (aircraft, result) in results {
            XCTAssertTrue(ControllerUtils.isPhantom4(aircraft) == result, "\(aircraft) incorrect result for phantom 4")
        }
    }

    func testIsPhantom() {
        let results = [
            DJIAircraftModelNameInspire1: false,
            DJIAircraftModelNameInspire1Pro: false,
            DJIAircraftModelNameInspire1RAW: false,
            DJIAircraftModelNamePhantom3Professional: true,
            DJIAircraftModelNamePhantom3Advanced: true,
            DJIAircraftModelNamePhantom3Standard: true,
            DJIAircraftModelNamePhantom34K: true,
            DJIAircraftModelNameMatrice100: false,
            DJIAircraftModelNamePhantom4: true,
            DJIAircraftModelNameMatrice600: false,
            DJIAircraftModelNameA3: false
        ]
        
        for (aircraft, result) in results {
            XCTAssertTrue(ControllerUtils.isPhantom(aircraft) == result, "\(aircraft) incorrect result for phantom")
        }
    }
    
    func testIsMatrice() {
        let results = [
            DJIAircraftModelNameInspire1: false,
            DJIAircraftModelNameInspire1Pro: false,
            DJIAircraftModelNameInspire1RAW: false,
            DJIAircraftModelNamePhantom3Professional: false,
            DJIAircraftModelNamePhantom3Advanced: false,
            DJIAircraftModelNamePhantom3Standard: false,
            DJIAircraftModelNamePhantom34K: false,
            DJIAircraftModelNameMatrice100: true,
            DJIAircraftModelNamePhantom4: false,
            DJIAircraftModelNameMatrice600: true,
            DJIAircraftModelNameA3: false
        ]
        
        for (aircraft, result) in results {
            XCTAssertTrue(ControllerUtils.isMatrice(aircraft) == result, "\(aircraft) incorrect result for matrice")
        }
    }

    
    func testGimbalYawIsRelativeToAircraft() {
        let results = [
            DJIAircraftModelNameInspire1: true,
            DJIAircraftModelNameInspire1Pro: true,
            DJIAircraftModelNameInspire1RAW: true,
            DJIAircraftModelNamePhantom3Professional: false,
            DJIAircraftModelNamePhantom3Advanced: false,
            DJIAircraftModelNamePhantom3Standard: false,
            DJIAircraftModelNamePhantom34K: false,
            DJIAircraftModelNameMatrice100: true,
            DJIAircraftModelNamePhantom4: true,
            DJIAircraftModelNameMatrice600: true,
            DJIAircraftModelNameA3: false
        ]
        
        for (aircraft, result) in results {
            XCTAssertTrue(ControllerUtils.gimbalYawIsRelativeToAircraft(aircraft) == result, "\(aircraft) incorrect result for gimbal yaw")
        }
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
