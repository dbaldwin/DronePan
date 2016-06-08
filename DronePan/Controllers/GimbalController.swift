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

protocol GimbalControllerDelegate {
    func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float)
}

class GimbalController: NSObject, DJIGimbalDelegate, Analytics, SystemUtils {
    let gimbal: DJIGimbal

    var delegate: GimbalControllerDelegate?

    var currentACYaw: Float = 0

    let relativeGimbalYaw: Bool

    let maxPitch: Int
    
    var supportsRangeExtension = false
    init(gimbal: DJIGimbal, gimbalYawIsRelativeToAircraft: Bool = false) {
        DDLogInfo("Gimbal Controller init")

        self.gimbal = gimbal

        self.relativeGimbalYaw = gimbalYawIsRelativeToAircraft

        if let pitchInfo = gimbal.gimbalCapability[DJIGimbalKeyAdjustPitch] as? DJIParamCapabilityMinMax {
            if (pitchInfo.isSupported) {
                maxPitch = pitchInfo.max.integerValue
            } else {
                maxPitch = 0
            }
        } else {
            maxPitch = 0
        }

        if let rangeExtension = gimbal.gimbalCapability[DJIGimbalKeyPitchRangeExtension] as? DJIParamCapability {
            DDLogDebug("Range extension supported: \(rangeExtension.isSupported)")

            self.supportsRangeExtension = rangeExtension.isSupported
            // TOOD - we should now be able to check and set sky row. Testing on all devices needed.
            /*
            if rangeExtension.isSupported {
                gimbal!.setPitchRangeExtensionEnabled(true, withCompletion: nil)
            }
            */
        }

        super.init()

        gimbal.delegate = self
    }

    func setACYaw(acYaw: Float) {
        self.currentACYaw = acYaw
    }

    func getMaxPitch() -> Int {
        return maxPitch
    }
    
    
    func gimbalAngleForHeading(angle: Float) -> Float {
        let sign = (angle == 0) ? 1 : angle / fabs(angle)
        
        var angleInRange = angle * sign
        
        while angleInRange > 360 {
            angleInRange -= 360
        }
        
        if (angleInRange > 180) {
            angleInRange = (360 - angleInRange) * -1.0
        }
        
        let newAngle = angleInRange * sign
        
        DDLogVerbose("Gimbal Controller angle \(angle) adjusted to \(newAngle)")
        
        return newAngle
    }
    
    func adjustedYaw(yaw: Float) -> Float {
        if (!relativeGimbalYaw) {
            return yaw
        } else {
            return gimbalAngleForHeading(self.currentACYaw) - yaw
        }
    }
    
    @objc func gimbal(gimbal: DJIGimbal, didUpdateGimbalState gimbalState: DJIGimbalState) {
        let atti = gimbalState.attitudeInDegrees

        DDLogVerbose("Gimbal Controller didUpdateGimbalState P:\(atti.pitch) Y:\(atti.yaw) R:\(atti.roll)")

        self.delegate?.gimbalAttitudeChanged(pitch: atti.pitch, yaw: adjustedYaw(atti.yaw), roll: atti.roll)
    }

}
