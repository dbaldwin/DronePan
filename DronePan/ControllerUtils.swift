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

@objc enum ControllerStatus: Int {
    case Normal = 0
    case Error = 1
    case Stopping = 2
}

@objc class ControllerUtils: NSObject {
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
    
    class func displayToastOnApp(message: String) {
        dispatch_async(dispatch_get_main_queue()) { 
            if let view = UIApplication.sharedApplication().keyWindow?.rootViewController?.view {
                let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
                hud.color = UIColor(colorLiteralRed: 0, green: 122.0/255.0, blue: 1, alpha: 1)
                hud.mode = .Text
                hud.labelText = message
                hud.margin = 10.0
                hud.removeFromSuperViewOnHide = true
                hud.hide(true, afterDelay: 5)
            }
        }
    }
    
    @objc class func isInspire(model: String) -> Bool {
        return model == DJIAircraftModelNameInspire1 ||
            model == DJIAircraftModelNameInspire1Pro ||
            model == DJIAircraftModelNameInspire1RAW
    }
    
    @objc class func isPhantom3(model: String) -> Bool {
        return model == DJIAircraftModelNamePhantom34K ||
            model == DJIAircraftModelNamePhantom3Advanced ||
            model == DJIAircraftModelNamePhantom3Standard ||
            model == DJIAircraftModelNamePhantom3Professional
    }
    
    @objc class func isPhantom4(model: String) -> Bool {
        return model == DJIAircraftModelNamePhantom4
    }

    @objc class func isPhantom(model: String) -> Bool {
        return ControllerUtils.isPhantom3(model) || ControllerUtils.isPhantom4(model)
    }
}
