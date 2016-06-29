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
import GoogleMaps
import CoreData

protocol PanoSavedDelegate: class {
    func panoSaved()
}

class AddPanoViewController: UIViewController, GMSMapViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var panoName: UITextField!
    
    @IBOutlet weak var panoAltitude: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var map: GMSMapView!
    
    var panos = [NSManagedObject]()
    
    var panoLocation: CLLocationCoordinate2D!
    
    weak var delegate: PanoSavedDelegate?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Initialize the map and controls
        // TODO: change default location and implement find my location
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(32, longitude: -96, zoom: 8.0)
        map.camera = camera
        map.myLocationEnabled = true
        map.mapType = kGMSTypeHybrid
        map.settings.myLocationButton = true
        
        // Set the map and text field delegates
        map.delegate = self
        panoName.delegate = self
        panoAltitude.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
    }

    @IBAction func dismissVC(sender: AnyObject) {
        
        dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBAction func savePano() {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entityForName("Pano", inManagedObjectContext:managedContext)
        let pano = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        pano.setValue(panoName.text, forKey: "name")
        pano.setValue(panoLocation.latitude, forKey: "latitude")
        pano.setValue(panoLocation.longitude, forKey: "longitude")
        pano.setValue(NSDate(), forKey: "datetime")
        
        // Save the pano
        do {
            
            try managedContext.save()
            panos.append(pano)
            
            // Dismiss the view controller after saving
            dismissViewControllerAnimated(true, completion: nil)
            
            // Update the table view
            self.delegate?.panoSaved()
            
        // Error saving pano
        } catch let error as NSError {
            
            print("Could not save \(error), \(error.userInfo)")
            
        }
    
    }
    
    // MARK: UITextFieldDelegate
    
    // Dismiss the keyboard
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        panoName.resignFirstResponder()
        panoAltitude.resignFirstResponder()
        
        return true
        
    }
    
    // Disable the save button until data exists
    func textFieldDidBeginEditing(textField: UITextField) {
    
        saveButton.enabled = false
        
    }
    
    // Enable save button if a pano name exists
    func textFieldDidEndEditing(textField: UITextField) {
        
        saveButton.enabled = !panoName.text!.isEmpty
        
    }
    
    // MARK: GMSMapViewDelegate
    
    // Get the location of the tap so we can add the marker
    func mapView(mapView: GMSMapView, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        
        // Clear the map just in case a previous location was tapped
        map.clear()
        
        // Add a marker at the tapped location
        let marker = GMSMarker(position: coordinate)
        marker.icon = UIImage(named: "marker")
        marker.map = map
        
        // Save the location
        panoLocation = coordinate
        
    }

}
