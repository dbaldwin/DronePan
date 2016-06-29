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
import GoogleAnalytics
import GoogleMaps
import CoreData

let ddloglevel = DDLogLevel.Debug

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, Analytics {

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
        fileLogger!.rollingFrequency = 60 * 60 * 24 * 5 // 5 days
        fileLogger!.maximumFileSize = 1024 * 1024 * 2 // 2 Mb
        fileLogger!.logFileManager.maximumNumberOfLogFiles = 2
        fileLogger!.logFormatter = logFormatter

        DDLog.addLogger(fileLogger!, withLevel: .Debug)

        DDLogInfo("DronePan launched")

        if let version = ControllerUtils.buildVersion() {
            DDLogInfo("Running version \(version)")
        }

        //DDLogDebug("Logging to \(fileLogger.currentLogFileInfo().filePath)  \(fileLogger.currentLogFileInfo().fileName)")

        let defaults = NSUserDefaults.standardUserDefaults()
        let appDefaults = [
                "infoOverride": false,
                "analyticsOK": false
        ]
        defaults.registerDefaults(appDefaults)
        defaults.synchronize()

        let hasOpted = defaults.boolForKey("hasOptedAnayltics")

        if !hasOpted {
            showAnalyticsOpt()
        } else {
            startAnalytics()
        }
        
        // Google Maps initialization
        GMSServices.provideAPIKey("AIzaSyCDz1tCnoS2OkhSl1f--DYSWF-VxHLo7l8");
        
        // Initialize the split view controller and children
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let leftNavController = splitViewController.viewControllers.first as! UINavigationController
        let masterViewController = leftNavController.topViewController as! PanoTableViewController
        let detailViewController = splitViewController.viewControllers.last as! PanoMapViewController
        
        // Setup the delegate so that the map gets updated when a pano is selected
        masterViewController.delegate = detailViewController

        return true
    }

    func showAnalyticsOpt() {
        let alert = UIAlertController(title: "Analytics", message: "Will you help development by allowing us to collect some anonymous usage analytics?", preferredStyle: .Alert)

        let defaults = NSUserDefaults.standardUserDefaults()

        let okAction = UIAlertAction(title: "Yes", style: .Default) {
            (action) in
            defaults.setBool(true, forKey: "hasOptedAnayltics")
            defaults.setBool(true, forKey: "analyticsOK")

            self.responseAlert("Thank you", message: "Thank you for helping us make DronePan better")

            self.startAnalytics()
        }

        let notOkAction = UIAlertAction(title: "No", style: .Cancel) {
            (action) in
            defaults.setBool(true, forKey: "hasOptedAnayltics")
            defaults.setBool(false, forKey: "analyticsOK")

            self.responseAlert("That's OK", message: "If you change your mind later - you can change this under iOS > Settings > DronePan")
        }

        alert.addAction(okAction)
        alert.addAction(notOkAction)

        popAlert(alert)
    }

    func responseAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)

        alert.addAction(action)

        self.popAlert(alert)
    }

    func popAlert(alert: UIAlertController) {
        dispatch_async(dispatch_get_main_queue(), {
            self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        })
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
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
        
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("DronePan", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}

