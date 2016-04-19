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

@objc class SettingsViewController: UIViewController {
    
    var model:String = ""
    
    @IBOutlet weak var startDelayControl: UISegmentedControl!
    
    @IBOutlet weak var photoDelayControl: UISegmentedControl!
    
    @IBOutlet weak var photosPerRowControl: UISegmentedControl!
    
    @IBOutlet weak var angleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initSettings()
    }
    
    func initSettings() {

        let startDelay = ModelSettings.startDelay(model)
        
        // Set the selected item
        for i in 0..<startDelayControl.numberOfSegments {
            
            if let title = startDelayControl.titleForSegmentAtIndex(i) {
                if let segment = Int(title) {
                    if (segment == startDelay) {
                        startDelayControl.selectedSegmentIndex = Int(i)
                    }
                }
            }
        }
        
        let photosPerRow = ModelSettings.photosPerRow(model)
        
        // Set the selected item
        for i in 0..<photosPerRowControl.numberOfSegments {
            
            if let title = photosPerRowControl.titleForSegmentAtIndex(i) {
                if let segment = Int(title) {
                    if (segment == photosPerRow) {
                        photosPerRowControl.selectedSegmentIndex = Int(i)
                    }
                }
            }
        }
        
        // Ints
        let delayBetweenShots = ModelSettings.delayBetweenShots(model)
        let numberOfRows = ModelSettings.numberOfRows(model)
        
        // Bool
        let includeSkyRow = ModelSettings.skyRow(model)
        
    }
    
    @IBAction func photosPerRowChanged(sender: AnyObject) {
        
        let photoCount = Int(photosPerRowControl.titleForSegmentAtIndex(sender.selectedSegmentIndex)!)!
        
        angleLabel.text = "Angle: " + String(360 / photoCount)
        
    }
    
    @IBAction func saveSettings(sender: AnyObject) {
        
        let startDelay = Int(startDelayControl.titleForSegmentAtIndex(startDelayControl.selectedSegmentIndex)!)!
        
        let photoCount = Int(photosPerRowControl.titleForSegmentAtIndex(photosPerRowControl.selectedSegmentIndex)!)!
        
        let settings : [SettingsKeys : AnyObject] = [
            .StartDelay : startDelay,
            .PhotosPerRow : photoCount
            /* add other settings in here */
        ]
        
        ModelSettings.updateSettings(model, settings: settings)
        
        // Dismiss the VC
        self.dismissViewControllerAnimated(true, completion: {})
    }
}
