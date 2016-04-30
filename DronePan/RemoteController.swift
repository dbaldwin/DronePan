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

@objc enum FlightMode: Int {
    case Function = 0
    case Attitude = 1
    case Positioning = 2
    case Sport = 3
}

@objc protocol RemoteControllerDelegate {
    func remoteControllerSetFlightMode(mode: FlightMode)

    func remoteControllerBatteryPercentUpdated(batteryPercent: Int)
}

@objc class RemoteController: NSObject, DJIRemoteControllerDelegate {
    var delegate: RemoteControllerDelegate?

    init(remote: DJIRemoteController) {
        DDLogInfo("Remote Controller init")

        super.init()

        remote.delegate = self
    }

    func remoteController(rc: DJIRemoteController, didUpdateBatteryState batteryInfo: DJIRCBatteryInfo) {
        self.delegate?.remoteControllerBatteryPercentUpdated(Int(batteryInfo.remainingEnergyInPercent))
    }

    func remoteController(rc: DJIRemoteController, didUpdateHardwareState state: DJIRCHardwareState) {
        DDLogVerbose("Remote didUpdateHardwareState")

        var mode: FlightMode

        switch (state.flightModeSwitch.mode) {
        case .F:
            mode = .Function
        case .A:
            mode = .Attitude
        case .P:
            mode = .Positioning
        case .S:
            mode = .Sport
        }


        self.delegate?.remoteControllerSetFlightMode(mode)
    }
}
