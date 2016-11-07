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
import DJISDK

import CocoaLumberjackSwift

class PanoramaViewController: UIViewController, Analytics {
    var panorama : Panorama?
    
    @IBOutlet weak var startLabel : UILabel!
    @IBOutlet weak var endLabel : UILabel!
    @IBOutlet weak var startFile : UILabel!
    @IBOutlet weak var endFile : UILabel!
    
    @IBOutlet weak var fetchFirstLastButton: UIButton!
    @IBOutlet weak var fetchAllButton: UIButton!
    
    static let dateFormatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PanoramaViewController.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let panorama = panorama {
            if let startTime = panorama.startTime {
                startLabel.text = PanoramaViewController.dateFormatter.stringFromDate(startTime)
            }
            
            if let endTime = panorama.endTime {
                endLabel.text = PanoramaViewController.dateFormatter.stringFromDate(endTime)
            }
            
            if panorama.imageList.count > 0 {
                startFile.text = panorama.imageList.first
                endFile.text = panorama.imageList.last
            }
        }
        
        #if !DEBUG
            fetchFirstLastButton.hidden = true
            fetchAllButton.hidden = true
        #endif
    }

    @IBAction func fetchStartEnd(sender: UIButton) {
    }

    
    @IBAction func fetchAll(sender: UIButton) {
    }
    
    @IBAction func Done(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
}
