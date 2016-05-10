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

    class func isInspire(model: String) -> Bool {
        return model == DJIAircraftModelNameInspire1 ||
                model == DJIAircraftModelNameInspire1Pro ||
                model == DJIAircraftModelNameInspire1RAW
    }

    class func isPhantom3(model: String) -> Bool {
        return model == DJIAircraftModelNamePhantom34K ||
                model == DJIAircraftModelNamePhantom3Advanced ||
                model == DJIAircraftModelNamePhantom3Standard ||
                model == DJIAircraftModelNamePhantom3Professional
    }

    class func isPhantom4(model: String) -> Bool {
        return model == DJIAircraftModelNamePhantom4
    }

    class func isPhantom(model: String) -> Bool {
        return ControllerUtils.isPhantom3(model) || ControllerUtils.isPhantom4(model)
    }

    // TODO: this should be P4 only - https://github.com/dbaldwin/DronePan/issues/48
    class func supportsSDKYaw(model: String?) -> Bool {
        if let model = model {
            return !(ControllerUtils.isPhantom4(model) || ControllerUtils.isInspire(model))
        } else {
            return false
        }
    }
}
