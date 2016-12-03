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
    func testSwitchPosition() {
        let results:[String: FlightMode] = [
            DJIAircraftModelNameInspire1: .Function,
            DJIAircraftModelNameInspire1Pro: .Function,
            DJIAircraftModelNameInspire1RAW: .Function,
            DJIAircraftModelNamePhantom3Professional: .Function,
            DJIAircraftModelNamePhantom3Advanced: .Function,
            DJIAircraftModelNamePhantom3Standard: .Function,
            DJIAircraftModelNamePhantom34K: .Function,
            DJIAircraftModelNameMatrice100: .Function,
            DJIAircraftModelNamePhantom4: .Positioning,
            DJIAircraftModelNameMatrice600: .Function,
            DJIAircraftModelNameA3: .Function
        ]
        
        for (aircraft, result) in results {
            XCTAssertTrue(ModelConfig.switchMode(aircraft) == result, "\(aircraft) incorrect result for switch mode")
        }
    }
}
