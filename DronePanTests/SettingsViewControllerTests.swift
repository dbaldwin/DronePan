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


class SettingsViewControllerTests: XCTestCase {
    var vc: SettingsViewController!

    // Need to run some different things before building view - so can't be in setup
    func buildView(model: String, productType: ProductType = .Aircraft) {
        let storyboard = UIStoryboard(name: "Main",
                bundle: NSBundle.mainBundle())

        vc = storyboard.instantiateViewControllerWithIdentifier("Settings") as! SettingsViewController

        vc.model = model
        vc.type = productType

        UIApplication.sharedApplication().keyWindow!.rootViewController = vc

        let _ = vc.view
    }

    // Tests default values
    func testInitWithoutModel() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("")

        XCTAssertEqual(vc.titleLabel.text, "Disconnected", "Incorrect model \(vc.titleLabel.text)")

        XCTAssertEqual(vc.yawAngleLabel.attributedText!.string, "60.00˚", "Incorrect angle \(vc.yawAngleLabel.attributedText?.string)")

        XCTAssertEqual(vc.pitchAngleLabel.attributedText!.string, "30.00˚", "Incorrect angle \(vc.pitchAngleLabel.attributedText?.string)")

        if let colour = vc.pitchAngleLabel.attributedText?.attribute(NSForegroundColorAttributeName, atIndex: 0, effectiveRange: nil) as? UIColor {
            XCTAssertEqual(colour, UIColor.whiteColor())
        } else {
            XCTFail("Couldn't get colour")
        }

        XCTAssertEqual(vc.countLabel.text, "19", "Incorrect count label \(vc.countLabel.text)")
        
        XCTAssertEqual(vc.tableView.numberOfSections, 1, "Incorrect number of sections")

        XCTAssertEqual(vc.tableView.numberOfRowsInSection(0), 6, "Incorrect number of rows")
        
        let perRowCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(perRowCell.titleLabel.text, "Number of photos per row: 6", "Incorrect number of photos per row title")
        XCTAssertEqual(perRowCell.slider.value, 6, "Incorrect number of photos per row")

        let rowsCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(rowsCell.titleLabel.text, "Number of rows: 3", "Incorrect number of rows title")
        XCTAssertEqual(rowsCell.slider.value, 3, "Incorrect number of rows")

        let nadirCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(nadirCell.titleLabel.text, "Number of nadir shots: 1", "Incorrect nadir title")
        XCTAssertEqual(nadirCell.slider.value, 1, "Incorrect number of nadir photos")

        let unitsCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! SegmentTableViewCell
        
        XCTAssertEqual(unitsCell.titleLabel.text, "Units:", "Incorrect units title")
        XCTAssertEqual(unitsCell.segmentControl.selectedSegmentIndex, 0, "Incorrect units")
    }

    func testInitWithModelAircraft() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        buildView("Test", productType: .Aircraft)
        
        XCTAssertEqual(vc.titleLabel.text, "Test Settings", "Incorrect model \(vc.titleLabel.text)")
        
        XCTAssertEqual(vc.yawAngleLabel.attributedText!.string, "60.00˚", "Incorrect angle \(vc.yawAngleLabel.attributedText?.string)")
        
        XCTAssertEqual(vc.pitchAngleLabel.attributedText!.string, "30.00˚", "Incorrect angle \(vc.pitchAngleLabel.attributedText?.string)")
        
        XCTAssertEqual(vc.countLabel.text, "19", "Incorrect count label \(vc.countLabel.text)")
        
        XCTAssertEqual(vc.tableView.numberOfSections, 1, "Incorrect number of sections")
        
        XCTAssertEqual(vc.tableView.numberOfRowsInSection(0), 6, "Incorrect number of rows")
        
        let perRowCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(perRowCell.titleLabel.text, "Number of photos per row: 6", "Incorrect number of photos per row title")
        XCTAssertEqual(perRowCell.slider.value, 6, "Incorrect number of photos per row")
        XCTAssertEqual(perRowCell.slider.minimumValue, 6, "Incorrect min photos per row")
        XCTAssertEqual(perRowCell.slider.maximumValue, 20, "Incorrect max photos per row")
        
        let rowsCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(rowsCell.titleLabel.text, "Number of rows: 3", "Incorrect number of rows title")
        XCTAssertEqual(rowsCell.slider.value, 3, "Incorrect number of rows")
        XCTAssertEqual(rowsCell.slider.minimumValue, 3, "Incorrect min rows")
        XCTAssertEqual(rowsCell.slider.maximumValue, 10, "Incorrect max rows")
        
        let nadirCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(nadirCell.titleLabel.text, "Number of nadir shots: 1", "Incorrect nadir title")
        XCTAssertEqual(nadirCell.slider.value, 1, "Incorrect number of nadir photos")
        XCTAssertEqual(nadirCell.slider.minimumValue, 1, "Incorrect min nadir")
        XCTAssertEqual(nadirCell.slider.maximumValue, 4, "Incorrect max nadir")
        
        let unitsCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! SegmentTableViewCell
        
        XCTAssertEqual(unitsCell.titleLabel.text, "Units:", "Incorrect units title")
        XCTAssertEqual(unitsCell.segmentControl.selectedSegmentIndex, 0, "Incorrect units")
    }
    
    func testInitWithModelAircraftMaxPitch() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        ModelSettings.updateSettings("Test", settings: [
            .MaxPitch: 30,
            .MaxPitchEnabled: true
        ])
        
        buildView("Test", productType: .Aircraft)
        
        XCTAssertEqual(vc.titleLabel.text, "Test Settings", "Incorrect model \(vc.titleLabel.text)")
        
        XCTAssertEqual(vc.yawAngleLabel.attributedText!.string, "60.00˚", "Incorrect angle \(vc.yawAngleLabel.attributedText?.string)")
        
        XCTAssertEqual(vc.pitchAngleLabel.attributedText!.string, "30.00˚", "Incorrect angle \(vc.pitchAngleLabel.attributedText?.string)")
        
        XCTAssertEqual(vc.countLabel.text, "25", "Incorrect count label \(vc.countLabel.text)")
        
        XCTAssertEqual(vc.tableView.numberOfSections, 1, "Incorrect number of sections")
        
        XCTAssertEqual(vc.tableView.numberOfRowsInSection(0), 7, "Incorrect number of rows")
        
        let perRowCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(perRowCell.titleLabel.text, "Number of photos per row: 6", "Incorrect number of photos per row title")
        XCTAssertEqual(perRowCell.slider.value, 6, "Incorrect number of photos per row")
        XCTAssertEqual(perRowCell.slider.minimumValue, 6, "Incorrect min photos per row")
        XCTAssertEqual(perRowCell.slider.maximumValue, 20, "Incorrect max photos per row")
        
        let rowsCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(rowsCell.titleLabel.text, "Number of rows: 4", "Incorrect number of rows title")
        XCTAssertEqual(rowsCell.slider.value, 4, "Incorrect number of rows")
        XCTAssertEqual(rowsCell.slider.minimumValue, 3, "Incorrect min rows")
        XCTAssertEqual(rowsCell.slider.maximumValue, 10, "Incorrect max rows")
        
        let nadirCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(nadirCell.titleLabel.text, "Number of nadir shots: 1", "Incorrect nadir title")
        XCTAssertEqual(nadirCell.slider.value, 1, "Incorrect number of nadir photos")
        XCTAssertEqual(nadirCell.slider.minimumValue, 1, "Incorrect min nadir")
        XCTAssertEqual(nadirCell.slider.maximumValue, 4, "Incorrect max nadir")
        
        let pitchCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! SegmentTableViewCell
        
        XCTAssertEqual(pitchCell.titleLabel.text, "Maximum Upward Pitch:", "Incorrect max pitch title")
        XCTAssertEqual(pitchCell.segmentControl.selectedSegmentIndex, 0, "Incorrect pitch set")
        XCTAssertEqual(pitchCell.segmentControl.titleForSegmentAtIndex(0), "30˚", "Incorrect max pitch")

        let unitsCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 4, inSection: 0)) as! SegmentTableViewCell
        
        XCTAssertEqual(unitsCell.titleLabel.text, "Units:", "Incorrect units title")
        XCTAssertEqual(unitsCell.segmentControl.selectedSegmentIndex, 0, "Incorrect units")
    }

    func testInitWithModelAircraftMaxPitchBadPitchAngle() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        ModelSettings.updateSettings("Test", settings: [
            .MaxPitch: 30,
            .MaxPitchEnabled: true
            ])

        ModelSettings.updateSettings("Test", settings: [
            .NumberOfRows: 3
            ])
        
        buildView("Test", productType: .Aircraft)
        
        XCTAssertEqual(vc.pitchAngleLabel.attributedText!.string, "40.00˚", "Incorrect pitch angle")
        
        if let colour = vc.pitchAngleLabel.attributedText?.attribute(NSForegroundColorAttributeName, atIndex: 0, effectiveRange: nil) as? UIColor {
            XCTAssertEqual(colour, UIColor(red: 1, green: 0.5, blue: 0.5, alpha: 1))
        } else {
            XCTFail("Couldn't get colour")
        }
    }
    
    func testInitWithModelHandheld() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        buildView("Test", productType: .Handheld)
        
        XCTAssertEqual(vc.titleLabel.text, "Test Settings", "Incorrect model \(vc.titleLabel.text)")
        
        XCTAssertEqual(vc.yawAngleLabel.attributedText!.string, "60.00˚", "Incorrect angle \(vc.yawAngleLabel.attributedText?.string)")
        
        XCTAssertEqual(vc.pitchAngleLabel.attributedText!.string, "30.00˚", "Incorrect angle \(vc.pitchAngleLabel.attributedText?.string)")
        
        XCTAssertEqual(vc.countLabel.text, "19", "Incorrect count label \(vc.countLabel.text)")
        
        XCTAssertEqual(vc.tableView.numberOfSections, 1, "Incorrect number of sections")
        
        XCTAssertEqual(vc.tableView.numberOfRowsInSection(0), 7, "Incorrect number of rows")

        let delayCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(delayCell.titleLabel.text, "Start Delay (seconds): 5", "Incorrect start delay title")
        XCTAssertEqual(delayCell.slider.value, 5, "Incorrect start delay")
        XCTAssertEqual(delayCell.slider.minimumValue, 0, "Incorrect min delay")
        XCTAssertEqual(delayCell.slider.maximumValue, 30, "Incorrect max delay")

        let perRowCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(perRowCell.titleLabel.text, "Number of photos per row: 6", "Incorrect number of photos per row title")
        XCTAssertEqual(perRowCell.slider.value, 6, "Incorrect number of photos per row")
        
        let rowsCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(rowsCell.titleLabel.text, "Number of rows: 3", "Incorrect number of rows title")
        XCTAssertEqual(rowsCell.slider.value, 3, "Incorrect number of rows")
        
        let nadirCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! SliderTableViewCell
        
        XCTAssertEqual(nadirCell.titleLabel.text, "Number of zenith shots: 1", "Incorrect nadir title")
        XCTAssertEqual(nadirCell.slider.value, 1, "Incorrect number of nadir photos")
        
        let unitsCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 4, inSection: 0)) as! SegmentTableViewCell
        
        XCTAssertEqual(unitsCell.titleLabel.text, "Units:", "Incorrect units title")
        XCTAssertEqual(unitsCell.segmentControl.selectedSegmentIndex, 0, "Incorrect units")
    }
    
    func testUpdatePerRowCellWithModelAircraft() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        buildView("Test", productType: .Aircraft)
        
        XCTAssertEqual(vc.yawAngleLabel.attributedText!.string, "60.00˚", "Incorrect yaw angle")
        
        XCTAssertEqual(vc.countLabel.text, "19", "Incorrect count label")
        
        let perRowCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! SliderTableViewCell

        perRowCell.slider.value = 7.6
        perRowCell.sliderValueChanged(perRowCell.slider)
        
        XCTAssertEqual(perRowCell.titleLabel.text, "Number of photos per row: 8", "Incorrect number of photos per row title")
        XCTAssertEqual(perRowCell.slider.value, 8, "Incorrect number of photos per row")

        XCTAssertEqual(vc.yawAngleLabel.attributedText!.string, "45.00˚", "Incorrect yaw angle after update")
        
        XCTAssertEqual(vc.countLabel.text, "25", "Incorrect count label after update")
    }

    func testUpdateRowCountCellWithModelAircraft() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        buildView("Test", productType: .Aircraft)
        
        XCTAssertEqual(vc.pitchAngleLabel.attributedText!.string, "30.00˚", "Incorrect pitch angle")
        
        XCTAssertEqual(vc.countLabel.text, "19", "Incorrect count label")
        
        let rowsCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SliderTableViewCell

        rowsCell.slider.value = 4.6
        rowsCell.sliderValueChanged(rowsCell.slider)
        
        XCTAssertEqual(rowsCell.titleLabel.text, "Number of rows: 5", "Incorrect number of rows title")
        XCTAssertEqual(rowsCell.slider.value, 5, "Incorrect number of rows")
        
        XCTAssertEqual(vc.pitchAngleLabel.attributedText!.string, "18.00˚", "Incorrect pitch angle after update")
        
        XCTAssertEqual(vc.countLabel.text, "31", "Incorrect count label after update")
    }
    
    func testUpdateNadirCountCellWithModelAircraft() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        buildView("Test", productType: .Aircraft)
        
        XCTAssertEqual(vc.countLabel.text, "19", "Incorrect count label")
        
        let nadirCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! SliderTableViewCell
        
        nadirCell.slider.value = 2.7
        nadirCell.sliderValueChanged(nadirCell.slider)
        
        XCTAssertEqual(nadirCell.titleLabel.text, "Number of nadir shots: 3", "Incorrect number of nadir shots title")
        XCTAssertEqual(nadirCell.slider.value, 3, "Incorrect number of nadir shots")
        
        XCTAssertEqual(vc.countLabel.text, "21", "Incorrect count label after update")
    }
    
    func testUpdateUnitsCellWithModelAircraft() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        buildView("Test", productType: .Aircraft)
        
        let unitsCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! SegmentTableViewCell
        
        unitsCell.segmentControl.selectedSegmentIndex = 1
        unitsCell.segmentValueChanged(unitsCell.segmentControl)
        
        XCTAssertFalse(vc.metricSelected, "Incorrect units after update")
    }

    func testUpdateMaxPitchCellWithModelAircraft() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        
        ModelSettings.updateSettings("Test", settings: [
            .MaxPitch: 30,
            .MaxPitchEnabled: true
            ])
        
        buildView("Test", productType: .Aircraft)
        
        let pitchCell = vc.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! SegmentTableViewCell
        
        pitchCell.segmentControl.selectedSegmentIndex = 1
        pitchCell.segmentValueChanged(pitchCell.segmentControl)
        
        XCTAssertFalse(vc.maxPitchEnabled, "Incorrect max pitch enabled after update")
    }
    
    func testVersionFormat() {
        buildView("Test")

        let versionString = vc.versionLabel.text

        XCTAssertTrue(versionString?.rangeOfString("\\d\\d?\\.\\d\\d?(\\.\\d\\d?)?\\(\\d\\d?\\)", options: .RegularExpressionSearch) != nil, "Version string didn't match format \(versionString)")
    }

    func testCopyLog() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("Test", productType: .Aircraft)

        vc.copyLogToClipboard(UIButton())

        guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType("public.text") else {
            XCTFail("Couldn't copy clipboard")

            return
        }

        let dataString = String(data: data, encoding: NSUTF8StringEncoding)

        XCTAssertTrue(dataString?.rangeOfString("Running version") != nil, "Didn't find expected log")
    }
}
