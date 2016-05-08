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
import GoogleAnalytics
import CocoaLumberjackSwift
import DeviceKit

extension NSObject {
    func optedIn() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("analyticsOK")
    }
    
    func startAnalytics() {
        let tracker = GAI.sharedInstance()

        if (!optedIn()) {
            tracker.optOut = true
            
            return
        }
        
        tracker.optOut = false
        tracker.trackerWithTrackingId("UA-41932159-3")
        tracker.trackUncaughtExceptions = true
        
        tracker.logger = AnalyticsLumberjackLogger()
        
        trackEvent(category: "System", action: "Device", label: String(Device()))
    }
    
    func trackScreenView(name: String) {
        if (!optedIn()) {
            return
        }
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: name)
        
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    func trackEvent(category category: String, action: String, label: String) {
        if (!optedIn()) {
            return
        }
        
        let tracker = GAI.sharedInstance().defaultTracker

        let builder = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: nil)
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
}

class AnalyticsLumberjackLogger : NSObject, GAILogger {
    @objc var logLevel: GAILogLevel = GAILogLevel.Verbose
    
    @objc func verbose(message: String!) {
        DDLogVerbose(message)
    }
    
    @objc func info(message: String!) {
        DDLogInfo(message)
    }
    
    @objc func warning(message: String!) {
        DDLogWarn(message)
    }
    
    @objc func error(message: String!) {
        DDLogError(message)
    }
}