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


class MainViewControllerTests: XCTestCase, SystemUtils {
    var viewController: MainViewController!

    // Need to run some different things before building view - so can't be in setup
    func buildView() {
        let storyboard = UIStoryboard(name: "Main",
                bundle: NSBundle.mainBundle())
        viewController = storyboard.instantiateInitialViewController() as! MainViewController

        UIApplication.sharedApplication().keyWindow!.rootViewController = viewController

        let _ = viewController.view
    }

    func testDefaultInit() {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "infoOverride")

        buildView()

        XCTAssertFalse(viewController.rcInFMode, "RC was in F mode at startup")

        [viewController.sequenceLabel, viewController.batteryLabel, viewController.altitudeLabel, viewController.satelliteLabel, viewController.distanceLabel].forEach {
            (label) in
            XCTAssertTrue(label.hidden, "Label \(label.text) was visible at startup")
        }

        XCTAssertEqual(viewController.warningView.alpha, 0, "Warning view was visible at start")

        XCTAssertEqual(viewController.infoView.alpha, 0, "Info view was visible at start")
    }

    func testInfoInit() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "infoOverride")

        buildView()

        viewController.animationDuration = 0.0

        XCTAssertEqual(viewController.infoView.alpha, 1, "Info view was not visible at start")
    }

    func testShowWarning() {
        buildView()

        viewController.showWarning("Test")

        XCTAssertEqual(viewController.currentWarning, "Test", "Warning view had incorrect text after show \(viewController.currentWarning)")
        XCTAssertEqual(viewController.warningView.alpha, 1, "Warning view was not visible after show")
    }

    func testHideWarning() {
        buildView()

        viewController.showWarning("Test")

        viewController.hideWarning()

        XCTAssertEqual(viewController.currentWarning, "", "Warning view had incorrect text after hide \(viewController.currentWarning)")
        // TODO - haven't figured out how to wait for animations in unit tests yet
        // XCTAssertEqual(viewController.warningView.alpha, 0, "Warning view was visible after hide")
    }

    func testShowInfo() {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "infoOverride")

        buildView()

        viewController.showInfo()

        XCTAssertEqual(viewController.infoView.alpha, 1, "Info view was not visible after show")
    }

    func testHideInfo() {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "infoOverride")

        buildView()

        viewController.showInfo()

        viewController.hideInfo()

        // TODO - haven't figured out how to wait for animations in unit tests yet
        // XCTAssertEqual(viewController.infoView.alpha, 0, "Info view was visible after hide")
    }

    func testShowInfoOverride() {
        buildView()

        viewController.showInfo()

        XCTAssertEqual(viewController.infoView.alpha, 1, "Info view was not visible after show with override")
    }

    func testHideInfoOverride() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "infoOverride")

        buildView()

        viewController.showInfo()

        viewController.hideInfo()

        XCTAssertEqual(viewController.infoView.alpha, 1, "Info view was not visible after hide with override")
    }

    func testSetSequence() {
        buildView()
        
        viewController.setSequence(10, count: 20)

        XCTAssertFalse(viewController.sequenceLabel.hidden, "Sequence label was hidden after setting")
        XCTAssertEqual(viewController.sequenceLabel.text, "Photo: 10/20", "Incorrect sequence label seen \(viewController.sequenceLabel.text)")
    }
    
    func testResetSequence() {
        buildView()
        
        viewController.setSequence(10, count: 20)
        viewController.setSequence()
        
        XCTAssertEqual(viewController.sequenceLabel.text, "Photo: -/-", "Incorrect sequence label seen \(viewController.sequenceLabel.text)")
    }

    func testProgress() {
        buildView()
        
        viewController.panoProgress(0.7)
        
        XCTAssertEqual(viewController.currentProgress, 0.7, "Incorrect progress \(viewController.currentProgress)")
    }
    
    func testSetSatellites() {
        buildView()
        
        viewController.setSatellites(5)
        
        XCTAssertFalse(viewController.satelliteLabel.hidden, "Satellite label was hidden after setting")
        XCTAssertEqual(viewController.satelliteLabel.text, "Sats: 5", "Incorrect satellite label seen \(viewController.satelliteLabel.text)")
    }
    
    func testResetSatellites() {
        setMetricUnits(true)
        
        buildView()
        
        viewController.setSatellites(5)
        viewController.setSatellites()
        
        XCTAssertEqual(viewController.satelliteLabel.text, "Sats: -", "Incorrect satellite label seen \(viewController.satelliteLabel.text)")
    }

    func testSetAltitude() {
        setMetricUnits(true)
        
        buildView()

        viewController.setAltitude(20)
        
        XCTAssertFalse(viewController.altitudeLabel.hidden, "Altitude label was hidden after setting")
        XCTAssertEqual(viewController.altitudeLabel.text, "Alt: 20m", "Incorrect altitude label seen \(viewController.altitudeLabel.text)")
    }

    func testResetAltitude() {
        setMetricUnits(true)
        
        buildView()

        viewController.setAltitude(20)
        viewController.setAltitude()
        
        XCTAssertEqual(viewController.altitudeLabel.text, "Alt: -", "Incorrect altitude label seen \(viewController.altitudeLabel.text)")
    }

    func testSetAltitudeFeet() {
        setMetricUnits(false)
        
        buildView()

        viewController.setAltitude(20)

        XCTAssertFalse(viewController.altitudeLabel.hidden, "Altitude label was hidden after setting")
        XCTAssertEqual(viewController.altitudeLabel.text, "Alt: 66'", "Incorrect altitude label seen \(viewController.altitudeLabel.text)")
    }

    func testResetAltitudeFeet() {
        setMetricUnits(false)
        
        buildView()

        viewController.setAltitude(20)
        viewController.setAltitude()
        
        XCTAssertEqual(viewController.altitudeLabel.text, "Alt: -", "Incorrect altitude label seen \(viewController.altitudeLabel.text)")
    }

    func testSetDistance() {
        setMetricUnits(true)
        
        buildView()

        viewController.setDistance(20)
        
        XCTAssertFalse(viewController.distanceLabel.hidden, "Distance label was hidden after setting")
        XCTAssertEqual(viewController.distanceLabel.text, "Dist: 20m", "Incorrect distance label seen \(viewController.distanceLabel.text)")
    }

    func testResetDistance() {
        setMetricUnits(true)
        
        buildView()

        viewController.setDistance(20)
        viewController.setDistance()
        
        XCTAssertEqual(viewController.distanceLabel.text, "Dist: -", "Incorrect distance label seen \(viewController.distanceLabel.text)")

    }

    func testSetDistanceFeet() {
        setMetricUnits(false)
        
        buildView()

        viewController.setDistance(20)
        
        XCTAssertFalse(viewController.distanceLabel.hidden, "Distance label was hidden after setting")
        XCTAssertEqual(viewController.distanceLabel.text, "Dist: 66'", "Incorrect distance label seen \(viewController.distanceLabel.text)")

    }

    func testResetDistanceFeet() {
        setMetricUnits(false)
        
        buildView()

        viewController.setDistance(20)
        viewController.setDistance()
        
        XCTAssertEqual(viewController.distanceLabel.text, "Dist: -", "Incorrect distance label seen \(viewController.distanceLabel.text)")
    }

    func testSetBattery() {
        buildView()

        viewController.batteryControllerPercentUpdated(95)

        XCTAssertFalse(viewController.batteryLabel.hidden, "Battery label hidden after receiving battery percentage")
        XCTAssertEqual(viewController.batteryLabel.text, "Batt: 95%", "Battery label incorrect after receiving battery percentage \(viewController.batteryLabel.text)")
    }

    func testResetBattery() {
        buildView()
        
        viewController.setBattery(95)
        viewController.setBattery()
        
        XCTAssertEqual(viewController.batteryLabel.text, "Batt: -", "Battery label incorrect after reset \(viewController.batteryLabel.text)")
    }


    func testSetLowBattery() {
        buildView()

        viewController.batteryControllerPercentUpdated(5)

        XCTAssertFalse(viewController.batteryLabel.hidden, "Battery label hidden after receiving battery percentage")
        XCTAssertEqual(viewController.batteryLabel.text, "Batt: 5%", "Battery label incorrect after receiving battery percentage \(viewController.batteryLabel.text)")

        XCTAssertEqual(viewController.warningView.alpha, 1, "Warning not visible on low battery") 
        XCTAssertEqual(viewController.currentWarning, "Battery Low: 5%", "Warning not correct on low battery \(viewController.currentWarning)")
    }
}
