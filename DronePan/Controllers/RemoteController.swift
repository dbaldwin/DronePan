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

protocol RemoteControllerDelegate {
    func remoteControllerBatteryPercentUpdated(batteryPercent: Int)
}

class RemoteController: NSObject, DJIRemoteControllerDelegate {
    var delegate: RemoteControllerDelegate?

    var mode = DJIRemoteControllerFlightModeSwitchPosition.One

    init(remote: DJIRemoteController) {
        DDLogInfo("Remote Controller init")

        super.init()

        remote.delegate = self
    }

    @objc func remoteController(rc: DJIRemoteController, didUpdateBatteryState batteryInfo: DJIRCBatteryInfo) {
        self.delegate?.remoteControllerBatteryPercentUpdated(Int(batteryInfo.remainingEnergyInPercent))
    }

    @objc func remoteController(rc: DJIRemoteController, didUpdateHardwareState state: DJIRCHardwareState) {
        DDLogVerbose("Remote didUpdateHardwareState")

        mode = state.flightModeSwitch
    }
}
