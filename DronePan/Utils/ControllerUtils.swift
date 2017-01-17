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

enum BatteryIcon : String {
    case Unknown = "BatteryIcon - ??"
    case Empty = "BatteryIcon - 00"
    case Low = "BatteryIcon - 25"
    case Half = "BatteryIcon - 50"
    case High = "BatteryIcon - 75"
    case Full = "BatteryIcon - 100"
    
    func image() -> UIImage? {
        return UIImage(named: self.rawValue)
    }
}

enum ConnectionStatusIcon : String {
    case Disconnected = "Disconnected"
    case Connected = "Connected"
    
    func image() -> UIImage? {
        return UIImage(named: self.rawValue)
    }
}

class ControllerUtils {
    class func delay(delay: Double, queue: dispatch_queue_t, closure: () -> ()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
                queue,
                closure)
    }


    class func buildVersion() -> String? {
        let info = NSBundle.mainBundle().infoDictionary

        if let version = info?["CFBundleShortVersionString"], build = info?["CFBundleVersion"] {
            return "\(version)(\(build))"
        }

        return nil
    }

    class func gimbalYawIsRelativeToAircraft(model: String?) -> Bool {
        if let model = model {
            return ModelConfig.relativeGimbalYaw(model)
        } else {
            return false
        }
    }

    class func setMetricUnits(metric: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(!metric, forKey: "unitsInFeet")
    }

    class func metricUnits() -> Bool {
        return !NSUserDefaults.standardUserDefaults().boolForKey("unitsInFeet")
    }

    class func displayDistance(distance: Int) -> String {
        if (metricUnits()) {
            return "\(distance)m"
        } else {
            return "\(Int(round(Double(distance) * 3.280839895)))'"
        }
    }

    class func batteryImageForLevel(level : Int? = nil) -> UIImage? {
        var icon : BatteryIcon = .Unknown
        
        if let level = level {
            switch(level) {
            case (90...100):
                icon = .Full
            case (70..<90):
                icon = .High
            case (45..<70):
                icon = .Half
            case (20..<45):
                icon = .Low
            case (0..<20):
                icon = .Empty
            default:
                icon = .Unknown
            }
        }
        
        return icon.image()
    }
}
