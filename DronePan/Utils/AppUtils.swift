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
import MBProgressHUD

enum ControllerStatus {
    case Normal
    case Error
    case Stopping
}

protocol ModelUtils {
    func isInspire(model: String) -> Bool

    func isPhantom3(model: String) -> Bool

    func isPhantom4(model: String) -> Bool

    func isPhantom(model: String) -> Bool

    func gimbalYawIsRelativeToAircraft(model: String?) -> Bool
}

extension ModelUtils {
    func isInspire(model: String) -> Bool {
        return model == DJIAircraftModelNameInspire1 ||
                model == DJIAircraftModelNameInspire1Pro ||
                model == DJIAircraftModelNameInspire1RAW
    }

    func isPhantom3(model: String) -> Bool {
        return model == DJIAircraftModelNamePhantom34K ||
                model == DJIAircraftModelNamePhantom3Advanced ||
                model == DJIAircraftModelNamePhantom3Standard ||
                model == DJIAircraftModelNamePhantom3Professional
    }

    func isPhantom4(model: String) -> Bool {
        return model == DJIAircraftModelNamePhantom4
    }

    func isPhantom(model: String) -> Bool {
        return isPhantom3(model) || isPhantom4(model)
    }

    func gimbalYawIsRelativeToAircraft(model: String?) -> Bool {
        if let model = model {
            return isPhantom4(model) || isInspire(model)
        } else {
            return false
        }
    }
}

protocol SystemUtils {
    func droneCommandsQueue() -> dispatch_queue_t

    func delay(delay: Double, queue: dispatch_queue_t, closure: () -> ())

    func buildVersion() -> String?

    func setMetricUnits(metric: Bool)

    func metricUnits() -> Bool

    func displayDistance(distance: Int) -> String
    
    func headingTo360(heading: Double) -> Double
    
    func angleForHeading(heading: Double) -> Double
}

extension SystemUtils {
    func droneCommandsQueue() -> dispatch_queue_t {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        return appDelegate.droneCommandsQueue
    }
    
    func delay(delay: Double, queue: dispatch_queue_t, closure: () -> ()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
                queue,
                closure)
    }

    func buildVersion() -> String? {
        let info = NSBundle.mainBundle().infoDictionary

        if let version = info?["CFBundleShortVersionString"], build = info?["CFBundleVersion"] {
            return "\(version)(\(build))"
        }

        return nil
    }

    func setMetricUnits(metric: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(!metric, forKey: "unitsInFeet")
    }

    func metricUnits() -> Bool {
        return !NSUserDefaults.standardUserDefaults().boolForKey("unitsInFeet")
    }

    func displayDistance(distance: Int) -> String {
        if (metricUnits()) {
            return "\(distance)m"
        } else {
            return "\(Int(round(Double(distance) * 3.280839895)))'"
        }
    }

    func headingTo360(heading: Double) -> Double {
        return heading >= 0 ? heading : heading + 360.0
    }
    
    func angleForHeading(angle: Double) -> Double {
        let sign = (angle == 0) ? 1 : angle / fabs(angle)
        
        var angleInRange = angle * sign
        
        while angleInRange > 360 {
            angleInRange -= 360
        }
        
        if (angleInRange > 180) {
            angleInRange = (360 - angleInRange) * -1.0
        }
        
        let newAngle = angleInRange * sign
        
        return newAngle
    }

}
