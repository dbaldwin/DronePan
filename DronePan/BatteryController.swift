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
import CocoaLumberjackSwift

@objc protocol BatteryControllerDelegate {
    func batteryControllerPercentUpdated(batteryPercent: Int)

    func batteryControllerTemperatureUpdated(batteryTemperature: Int)
}

@objc class BatteryController: NSObject, DJIBatteryDelegate {
    var delegate: BatteryControllerDelegate?
    
    init(battery: DJIBattery) {
        DDLogInfo("Battery Controller init")
        
        super.init()

        battery.delegate = self
    }
    
    func battery(battery: DJIBattery, didUpdateState batteryState: DJIBatteryState) {
        DDLogVerbose("Battery didUpdateState")
        
        self.delegate?.batteryControllerPercentUpdated(batteryState.batteryEnergyRemainingPercent)

        self.delegate?.batteryControllerTemperatureUpdated(batteryState.batteryTemperature)
    }
}
