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

import UIKit

import CocoaLumberjackSwift

class SettingsViewController: UIViewController {

    var model: String = ""
    var type: ProductType = .Aircraft

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var skyRowControl: UISegmentedControl!
    @IBOutlet weak var unitsControl: UISegmentedControl!

    @IBOutlet weak var angleLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!

    @IBOutlet weak var startDelayDescription: UILabel!
    @IBOutlet weak var numberOfPhotosPerRowDescription: UILabel!
    @IBOutlet weak var numberOfRowsDescription: UILabel!
    @IBOutlet weak var skyRowDescription: UILabel!

    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var saveButton: UIButton!

    @IBOutlet weak var delayLabel: UILabel!
    @IBOutlet weak var delaySlider: UISlider!

    @IBOutlet weak var photosPerRowLabel: UILabel!
    @IBOutlet weak var photosPerRowSlider: UISlider!

    @IBOutlet weak var rowCountLabel: UILabel!
    @IBOutlet weak var rowCountSlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()

        initSettings()

        if let version = ControllerUtils.buildVersion() {
            self.versionLabel.hidden = false
            self.versionLabel.text = "Version \(version)"

            DDLogDebug("Settings VC showing version \(version)")
        } else {
            self.versionLabel.hidden = true

            DDLogWarn("Settings VC unknown version")
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        DDLogInfo("Showing settings window")
        trackScreenView("SettingsViewController")
    }

    override func viewDidAppear(animated: Bool) {
        DDLogInfo("Settings VC Showing settings view")

        self.scrollView.flashScrollIndicators()
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    private func initSegment(control: UISegmentedControl, setting: Int) {
        for i in 0 ..< control.numberOfSegments {

            if let title = control.titleForSegmentAtIndex(i) {
                if let segment = Int(title) {
                    if (segment == setting) {
                        control.selectedSegmentIndex = Int(i)
                    }
                }
            }
        }
    }

    private func startDelay(setting: Int, updateSlider: Bool = false) {
        delayLabel.text = "Start Delay (seconds): \(setting)"

        if updateSlider {
            delaySlider.minimumValue = 5
            delaySlider.maximumValue = 30
            delaySlider.value = Float(setting)
        }
    }

    @IBAction func delaySliderChanged(sender: UISlider) {
        let step: Float = 5.0

        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue

        startDelay(Int(roundedValue))
    }

    private func photosPerRow(setting: Int, updateSlider: Bool = false) {
        photosPerRowLabel.text = "Number of photos per row: \(setting)"

        if updateSlider {
            photosPerRowSlider.minimumValue = 6
            photosPerRowSlider.maximumValue = 20
            photosPerRowSlider.value = Float(setting)
        }
    }

    @IBAction func photosPerRowSliderChanged(sender: UISlider) {
        let step: Float = 1.0

        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue

        photosPerRow(Int(roundedValue))

        updateCounts()
    }


    private func rowCount(setting: Int, updateSlider: Bool = false) {
        rowCountLabel.text = "Number of rows: \(setting)"

        if updateSlider {
            rowCountSlider.minimumValue = 3
            rowCountSlider.maximumValue = 10
            rowCountSlider.value = Float(setting)
        }
    }

    @IBAction func rowCountChanged(sender: UISlider) {
        let step: Float = 1.0

        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue

        rowCount(Int(roundedValue))

        updateCounts()
    }

    func initSettings() {
        if (self.model == "") {
            titleLabel.attributedText = NSAttributedString(string: "Disconnected", attributes: [
                    NSFontAttributeName: UIFont.boldSystemFontOfSize(20)
            ])

            for control in [delaySlider, photosPerRowSlider, rowCountSlider] {
                control.enabled = false
            }

            for control in [skyRowControl] {
                control.enabled = false
                control.selectedSegmentIndex = UISegmentedControlNoSegment
            }

            for label in [startDelayDescription, numberOfPhotosPerRowDescription, numberOfRowsDescription, skyRowDescription] {
                label.text = "Disconnected"
            }

            setAngleLabel(0)
            countLabel.text = "--"

            saveButton.enabled = false

            return
        }


        titleLabel.attributedText = NSAttributedString(string: "\(model) Settings", attributes: [
                NSFontAttributeName: UIFont.boldSystemFontOfSize(20)
        ])

        if (type == .Handheld) {

            startDelayDescription.text = "Specify a delay before starting your pano. The pano process will delay this amount of time after clicking the start button."

            delaySlider.enabled = true
            startDelay(ModelSettings.startDelay(model), updateSlider: true)

            skyRowDescription.text = "Handheld always gets this extra row. Number of rows will be the number selected above +1."
            skyRowControl.enabled = false
            skyRowControl.selectedSegmentIndex = 0
        } else {
            delaySlider.enabled = false
            startDelay(0, updateSlider: true)

            startDelayDescription.text = "Only applicable for handheld"

            if (ControllerUtils.isPhantom(model)) {
                skyRowControl.enabled = false
                skyRowDescription.text = "Phantom models do not support sky row"
                skyRowControl.selectedSegmentIndex = 1
            } else {
                skyRowControl.enabled = true
                skyRowDescription.text = "If set, DronePan will shoot a \"sky row\" with the gimbal at +30˚. Then it will take a row of shots at 0˚, -30˚ and -60˚ and one nadir. Selecting \"No\" will skip the sky row."
                let skyRow = ModelSettings.skyRow(model)

                if (skyRow) {
                    skyRowControl.selectedSegmentIndex = 0
                } else {
                    skyRowControl.selectedSegmentIndex = 1
                }
            }
        }

        photosPerRow(ModelSettings.photosPerRow(model), updateSlider: true)

        rowCount(ModelSettings.numberOfRows(model), updateSlider: true)

        updateCounts()

        unitsControl.selectedSegmentIndex = ControllerUtils.metricUnits() ? 0 : 1
    }

    private func setAngleLabel(angle: Float) {
        let roundedString = String(format: "%.2f", angle)

        let angleString = NSMutableAttributedString(string: "\(roundedString)", attributes: [
                NSFontAttributeName: UIFont.boldSystemFontOfSize(14)
        ])


        angleString.appendAttributedString(NSAttributedString(string: "˚", attributes: [
                NSFontAttributeName: UIFont.systemFontOfSize(14)
        ]))

        angleLabel.attributedText = angleString
    }

    private func updateCounts() {
        if var numberOfRows = selectedNumberOfRows() {
            if (isSkyRow()) {
                numberOfRows += 1
            }

            if let photosPerRow = selectedPhotosPerRow() {
                self.setAngleLabel(360.0 / Float(photosPerRow))
                self.countLabel.text = "\((numberOfRows * photosPerRow) + 1)"
            } else {
                self.setAngleLabel(0)
                self.countLabel.text = "--"
            }
        }
    }

    private func isSkyRow() -> Bool {
        return skyRowControl.selectedSegmentIndex == 0
    }

    private func selectedValue(control: UISegmentedControl) -> Int? {
        if (control.selectedSegmentIndex == UISegmentedControlNoSegment) {
            return nil
        }

        if let title = control.titleForSegmentAtIndex(control.selectedSegmentIndex) {
            return Int(title)
        } else {
            return nil
        }
    }

    private func selectedPhotosPerRow() -> Int? {
        return Int(photosPerRowSlider.value)
    }

    private func selectedNumberOfRows() -> Int? {
        return Int(rowCountSlider.value)
    }

    private func selectedStartDelay() -> Int? {
        return Int(delaySlider.value)
    }

    @IBAction func numberOfRowsChanged(sender: AnyObject) {
        updateCounts()
    }

    @IBAction func skyRowChanged(sender: AnyObject) {
        updateCounts()
    }

    @IBAction func saveSettings(sender: AnyObject) {
        var settings: [SettingsKeys:AnyObject] = [
                .SkyRow: isSkyRow()
        ]

        if let startDelay = selectedStartDelay() {
            settings[.StartDelay] = startDelay
        }

        if let photoCount = selectedPhotosPerRow() {
            settings[.PhotosPerRow] = photoCount
        }

        if let rowCount = selectedNumberOfRows() {
            settings[.NumberOfRows] = rowCount
        }

        ModelSettings.updateSettings(model, settings: settings)

        ControllerUtils.setMetricUnits(unitsControl.selectedSegmentIndex == 0)

        // Dismiss the VC
        self.dismissViewControllerAnimated(true, completion: {})
    }

    @IBAction func cancelSettings(sender: AnyObject) {
        // Dismiss the VC
        self.dismissViewControllerAnimated(true, completion: {})
    }

    @IBAction func copyLogToClipboard(sender: UIButton) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if (appDelegate.copyLogToClipboard()) {
                showAlert("Log copied", body: "Log copied to clipboard")
            } else {
                showAlert("Failed", body: "Failed to copy log to clipboard")
            }
        }
    }

    private func showAlert(title: String, body: String) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .Alert)

        let ok = UIAlertAction(title: "OK", style: .Default, handler: nil)

        alert.addAction(ok)

        self.presentViewController(alert, animated: true, completion: nil)
    }
}
