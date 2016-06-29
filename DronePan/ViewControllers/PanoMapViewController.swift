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

class PanoMapViewController: UIViewController, GMSMapViewDelegate {
    
    @IBOutlet weak var map: GMSMapView!
    
    var pano: NSManagedObject! {
        didSet (newPano) {
            loadNewPano()
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Initialize the map and controls
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(32, longitude: -96, zoom: 8.0)
        map.camera = camera
        map.myLocationEnabled = true
        map.mapType = kGMSTypeHybrid
        map.settings.myLocationButton = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadNewPano() {
        
        map.clear()
        
        let name = pano.valueForKey("name") as! String
        let latitude = pano.valueForKey("latitude") as! Double
        let longitude = pano.valueForKey("longitude") as! Double
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        map.animateToLocation(location)
        
        
        let marker = GMSMarker(position: location)
        marker.icon = UIImage(named: "marker")
        marker.title = name
        marker.snippet = "Altitude: 100m"
        marker.map = map
        
        map.selectedMarker = marker
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension PanoMapViewController: PanoSelectionDelegate {
    func panoSelected(newPano: NSManagedObject) {
        pano = newPano
    }
}
