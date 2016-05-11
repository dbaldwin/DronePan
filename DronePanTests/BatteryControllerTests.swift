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

class BatteryControllerSpyDelegate: BatteryControllerDelegate {

    var percent: Int? = .None
    var temperature: Int? = .None

    var asyncExpectation: XCTestExpectation?

    var percentFulfill: Bool = false
    var temperatureFulfill: Bool = false

    func batteryControllerPercentUpdated(batteryPercent: Int) {
        if !percentFulfill {
            return
        }

        guard let expectation = asyncExpectation else {
            XCTFail("RemoteControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        percent = batteryPercent
        expectation.fulfill()
    }

    func batteryControllerTemperatureUpdated(batteryTemperature: Int) {
        if !temperatureFulfill {
            return
        }

        guard let expectation = asyncExpectation else {
            XCTFail("RemoteControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        temperature = batteryTemperature
        expectation.fulfill()
    }
}

class BatteryStateMock: DJIBatteryState {
    var internalPercent: Int
    var internalTemperature: Int

    override var batteryEnergyRemainingPercent: Int {
        get {
            return internalPercent
        }
    }

    override var batteryTemperature: Int {
        get {
            return internalTemperature
        }
    }

    init(percent: Int, temperature: Int) {
        self.internalPercent = percent
        self.internalTemperature = temperature
    }
}

class BatteryControllerTests: XCTestCase {
    var batteryController: BatteryController?
    var battery = DJIBattery()

    override func setUp() {
        super.setUp()

        self.batteryController = BatteryController(battery: battery)
    }

    func getSpy(reason: String) -> BatteryControllerSpyDelegate {
        let spyDelegate = BatteryControllerSpyDelegate()
        batteryController!.delegate = spyDelegate

        let expectation = expectationWithDescription(reason)
        spyDelegate.asyncExpectation = expectation

        return spyDelegate
    }

    func testBatteryChange() {
        let spyDelegate = getSpy("Expect that change in battery is passed on")
        spyDelegate.percentFulfill = true

        let state = BatteryStateMock(percent: 30, temperature: 30)

        batteryController!.battery(battery, didUpdateState: state)

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let percent = spyDelegate.percent else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual(30, percent, "Incorrect battery percent")
        }
    }

    func testBatteryTemperatureChange() {
        let spyDelegate = getSpy("Expect that change in battery temperature is passed on")
        spyDelegate.temperatureFulfill = true

        let state = BatteryStateMock(percent: 30, temperature: 30)

        batteryController!.battery(battery, didUpdateState: state)

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let temperature = spyDelegate.temperature else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual(30, temperature, "Incorrect battery temperature")
        }
    }
}