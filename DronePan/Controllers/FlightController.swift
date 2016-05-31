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

    func flightControllerUnableToSetControlMode()

    func flightControllerSetControlMode()

    func flightControllerUnableToYaw(reason: String)
    
    func flightControllerDidYaw()
}

class FlightController: NSObject, DJIFlightControllerDelegate, DJISimulatorDelegate, SystemUtils {
    let fc: DJIFlightController

    let yawSpeedThreshold = 0.5

    var delegate: FlightControllerDelegate?

    var yawDestination : Double?
    var yawSpeed = 0.0

    init(fc: DJIFlightController) {
        DDLogInfo("Flight Controller init")

        self.fc = fc

        super.init()

        fc.delegate = self

        if let simulator = fc.simulator {
            simulator.delegate = self
        }
    }

    func setControlModes() {
        self.fc.enableVirtualStickControlModeWithCompletion {
            (error) in
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

            self.fc.sendVirtualStickFlightControlData(ctrlData, withCompletion: {
                (error) in
                if let error = error {
                    DDLogWarn("Unable to yaw aircraft \(error)")

                    self.delegate?.flightControllerUnableToYaw("Unable to yaw: \(error)")
                }
            })
        }
    }

    func yawTo(yaw: Double) {
        DDLogDebug("Yaw to \(yaw)")

        self.yawSpeed = 30 // This represents 30m/sec
        self.yawDestination = yaw
        
        // Calling this on a timer as it improves the accuracy of aircraft yaw
        dispatch_sync(droneCommandsQueue(), {
            let timer = NSTimer.scheduledTimerWithTimeInterval(0.1,
                target: self,
                selector: #selector(FlightController.yawAircraftUsingVelocity(_:)),
                userInfo: nil,
                repeats: true)
            
            NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
            NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 5))
            
            if timer.valid {
                timer.invalidate()
                self.delegate?.flightControllerUnableToYaw("Yaw did not complete")
            }
        })
    }

    @objc func yawAircraftUsingVelocity(timer: NSTimer) {
        DDLogDebug("Yawing speed \(self.yawSpeed) target \(self.yawDestination)")

        if let _ = self.yawDestination {
            if (self.yawSpeed < yawSpeedThreshold) {
                self.delegate?.flightControllerDidYaw()
                self.yawSpeed = 0
                self.yawDestination = nil
                
                timer.invalidate()
            } else {
                self.yaw(self.yawSpeed)
            }
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

            if let yawDestination = self.yawDestination {
                var diff = 0.0

                DDLogDebug("Current heading \(currentHeading) target \(yawDestination)")
                if (yawDestination > currentHeading) {
                    diff = fabs(yawDestination) - fabs(currentHeading)
                    self.yawSpeed = diff * 0.5
                } else {
                    // This happens when the current heading is 340 and destination is 40, for example
                    diff = fabs(currentHeading) - fabs(yawDestination)
                    self.yawSpeed = fmod(360.0, diff) * 0.5
                }

                if self.yawSpeed.isNaN {
                    self.yawSpeed = 0.00000001
                }
                
                DDLogDebug("Current heading \(currentHeading) target \(yawDestination) diff \(diff) yawSpeed \(self.yawSpeed)")
            }
            
            self.delegate?.flightControllerUpdateHeading(currentHeading)
        }

        self.delegate?.flightControllerUpdateAltitude(state.altitude)
        self.delegate?.flightControllerUpdateSatelliteCount(Int(state.satelliteCount))
    }

    func simulator(simulator: DJISimulator, updateSimulatorState state: DJISimulatorState) {
        // TODO: it's just possible that state.pitch, state.roll, state.yaw here could help in testing        
    }
}