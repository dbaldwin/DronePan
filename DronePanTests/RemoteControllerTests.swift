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


class RemoteControllerSpyDelegate: RemoteControllerDelegate {

    var percent: Int? = .None

    var asyncExpectation: XCTestExpectation?

    func remoteControllerBatteryPercentUpdated(batteryPercent: Int) {
        guard let expectation = asyncExpectation else {
            XCTFail("RemoteControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        percent = batteryPercent
        expectation.fulfill()
    }
}

class RemoteControllerTests: XCTestCase {
    var remoteController: RemoteController?
    var remote = DJIRemoteController()

    override func setUp() {
        super.setUp()

        self.remoteController = RemoteController(remote: remote)
    }

    func getSpy(reason: String) -> RemoteControllerSpyDelegate {
        let spyDelegate = RemoteControllerSpyDelegate()
        remoteController!.delegate = spyDelegate

        let expectation = expectationWithDescription(reason)
        spyDelegate.asyncExpectation = expectation

        return spyDelegate
    }

    func testBatteryChange() {
        let spyDelegate = getSpy("Expect that change in battery is passed on")

        var info = DJIRCBatteryInfo()
        info.remainingEnergyInPercent = 30

        remoteController!.remoteController(remote, didUpdateBatteryState: info)

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
}
