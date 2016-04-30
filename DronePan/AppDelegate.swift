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
import CocoaLumberjackSwift

let ddloglevel = DDLogLevel.Debug

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var fileLogger: DDFileLogger?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
        UIApplication.sharedApplication().idleTimerDisabled = true

        let logFormatter = LogFormatter()

        DDTTYLogger.sharedInstance().logFormatter = logFormatter
        DDASLLogger.sharedInstance().logFormatter = logFormatter

        DDLog.addLogger(DDTTYLogger.sharedInstance(), withLevel: .Debug) // TTY = Xcode console
        DDLog.addLogger(DDASLLogger.sharedInstance(), withLevel: .Debug) // ASL = Apple System Logs

        fileLogger = DDFileLogger()
        fileLogger!.rollingFrequency = 60 * 60 * 24
        fileLogger!.logFileManager.maximumNumberOfLogFiles = 2
        fileLogger!.logFormatter = logFormatter

        DDLog.addLogger(fileLogger!, withLevel: .Debug)

        DDLogInfo("DronePan launched")

        if let version = ControllerUtils.buildVersion() {
            DDLogInfo("Running version \(version)")
        }

        //DDLogDebug("Logging to \(fileLogger.currentLogFileInfo().filePath)  \(fileLogger.currentLogFileInfo().fileName)")

        return true
    }

    func copyLogToClipboard() -> Bool {
        if let info = fileLogger?.currentLogFileInfo() {
            if let data = NSData(contentsOfFile: info.filePath) {
                UIPasteboard.generalPasteboard().setData(data, forPasteboardType: "public.text")

                return true
            }
        }

        return false
    }

}

