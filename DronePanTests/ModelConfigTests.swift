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

class ModelConfigTests: XCTestCase {
    func testValidSwitchPosition() {
        let testData:[String: DJIRemoteControllerFlightModeSwitchPosition] = [
            DJIAircraftModelNameInspire1: .One,
            DJIAircraftModelNameInspire1Pro: .One,
            DJIAircraftModelNameInspire1RAW: .One,
            DJIAircraftModelNamePhantom3Professional: .One,
            DJIAircraftModelNamePhantom3Advanced: .One,
            DJIAircraftModelNamePhantom3Standard: .One,
            DJIAircraftModelNamePhantom34K: .One,
            DJIAircraftModelNameMatrice100: .One,
            DJIAircraftModelNamePhantom4: .Three,
            DJIAircraftModelNameMatrice600: .One,
            DJIAircraftModelNameA3: .One,
            DJIAircraftModelNameMavicPro: .Two,
            DJIAircraftModelNamePhantom4Pro: .Three
        ]
        
        for (aircraft, position) in testData {
            let (valid, warning) = ModelConfig.correctMode(aircraft, position: position)
            
            XCTAssertTrue(valid, "\(aircraft) incorrect result for switch mode \(warning)")
            XCTAssertNil(warning)

        }
    }
    
    func testInvalidSwitchPosition() {
        let testData:[String: DJIRemoteControllerFlightModeSwitchPosition] = [
            DJIAircraftModelNameInspire1: .Two,
            DJIAircraftModelNameInspire1Pro: .Three,
            DJIAircraftModelNameInspire1RAW: .Two,
            DJIAircraftModelNamePhantom3Professional: .Three,
            DJIAircraftModelNamePhantom3Advanced: .Two,
            DJIAircraftModelNamePhantom3Standard: .Three,
            DJIAircraftModelNamePhantom34K: .Two,
            DJIAircraftModelNameMatrice100: .Three,
            DJIAircraftModelNamePhantom4: .Two,
            DJIAircraftModelNameMatrice600: .Three,
            DJIAircraftModelNameA3: .Two,
            DJIAircraftModelNameMavicPro: .One,
            DJIAircraftModelNamePhantom4Pro: .One
        ]
        
        for (aircraft, position) in testData {
            let (valid, warning) = ModelConfig.correctMode(aircraft, position: position)
            
            XCTAssertFalse(valid, "\(aircraft) incorrect result for switch mode")
            XCTAssertNotNil(warning)
        }
    }
}
