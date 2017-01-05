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
        
        let defaultValue = loadedConfig["defaults"]!["photosPerRow"] as! Int
        
        guard let modelName = ModelConstants.valueToName(model) else {
            return defaultValue
        }
        
        guard let photosPerRow = loadedConfig["photosPerRow"]?[modelName] as? Int else {
            return defaultValue
        }

        return photosPerRow
    }
    
    class func allowsAboveHorizon(model: String) -> Bool {
        let loadedConfig = ModelConfig.sharedInstance.config
        
        let defaultValue = loadedConfig["defaults"]!["allowsAboveHorizon"] as! Bool
        
        guard let modelName = ModelConstants.valueToName(model) else {
            return defaultValue
        }
        
        guard let relativeGimbalYaw = loadedConfig["allowsAboveHorizon"]?[modelName] as? Bool else {
            return defaultValue
        }
        
        return relativeGimbalYaw
    }

    class func relativeGimbalYaw(model: String) -> Bool {
        let loadedConfig = ModelConfig.sharedInstance.config
        
        let defaultValue = loadedConfig["defaults"]!["relativeGimbalYaw"] as! Bool
        
        guard let modelName = ModelConstants.valueToName(model) else {
            return defaultValue
        }

        guard let relativeGimbalYaw = loadedConfig["relativeGimbalYaw"]?[modelName] as? Bool else {
            return defaultValue
        }
        
        return relativeGimbalYaw
    }
    
    class func correctMode(model: String, position: DJIRemoteControllerFlightModeSwitchPosition) -> (Bool, String?) {
        let loadedConfig = ModelConfig.sharedInstance.config

        let defaultValue : (Bool, String?) = (true, nil)
        
        guard let modelName = ModelConstants.valueToName(model) else {
            return defaultValue
        }
        
        guard let positionData = loadedConfig["switchPosition"]?[modelName] as? [String : AnyObject] ?? loadedConfig["defaults"]?["switchPosition"] as? [String : AnyObject] else {
            return defaultValue
        }

        guard let switchPosition = positionData["position"] as? Int else {
            return defaultValue
        }
        
        guard let switchPositionName = positionData["name"] as? String else {
            return defaultValue
        }

        let invalidValue : (Bool, String?) = (false, "Please set RC flight mode switch to \(switchPositionName)")

        
        switch(position) {
        case .One:
            if switchPosition != 1 {
                return invalidValue
            }
        case .Two:
            if switchPosition != 2 {
                return invalidValue
            }
        case .Three:
            if switchPosition != 3 {
                return invalidValue
            }
        }
        
        return defaultValue
    }
}

/**
 * Taken from Aircraft.h and Handheld.h. We want to store constant names in the plist to avoid issues
 * if DJI change a display string.
 */
class ModelConstants {
    class func valueToName(value: String) -> String? {
        switch (value) {
            
        case DJIAircraftModelNameInspire1:
            return "DJIAircraftModelNameInspire1"
        case DJIAircraftModelNameInspire1Pro:
            return "DJIAircraftModelNameInspire1Pro"
        case DJIAircraftModelNameInspire1RAW:
            return "DJIAircraftModelNameInspire1RAW"
        case DJIAircraftModelNamePhantom3Professional:
            return "DJIAircraftModelNamePhantom3Professional"
        case DJIAircraftModelNamePhantom3Advanced:
            return "DJIAircraftModelNamePhantom3Advanced"
        case DJIAircraftModelNamePhantom3Standard:
            return "DJIAircraftModelNamePhantom3Standard"
        case DJIAircraftModelNamePhantom34K:
            return "DJIAircraftModelNamePhantom34K"
        case DJIAircraftModelNameMatrice100:
            return "DJIAircraftModelNameMatrice100"
        case DJIAircraftModelNamePhantom4:
            return "DJIAircraftModelNamePhantom4"
        case DJIAircraftModelNameMatrice600:
            return "DJIAircraftModelNameMatrice600"
        case DJIAircraftModelNameMatrice600Pro:
            return "DJIAircraftModelNameMatrice600Pro"
        case DJIAircraftModelNameA3:
            return "DJIAircraftModelNameA3"
        case DJIAircraftModelNameN3:
            return "DJIAircraftModelNameN3"
        case DJIAircraftModelNameMavicPro:
            return "DJIAircraftModelNameMavicPro"
        case DJIAircraftModelNamePhantom4Pro:
            return "DJIAircraftModelNamePhantom4Pro"
        case DJIAircraftModelNameInspire2:
            return "DJIAircraftModelNameInspire2"
        case DJIHandheldModelNameOsmo:
            return "DJIHandheldModelNameOsmo"
        case DJIHandheldModelNameOsmoPro:
            return "DJIHandheldModelNameOsmoPro"
        case DJIHandheldModelNameOsmoRAW:
            return "DJIHandheldModelNameOsmoRAW"
        case DJIHandheldModelNameOsmoMobile:
            return "DJIHandheldModelNameOsmoMobile"
        case DJIHandheldModelNameOsmoPlus:
            return "DJIHandheldModelNameOsmoPlus"
        default:
            return nil
        }
    }
}
