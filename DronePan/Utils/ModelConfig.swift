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

class ModelConfig {
    static let sharedInstance = ModelConfig.modelConfig()
    
    var config : [String: AnyObject] = [:]
    
    
    init?() {
        guard let path = NSBundle.mainBundle().pathForResource("ModelConfig", ofType: "plist") else {
            return nil
        }
        
        guard let xml = NSFileManager.defaultManager().contentsAtPath(path) else {
            return nil
        }
        
        do {
            var format = NSPropertyListFormat.XMLFormat_v1_0
            self.config = try NSPropertyListSerialization.propertyListWithData(xml, options: .MutableContainersAndLeaves, format: &format) as! [String: AnyObject]
            
        } catch {
            return nil
        }
    }
    
    init(defaultConfig : [String: AnyObject]) {
        self.config = defaultConfig
    }
    
    class func modelConfig() -> ModelConfig {
        if let data = ModelConfig() {
            return data
        } else {
            return ModelConfig(defaultConfig: [
                "defaults": [
                    "relativeGimbalYaw": true,
                    "photosPerRow": 6,
                    "switchMode": "F"
                ]
            ])
        }
    }
    
    class func photosPerRow(model: String) -> Int {
        let loadedConfig = ModelConfig.sharedInstance.config
        
        guard let photosPerRow = loadedConfig["photosPerRow"]?[model] as? Int else {
            return loadedConfig["defaults"]!["photosPerRow"] as! Int
        }

        return photosPerRow
    }

    class func relativeGimbalYaw(model: String) -> Bool {
        let loadedConfig = ModelConfig.sharedInstance.config
        
        guard let relativeGimbalYaw = loadedConfig["relativeGimbalYaw"]?[model] as? Bool else {
            return loadedConfig["defaults"]!["relativeGimbalYaw"] as! Bool
        }
        
        return relativeGimbalYaw
    }
    
    class func switchMode(model: String) -> FlightMode {
        let loadedConfig = ModelConfig.sharedInstance.config
        
        guard let switchMode = loadedConfig["switchMode"]?[model] as? String ?? loadedConfig["defaults"]?["switchMode"] as? String else {
            return FlightMode.Function
        }
        
        switch (switchMode) {
        case "F":
            return FlightMode.Function
        case "A":
            return FlightMode.Attitude
        case "P":
            return FlightMode.Positioning
        case "S":
            return FlightMode.Sport
        default:
            return FlightMode.Unknown
        }
    }
}
