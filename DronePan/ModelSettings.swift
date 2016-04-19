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

enum SettingsKeys: String {
    case StartDelay = "delay"
    case PhotosPerRow = "photos_per_row"
    case DelayBetweenShots = "delay_between"
    case NumberOfRows = "row_count"
    case SkyRow = "sky_row"
}

@objc class ModelSettings: NSObject {
    private class func settingForKey(model: String, key: SettingsKeys, defaultValue: AnyObject) -> AnyObject {
        var value = defaultValue
        
        if let settings = NSUserDefaults.standardUserDefaults().dictionaryForKey(model) {
            if let storedValue = settings[key.rawValue] {
                value = storedValue
            }
        }
        
        return value
    }
    
    private class func intSettingForKey(model: String, key: SettingsKeys, defaultValue: Int) -> Int {
        var value = defaultValue
        
        if let storedValue = ModelSettings.settingForKey(model, key: key, defaultValue: defaultValue) as? Int {
            value = storedValue
        }
        
        return value
    }

    private class func boolSettingForKey(model: String, key: SettingsKeys, defaultValue: Bool) -> Bool {
        var value = defaultValue
        
        if let storedValue = ModelSettings.settingForKey(model, key: key, defaultValue: defaultValue) as? Bool {
            value = storedValue
        }
        
        return value
    }

    class func startDelay(model: String) -> Int {
        return ModelSettings.intSettingForKey(model, key: .StartDelay, defaultValue: 5)
    }
    
    class func photosPerRow(model: String) -> Int {
        return ModelSettings.intSettingForKey(model, key: .PhotosPerRow, defaultValue: 6)
    }

    class func delayBetweenShots(model: String) -> Int {
        return ModelSettings.intSettingForKey(model, key: .DelayBetweenShots, defaultValue: 6)
    }

    class func numberOfRows(model: String) -> Int {
        return ModelSettings.intSettingForKey(model, key: .NumberOfRows, defaultValue: 3)
    }

    class func skyRow(model: String) -> Bool {
        return ModelSettings.boolSettingForKey(model, key: .SkyRow, defaultValue: false)
    }

    class func updateSettings(model: String, settings newSettings : [SettingsKeys: AnyObject]) {
        var settings : [String : AnyObject] = [:]
        
        if let storedSettings = NSUserDefaults.standardUserDefaults().dictionaryForKey(model) {
            settings = storedSettings
        }
        
        for (key, val) in newSettings {
            settings[key.rawValue] = val
        }
        
        NSUserDefaults.standardUserDefaults().setObject(settings, forKey: model)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
