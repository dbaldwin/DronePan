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
    case ACGimbalYaw = "ac_gimbal_yaw"
}

protocol ModelSettings {
    func startDelay(model: String) -> Int

    func photosPerRow(model: String) -> Int

    func numberOfRows(model: String) -> Int

    func nadirCount(model: String) -> Int

    func maxPitch(model: String) -> Int

    func maxPitchEnabled(model: String) -> Bool

    func acGimbalYaw(model: String) -> Bool

    func updateSettings(model: String, settings newSettings: [SettingsKeys:AnyObject])

    func numberOfImagesForCurrentSettings(model: String) -> Int
}

extension ModelSettings {
    private func settingForKey(model: String, key: SettingsKeys) -> AnyObject? {
        return NSUserDefaults.standardUserDefaults().dictionaryForKey(model)?[key.rawValue]
    }

    private func intSettingForKey(model: String, key: SettingsKeys, defaultValue: Int) -> Int {
        return settingForKey(model, key: key) as? Int ?? defaultValue
    }

    private func boolSettingForKey(model: String, key: SettingsKeys, defaultValue: Bool) -> Bool {
        return settingForKey(model, key: key) as? Bool ?? defaultValue
    }

    func startDelay(model: String) -> Int {
        return intSettingForKey(model, key: .StartDelay, defaultValue: 5)
    }

    func photosPerRow(model: String) -> Int {
        return intSettingForKey(model, key: .PhotosPerRow, defaultValue: 6)
    }

    func numberOfRows(model: String) -> Int {
        return intSettingForKey(model, key: .NumberOfRows, defaultValue: 3)
    }

    func nadirCount(model: String) -> Int {
        return intSettingForKey(model, key: .NadirCount, defaultValue: 1)
    }

    func maxPitch(model: String) -> Int {
        return intSettingForKey(model, key: .MaxPitch, defaultValue: 0)
    }

    func maxPitchEnabled(model: String) -> Bool {
        return boolSettingForKey(model, key: .MaxPitchEnabled, defaultValue: true)
    }

    func acGimbalYaw(model: String) -> Bool {
        return boolSettingForKey(model, key: .ACGimbalYaw, defaultValue: false)
    }
    
    func updateSettings(model: String, settings newSettings: [SettingsKeys:AnyObject]) {
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
    
    func numberOfImagesForCurrentSettings(model: String) -> Int {
        let rows = numberOfRows(model)

        let photos = photosPerRow(model)

        let nadir = nadirCount(model)
        
        return (rows * photos) + nadir
    }
}
