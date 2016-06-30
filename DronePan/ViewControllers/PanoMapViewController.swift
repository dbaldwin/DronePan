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
import DJISDK

class PanoMapViewController: UIViewController, GMSMapViewDelegate, DJIMissionManagerDelegate {
    
    @IBOutlet weak var map: GMSMapView!
    
    var panoLocation: CLLocationCoordinate2D? = nil
    var missionManager: DJIMissionManager? = nil
    
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
        
        // Setup the mission manager
        self.missionManager = DJIMissionManager.sharedInstance()
        self.missionManager!.delegate = self
        
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
        panoLocation = location
        
        map.animateToLocation(location)
        
        
        let marker = GMSMarker(position: location)
        marker.icon = UIImage(named: "marker")
        marker.title = name
        marker.snippet = "Altitude: 100m"
        marker.map = map
        
        map.selectedMarker = marker
        
    }
    

    // This will trigger the aircraft to fly towards the pano location and begin the sequence
    @IBAction func startPano(sender: AnyObject) {
        
        let wp: DJIWaypoint = DJIWaypoint(coordinate: panoLocation!)
        wp.altitude = 20 // 10 meters
        
        // Setup some mission parameters
        let mission: DJIWaypointMission = DJIWaypointMission()
        mission.autoFlightSpeed = 10 // 10 m/s or 22 mph
        mission.finishedAction = DJIWaypointMissionFinishedAction.NoAction
        mission.headingMode = DJIWaypointMissionHeadingMode.Auto
        mission.flightPathMode = DJIWaypointMissionFlightPathMode.Normal
        
        // Add waypoint to mission
        mission.addWaypoint(wp)
        
        // Upload the waypoint and start the mission
        self.missionManager!.prepareMission(mission, withProgress: nil, withCompletion: {[weak self] (error: NSError?) -> Void in
            if error == nil {
                
                self?.missionManager!.startMissionExecutionWithCompletion({[weak self] (error: NSError?) -> Void in
                    
                    if error != nil {
                        
                        print("Error starting mission: \(error!.localizedDescription)")
                        
                    }
                })
                
            } else {
                
                print("Custom mission failed: \(error!.localizedDescription)")
                
            }
            
        })
        
        
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
