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
    var photoCount:Int = 6
    var defaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var photoDelayControl: UISegmentedControl!
    
    @IBOutlet weak var photosPerRowControl: UISegmentedControl!
    
    @IBOutlet weak var angleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initSettings()
    }
    
    func initSettings() {
        
        let photos_per_row = defaults.objectForKey(model)!.valueForKey("photos_per_row")
        
        // Set the selected item
        for i in 0...photosPerRowControl.numberOfSegments-1 {
            
            if(photosPerRowControl.titleForSegmentAtIndex(i) == photos_per_row?.stringValue) {
                photosPerRowControl.selectedSegmentIndex = i
                break
            }
        }
    }
    
    @IBAction func photosPerRowChanged(sender: AnyObject) {
        
        photoCount = Int(photosPerRowControl.titleForSegmentAtIndex(sender.selectedSegmentIndex)!)!
        
        angleLabel.text = "Angle: " + String(360 / photoCount)
        
    }
    
    @IBAction func saveSettings(sender: AnyObject) {
        
        // Dismiss the VC
        self.dismissViewControllerAnimated(true, completion: {})
        
        let settings : [String : Int] = [
            "photos_per_row" : photoCount
            /* add other settings in here */
        ]
        
        defaults.setObject(settings, forKey: model)
        defaults.synchronize()
    }
    
    func getSetting(setting: String) -> Int{
        
        // return defaults.objectForKey(model)!.valueForKey("photos_per_row")
        return 6
        
    }
    
    
}
