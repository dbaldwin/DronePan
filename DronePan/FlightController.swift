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

import Foundation

import DJISDK
import CocoaLumberjackSwift

@objc protocol FlightControllerDelegate {
    func flightControllerUpdateHeading(compassHeading: Double)
    func flightControllerUpdateAltitude(altitude: Float)
    func flightControllerUpdateSatelliteCount(satelliteCount: Int)
    func flightControllerUpdateDistance(distance: CLLocationDistance)
    
    func flightControllerUnableToSetControlMode()
    func flightControllerSetControlMode()
}

@objc class FlightController: NSObject, DJIFlightControllerDelegate {
    let fc : DJIFlightController
    
    var delegate : FlightControllerDelegate?
    
    init(fc: DJIFlightController) {
        DDLogInfo("Flight Controller init")
        
        self.fc = fc
        
        super.init()
        
        fc.delegate = self
    }

    func setControlModes() {
        self.fc.enableVirtualStickControlModeWithCompletion { (error) in
            if let error = error {
                DDLogWarn("Unable to set virtual stick mode \(error)")
                self.delegate?.flightControllerUnableToSetControlMode()
            } else {
                self.fc.yawControlMode = .AngularVelocity
                self.fc.rollPitchControlMode = .Velocity
                self.fc.verticalControlMode = .Velocity
                self.delegate?.flightControllerSetControlMode()
            }
        }
    }
    
    func yaw(speed: Double) {
        if (self.fc.isVirtualStickControlModeAvailable()) {
            var ctrlData = DJIVirtualStickFlightControlData()
            ctrlData.pitch = 0
            ctrlData.roll = 0
            ctrlData.verticalThrottle = 0
            ctrlData.yaw = Float(speed)

            self.fc.sendVirtualStickFlightControlData(ctrlData, withCompletion: { (error) in
                if let error = error {
                    DDLogWarn("Unable to yaw aircraft \(error)")
                }
            })
        }
    }
    
    func flightController(fc: DJIFlightController, didUpdateSystemState state: DJIFlightControllerCurrentState) {
        DDLogVerbose("FC didUpdateSystemState")

        let homeLoc = CLLocation(latitude: state.homeLocation.latitude, longitude: state.homeLocation.longitude)
        let aircraftLoc = CLLocation(latitude: state.aircraftLocation.latitude, longitude: state.aircraftLocation.longitude)

        let dist = homeLoc.distanceFromLocation(aircraftLoc)
        
        self.delegate?.flightControllerUpdateDistance(dist)

        if let compass = fc.compass {
            self.delegate?.flightControllerUpdateHeading(compass.heading)
        }
        
        self.delegate?.flightControllerUpdateAltitude(state.altitude)
        self.delegate?.flightControllerUpdateSatelliteCount(Int(state.satelliteCount))
    }
}