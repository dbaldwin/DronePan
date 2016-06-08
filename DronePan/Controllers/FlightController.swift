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

protocol FlightControllerDelegate {
    func flightControllerUpdateHeading(compassHeading: Double)

    func flightControllerUpdateAltitude(altitude: Float)

    func flightControllerUpdateSatelliteCount(satelliteCount: Int)

    func flightControllerUpdateDistance(distance: CLLocationDistance)
}

class FlightController: NSObject, DJIFlightControllerDelegate, DJISimulatorDelegate, SystemUtils, Analytics, DJIMissionManagerDelegate {
    let fc: DJIFlightController

    var delegate: FlightControllerDelegate?

    init(fc: DJIFlightController) {
        DDLogInfo("Flight Controller init")

        self.fc = fc

        super.init()

        fc.delegate = self

        if let simulator = fc.simulator {
            simulator.delegate = self
        }
    }

    @objc func flightController(fc: DJIFlightController, didUpdateSystemState state: DJIFlightControllerCurrentState) {
        DDLogVerbose("FC didUpdateSystemState")

        let homeLoc = CLLocation(latitude: state.homeLocation.latitude, longitude: state.homeLocation.longitude)
        let aircraftLoc = CLLocation(latitude: state.aircraftLocation.latitude, longitude: state.aircraftLocation.longitude)

        let dist = homeLoc.distanceFromLocation(aircraftLoc)

        self.delegate?.flightControllerUpdateDistance(dist)

        if let compass = fc.compass {
            let currentHeading = headingTo360(compass.heading)
            
            DDLogDebug("Current heading \(currentHeading)")

            self.delegate?.flightControllerUpdateHeading(currentHeading)
        }

        self.delegate?.flightControllerUpdateAltitude(state.altitude)
        self.delegate?.flightControllerUpdateSatelliteCount(Int(state.satelliteCount))
    }

    func simulator(simulator: DJISimulator, updateSimulatorState state: DJISimulatorState) {
        // TODO: it's just possible that state.pitch, state.roll, state.yaw here could help in testing        
    }
}