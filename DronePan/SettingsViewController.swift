//
//  SettingsViewController.swift
//  DronePan
//
//  Created by Dennis Baldwin on 4/16/16.
//

import UIKit

class SettingsViewController: UIViewController {
    
    
    @IBOutlet weak var photoDelayControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func saveSettings(sender: AnyObject) {
        
        // Save the settings
        print(photoDelayControl.selectedSegmentIndex)
        
        // Dismiss the VC
        self.dismissViewControllerAnimated(true, completion: {})
    }

}
