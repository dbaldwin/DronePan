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
    var photoCount:Int = 6 // Number of photos in a row
    var startDelay:Int = 5 // Number of seconds to delay before pano
    var defaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var startDelayControl: UISegmentedControl!
    
    @IBOutlet weak var photoDelayControl: UISegmentedControl!
    
    @IBOutlet weak var photosPerRowControl: UISegmentedControl!
    
    @IBOutlet weak var angleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initSettings()
    }
    
    func initSettings() {
        
        // Number of seconds to delay before pano starts
        var start_delay = 5
        
        if let saved_start_delay = defaults.objectForKey(model)?.valueForKey("start_delay") as? Int {
            start_delay = saved_start_delay
        }
        
        print(start_delay)
        
        
        // Set the selected item
        for i in 0..<startDelayControl.numberOfSegments {
            
            if let title = startDelayControl.titleForSegmentAtIndex(i) {
                if let segment = Int(title) {
                    if (segment == start_delay) {
                        startDelayControl.selectedSegmentIndex = Int(i)
                    }
                }
            }
        }
        
        // Define the number of photos in a row
        var photos_per_row = 6
        
        if let saved_per_row = defaults.objectForKey(model)?.valueForKey("photos_per_row") as? Int {
            photos_per_row = saved_per_row
        }
        
        // Set the selected item
        for i in 0..<photosPerRowControl.numberOfSegments {
            
            if let title = photosPerRowControl.titleForSegmentAtIndex(i) {
                if let segment = Int(title) {
                    if (segment == photos_per_row) {
                        photosPerRowControl.selectedSegmentIndex = Int(i)
                    }
                }
            }
        }
        
    }
    
    @IBAction func photosPerRowChanged(sender: AnyObject) {
        
        photoCount = Int(photosPerRowControl.titleForSegmentAtIndex(sender.selectedSegmentIndex)!)!
        
        angleLabel.text = "Angle: " + String(360 / photoCount)
        
    }
    
    @IBAction func saveSettings(sender: AnyObject) {
        
        startDelay = Int(startDelayControl.titleForSegmentAtIndex(startDelayControl.selectedSegmentIndex)!)!
        
        photoCount = Int(photosPerRowControl.titleForSegmentAtIndex(photosPerRowControl.selectedSegmentIndex)!)!
        
        let settings : [String : Int] = [
            "start_delay" : startDelay,
            "photos_per_row" : photoCount
            /* add other settings in here */
        ]
        
        defaults.setObject(settings, forKey: model)
        defaults.synchronize()
        
        // Dismiss the VC
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    func getSetting(setting: String) -> Int{
        
        // return defaults.objectForKey(model)!.valueForKey("photos_per_row")
        return 6
        
    }
    
    
}
