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

    func testInitWithoutModel() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("")

        XCTAssertEqual(vc.titleLabel.text, "Disconnected", "Incorrect model \(vc.titleLabel.text)")

        [vc.delaySlider, vc.photosPerRowSlider, vc.rowCountSlider, vc.skyRowControl, vc.saveButton].forEach {
            (control) in
            XCTAssertFalse(control.enabled, "Control \(control) was enabled")
        }

        XCTAssertEqual(vc.skyRowControl.selectedSegmentIndex, UISegmentedControlNoSegment, "Sky row had a selected segment")

        [vc.startDelayDescription, vc.numberOfPhotosPerRowDescription, vc.numberOfRowsDescription, vc.skyRowDescription].forEach {
            (control) in
            XCTAssertEqual(control.text, "Disconnected", "Control \(control) was connected")
        }

        XCTAssertEqual(vc.angleLabel.attributedText!.string, "0.00˚", "Incorrect angle \(vc.angleLabel.attributedText?.string)")

        XCTAssertEqual(vc.countLabel.text, "--", "Incorrect count label \(vc.countLabel.text)")
    }

    func testInitWithModelAircraft() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("Test", productType: .Aircraft)

        XCTAssertEqual(vc.titleLabel.text, "Test Settings", "Incorrect model \(vc.titleLabel.text)")

        [vc.delaySlider].forEach {
            (control) in
            XCTAssertFalse(control.enabled, "Control \(control) was enabled")
        }

        [vc.photosPerRowSlider, vc.rowCountSlider, vc.skyRowControl, vc.saveButton].forEach {
            (control) in
            XCTAssertTrue(control.enabled, "Control \(control) was not enabled")
        }

        XCTAssertEqual(vc.startDelayDescription.text, "Only applicable for handheld", "Incorrect start delay description \(vc.startDelayDescription.text)")

        XCTAssertEqual(vc.skyRowControl.selectedSegmentIndex, 0, "Sky row didn't have correct default segment")

        XCTAssertEqual(vc.photosPerRowSlider.value, 6, "Incorrect photos per row \(vc.photosPerRowSlider.value)")

        XCTAssertEqual(vc.rowCountSlider.value, 3, "Incorrect row count \(vc.rowCountSlider.value)")

        XCTAssertEqual(vc.angleLabel.attributedText!.string, "60.00˚", "Incorrect angle \(vc.angleLabel.attributedText?.string)")

        XCTAssertEqual(vc.countLabel.text, "25", "Incorrect count label \(vc.countLabel.text)")
    }

    func testInitWithModelAircraftNoSkyRow() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        ModelSettings.updateSettings("Test", settings: [.SkyRow: false])

        buildView("Test", productType: .Aircraft)

        XCTAssertEqual(vc.skyRowControl.selectedSegmentIndex, 1, "Sky row didn't have correct segment")
    }

    func testInitWithModelHandheld() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("Test", productType: .Handheld)

        XCTAssertEqual(vc.titleLabel.text, "Test Settings", "Incorrect model \(vc.titleLabel.text)")

        [vc.skyRowControl].forEach {
            (control) in
            XCTAssertFalse(control.enabled, "Control \(control) was enabled")
        }

        [vc.delaySlider, vc.photosPerRowSlider, vc.rowCountSlider, vc.saveButton].forEach {
            (control) in
            XCTAssertTrue(control.enabled, "Control \(control) was not enabled")
        }

        XCTAssertEqual(vc.delaySlider.value, 5, "Incorrect start delay \(vc.delaySlider.value)")

        XCTAssertEqual(vc.skyRowControl.selectedSegmentIndex, 0, "Sky row didn't have correct default segment")

        XCTAssertEqual(vc.skyRowDescription.text, "Handheld always gets this extra row. Number of rows will be the number selected above +1.", "Incorrect sky row description \(vc.skyRowDescription.text)")

        XCTAssertEqual(vc.photosPerRowSlider.value, 6, "Incorrect photos per row \(vc.photosPerRowSlider.value)")

        XCTAssertEqual(vc.rowCountSlider.value, 3, "Incorrect row count \(vc.rowCountSlider.value)")

        XCTAssertEqual(vc.angleLabel.attributedText!.string, "60.00˚", "Incorrect angle \(vc.angleLabel.attributedText?.string)")

        XCTAssertEqual(vc.countLabel.text, "25", "Incorrect count label \(vc.countLabel.text)")
    }

    func testInitWithModelPhantom() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView(DJIAircraftModelNamePhantom4, productType: .Aircraft)

        XCTAssertEqual(vc.titleLabel.text, "\(DJIAircraftModelNamePhantom4) Settings", "Incorrect model \(vc.titleLabel.text)")

        [vc.delaySlider, vc.skyRowControl].forEach {
            (control) in
            XCTAssertFalse(control.enabled, "Control \(control) was enabled")
        }

        [vc.photosPerRowSlider, vc.rowCountSlider, vc.saveButton].forEach {
            (control) in
            XCTAssertTrue(control.enabled, "Control \(control) was not enabled")
        }

        XCTAssertEqual(vc.startDelayDescription.text, "Only applicable for handheld", "Incorrect start delay description \(vc.startDelayDescription.text)")

        XCTAssertEqual(vc.skyRowControl.selectedSegmentIndex, 1, "Sky row didn't have correct default segment")
        XCTAssertEqual(vc.skyRowDescription.text, "Phantom models do not support sky row", "Incorrect sky row description \(vc.skyRowDescription.text)")

        XCTAssertEqual(vc.photosPerRowSlider.value, 6, "Incorrect photos per row \(vc.photosPerRowSlider.value)")

        XCTAssertEqual(vc.rowCountSlider.value, 3, "Incorrect row count \(vc.rowCountSlider.value)")

        XCTAssertEqual(vc.angleLabel.attributedText!.string, "60.00˚", "Incorrect angle \(vc.angleLabel.attributedText?.string)")

        XCTAssertEqual(vc.countLabel.text, "19", "Incorrect count label \(vc.countLabel.text)")
    }

    func testInitDefaultUnits() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("Test")

        XCTAssertEqual(vc.unitsControl.selectedSegmentIndex, 0, "Incorrect default units")
    }

    func testInitFeetUnits() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        ControllerUtils.setMetricUnits(false)

        buildView("Test")

        XCTAssertEqual(vc.unitsControl.selectedSegmentIndex, 1, "Incorrect default units")
    }

    func testVersionFormat() {
        buildView("Test")

        let versionString = vc.versionLabel.text

        XCTAssertTrue(versionString?.rangeOfString("\\d\\d?.\\d\\d?.\\d\\d?\\(\\d\\d?\\d?\\)", options: .RegularExpressionSearch) != nil, "Version string didn't match format \(versionString)")
    }

    func testDelayChange() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("Test", productType: .Handheld)

        vc.delaySlider.value = 15.4

        vc.delaySliderChanged(vc.delaySlider)

        XCTAssertEqual(vc.delaySlider.value, 15, "Incorrect value")
    }

    func testPhotoPerRowChange() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("Test", productType: .Handheld)

        vc.photosPerRowSlider.value = 15.4

        vc.photosPerRowSliderChanged(vc.photosPerRowSlider)

        XCTAssertEqual(vc.photosPerRowSlider.value, 15, "Incorrect value")
    }

    func testRowCountChange() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("Test", productType: .Handheld)

        vc.rowCountSlider.value = 5.4

        vc.rowCountChanged(vc.rowCountSlider)

        XCTAssertEqual(vc.rowCountSlider.value, 5, "Incorrect value")
    }

    func testSaveHandheld() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("Test", productType: .Handheld)

        vc.delaySlider.value = 10

        vc.photosPerRowSlider.value = 10

        vc.rowCountSlider.value = 8

        vc.unitsControl.selectedSegmentIndex = 0

        vc.saveSettings(self)

        XCTAssertEqual(ModelSettings.startDelay("Test"), 10, "Incorrect start delay")
        XCTAssertEqual(ModelSettings.photosPerRow("Test"), 10, "Incorrect photos per row")
        XCTAssertEqual(ModelSettings.numberOfRows("Test"), 8, "Incorrect row count")
        XCTAssertTrue(ModelSettings.skyRow("Test"), "Incorrect skyRow")
        XCTAssertTrue(ControllerUtils.metricUnits(), "Non-metric units")
    }

    func testSaveAircraft() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)

        buildView("Test", productType: .Aircraft)

        vc.photosPerRowSlider.value = 10

        vc.rowCountSlider.value = 8

        vc.skyRowControl.selectedSegmentIndex = 1

        vc.unitsControl.selectedSegmentIndex = 1

        vc.saveSettings(self)

        XCTAssertEqual(ModelSettings.photosPerRow("Test"), 10, "Incorrect photos per row")
        XCTAssertEqual(ModelSettings.numberOfRows("Test"), 8, "Incorrect row count")
        XCTAssertFalse(ModelSettings.skyRow("Test"), "Incorrect skyRow")
        XCTAssertFalse(ControllerUtils.metricUnits(), "Metric units")
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
