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
    case NumberOfRows = "row_count"
    case NadirCount = "nadir_count"
    case MaxPitch = "max_pitch"
    case MaxPitchEnabled = "max_pitch_enabled"
    case PhotoMode = "photo_mode"
}

class ModelSettings {
    private class func settingForKey(model: String, key: SettingsKeys) -> AnyObject? {
        return NSUserDefaults.standardUserDefaults().dictionaryForKey(model)?[key.rawValue]
    }

    private class func intSettingForKey(model: String, key: SettingsKeys, defaultValue: Int) -> Int {
        return ModelSettings.settingForKey(model, key: key) as? Int ?? defaultValue
    }

    private class func boolSettingForKey(model: String, key: SettingsKeys, defaultValue: Bool) -> Bool {
        return ModelSettings.settingForKey(model, key: key) as? Bool ?? defaultValue
    }
    class func startDelay(model: String) -> Int {
        return ModelSettings.intSettingForKey(model, key: .StartDelay, defaultValue: 5)
    }

    class func photosPerRow(model: String) -> Int {
        return ModelSettings.intSettingForKey(model, key: .PhotosPerRow, defaultValue: ModelConfig.photosPerRow(model))
    }

    class func numberOfRows(model: String) -> Int {
        return ModelSettings.intSettingForKey(model, key: .NumberOfRows, defaultValue: 3)
    }

    class func nadirCount(model: String) -> Int {
        return ModelSettings.intSettingForKey(model, key: .NadirCount, defaultValue: 1)
    }

    class func maxPitch(model: String) -> Int {
        return ModelSettings.intSettingForKey(model, key: .MaxPitch, defaultValue: 0)
    }

    class func maxPitchEnabled(model: String) -> Bool {
        return ModelSettings.boolSettingForKey(model, key: .MaxPitchEnabled, defaultValue: true)
    }
    
    class func photoMode(model: String) -> Int {
        return ModelSettings.intSettingForKey(model, key: .PhotoMode, defaultValue: 0)
    }
    
    class func updateSettings(model: String, settings newSettings: [SettingsKeys:AnyObject]) {
        var settings: [String:AnyObject] = NSUserDefaults.standardUserDefaults().dictionaryForKey(model) ?? [:]

        var minRowCount : Int?
        
        for (key, val) in newSettings {
            if (key == .MaxPitch) {
                if (val as! Int > 0) {
                    minRowCount = 4
                }
            }
            settings[key.rawValue] = val
        }

        NSUserDefaults.standardUserDefaults().setObject(settings, forKey: model)
        
        if let minRowCount = minRowCount {
            let currentRowCount = numberOfRows(model)
            
            if currentRowCount < minRowCount {
                settings[SettingsKeys.NumberOfRows.rawValue] = minRowCount
                
                NSUserDefaults.standardUserDefaults().setObject(settings, forKey: model)
            }
        }

        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func numberOfImagesForCurrentSettings(model: String) -> Int {
        let numberOfRows = ModelSettings.numberOfRows(model)

        let photosPerRow = ModelSettings.photosPerRow(model)

        let nadirCount = ModelSettings.nadirCount(model)
        
        return (numberOfRows * photosPerRow) + nadirCount
    }
}
