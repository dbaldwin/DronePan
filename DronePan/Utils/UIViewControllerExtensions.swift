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
import MBProgressHUD

extension UIViewController {
    func displayToastOnApp(message: String, view : UIView? = UIApplication.sharedApplication().keyWindow?.rootViewController?.view) {
        dispatch_async(dispatch_get_main_queue()) {
            if let view = view {
                let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
                hud.bezelView.color = UIColor(colorLiteralRed: 0, green: 122.0 / 255.0, blue: 1, alpha: 1)
                hud.mode = .Text
                hud.label.text = message
                hud.margin = 10.0
                hud.removeFromSuperViewOnHide = true
                hud.hideAnimated(true, afterDelay: 5)
            }
        }
    }
}
