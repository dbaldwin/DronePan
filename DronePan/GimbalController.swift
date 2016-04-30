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

@objc protocol GimbalControllerDelegate {
    func gimbalControllerCompleted()

    func gimbalControllerAborted(reason: String)

    func gimbalMoveOutOfRange(reason: String)

    optional func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float)
}

@objc class GimbalController: NSObject, DJIGimbalDelegate {
    let gimbal: DJIGimbal

    var delegate: GimbalControllerDelegate?
    var status: ControllerStatus = .Normal

    let maxCount = 5
    let allowedOffset: Float = 2.5

    var currentPitch: Float = 0
    var currentYaw: Float = 0
    var currentRoll: Float = 0

    var lastSetPitch: Float = 0
    var lastSetYaw: Float = 0
    var lastSetRoll: Float = 0

    let isPitchAdjustable: Bool
    let isYawAdjustable: Bool
    let isRollAdjustable: Bool

    let pitchRange: Range<Int>?
    let yawRange: Range<Int>?
    let rollRange: Range<Int>?

    let gimbalWorkQueue = dispatch_queue_create("com.dronepan.queue.gimbal", DISPATCH_QUEUE_CONCURRENT)

    init(gimbal: DJIGimbal, supportsSDKYaw: Bool = true) {
        DDLogInfo("Gimbal Controller init")

        self.gimbal = gimbal

        if let pitchInfo = gimbal.gimbalCapability[DJIGimbalKeyAdjustPitch] as? DJIParamCapabilityMinMax {
            isPitchAdjustable = pitchInfo.isSupported

            if (isPitchAdjustable) {
                pitchRange = pitchInfo.min.integerValue ... pitchInfo.max.integerValue
            } else {
                pitchRange = nil
            }
        } else {
            isPitchAdjustable = false
            pitchRange = nil
        }

        if let yawInfo = gimbal.gimbalCapability[DJIGimbalKeyAdjustYaw] as? DJIParamCapabilityMinMax {
            isYawAdjustable = yawInfo.isSupported && supportsSDKYaw

            if (isYawAdjustable) {
                yawRange = yawInfo.min.integerValue ... yawInfo.max.integerValue
            } else {
                yawRange = nil
            }
        } else {
            isYawAdjustable = false
            yawRange = nil
        }

        if let rollInfo = gimbal.gimbalCapability[DJIGimbalKeyAdjustRoll] as? DJIParamCapabilityMinMax {
            isRollAdjustable = rollInfo.isSupported

            if (isRollAdjustable) {
                rollRange = rollInfo.min.integerValue ... rollInfo.max.integerValue
            } else {
                rollRange = nil
            }
        } else {
            isRollAdjustable = false
            rollRange = nil
        }

        if let rangeExtension = gimbal.gimbalCapability[DJIGimbalKeyPitchRangeExtension] as? DJIParamCapability {
            DDLogDebug("Range extension supported: \(rangeExtension.isSupported)")

            // TOOD - we should now be able to check and set sky row. Testing on all devices needed.
            /*
            if rangeExtension.isSupported {
                gimbal!.setPitchRangeExtensionEnabled(true, withCompletion: nil)
            }
            */
        }

        super.init()

        DDLogDebug("Gimbal Controller contraints pitch: A: \(isPitchAdjustable) Mn: \(pitchRange?.minElement()) Mx: \(pitchRange?.maxElement())")
        DDLogDebug("Gimbal Controller contraints yaw: A: \(isYawAdjustable) Mn: \(yawRange?.minElement()) Mx: \(yawRange?.maxElement())")
        DDLogDebug("Gimbal Controller contraints roll: A: \(isRollAdjustable) Mn: \(rollRange?.minElement()) Mx: \(rollRange?.maxElement())")

        gimbal.completionTimeForControlAngleAction = 0.5
        gimbal.delegate = self
    }

    func reset() {
        DDLogInfo("Gimbal Controller reset")

        self.status = .Normal

        self.lastSetPitch = 0
        self.lastSetYaw = 0
        self.lastSetRoll = 0

        dispatch_async(self.gimbalWorkQueue) {
//            self.reset(0) This seems to have a bug in the API which fails without error
            self.setAttitude(0, pitch: 0, yaw: 0, roll: 0)
        }
    }

    func inRange(value: Float, range: Range<Int>?, available: Bool) -> Bool {
        if (!available) {
            return false
        }

        if let min = range?.minElement(), max = range?.maxElement() {
            return Float(min) ... Float(max) ~= value
        }

        return false
    }

    func setPitch(pitch: Float) {
        DDLogInfo("Gimbal Controller set pitch to \(pitch)")

        let pitchInRange = self.gimbalAngleForHeading(pitch)

        if (!inRange(pitchInRange, range: pitchRange, available: isPitchAdjustable)) {
            DDLogWarn("Gimbal Controller set pitch to \(pitchInRange) out of range")

            self.delegate?.gimbalMoveOutOfRange("Pitch \(pitchInRange) was out of range")

            return
        }

        self.status = .Normal

        self.lastSetPitch = pitchInRange
        dispatch_async(self.gimbalWorkQueue) {
            self.setAttitude(0, pitch: pitchInRange, yaw: self.lastSetYaw, roll: self.lastSetRoll)
        }
    }

    func setYaw(yaw: Float) {
        DDLogInfo("Gimbal Controller set yaw to \(yaw)")

        let yawInRange = self.gimbalAngleForHeading(yaw)

        if (!inRange(yawInRange, range: yawRange, available: isYawAdjustable)) {
            DDLogWarn("Gimbal Controller set yaw to \(yawInRange) out of range")

            self.delegate?.gimbalMoveOutOfRange("Yaw \(yawInRange) was out of range")

            return
        }

        self.status = .Normal

        self.lastSetYaw = yawInRange
        dispatch_async(self.gimbalWorkQueue) {
            self.setAttitude(0, pitch: self.lastSetPitch, yaw: yawInRange, roll: self.lastSetRoll)
        }
    }

    func setRoll(roll: Float) {
        DDLogInfo("Gimbal Controller set roll to \(roll)")

        let rollInRange = self.gimbalAngleForHeading(roll)

        if (!inRange(rollInRange, range: rollRange, available: isRollAdjustable)) {
            DDLogWarn("Gimbal Controller set roll to \(rollInRange) out of range")

            self.delegate?.gimbalMoveOutOfRange("Roll \(rollInRange) was out of range")

            return
        }

        self.status = .Normal

        self.lastSetRoll = rollInRange
        dispatch_async(self.gimbalWorkQueue) {
            self.setAttitude(0, pitch: self.lastSetPitch, yaw: self.lastSetYaw, roll: rollInRange)
        }
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

        DDLogDebug("Gimbal Controller angle \(angle) adjusted to \(newAngle)")

        return newAngle
    }

    private func delay(delay: Double, closure: () -> ()) {
        if (status != .Normal) {
            DDLogDebug("Gimbal Controller delay - status was \(status) - returning")

            return
        }

        ControllerUtils.delay(delay, queue: self.gimbalWorkQueue, closure: closure)
    }

    func valueInRange(adjustable: Bool, value: Float, currentValue: Float) -> Bool {
        return !adjustable || ((value - allowedOffset) ... (value + allowedOffset) ~= currentValue)
    }

    func check(pitch p: Float, yaw y: Float, roll r: Float) -> Bool {
        DDLogDebug("Checking PA: \(isPitchAdjustable) P: \(p) CP: \(self.currentPitch)")
        DDLogDebug("Checking YA: \(isYawAdjustable) Y: \(y) CY: \(self.currentYaw)")
        DDLogDebug("Checking RA: \(isRollAdjustable) R: \(r) CR: \(self.currentRoll)")

        return valueInRange(isPitchAdjustable, value: p, currentValue: self.currentPitch) &&
                valueInRange(isYawAdjustable, value: y, currentValue: self.currentYaw) &&
                valueInRange(isRollAdjustable, value: r, currentValue: self.currentRoll)
    }

    private func reset(counter: Int) {
        if (status != .Normal) {
            DDLogDebug("Gimbal Controller reset - status was \(status) - returning")

            return
        }

        self.lastSetPitch = 0
        self.lastSetYaw = 0
        self.lastSetRoll = 0

        if (counter > maxCount) {
            self.delegate?.gimbalControllerAborted("Unable to reset gimbal")
            return
        }

        let nextCount = counter + 1

        self.gimbal.resetGimbalWithCompletion {
            (error) in

            if let e = error {
                NSLog("Error resetting gimbal: \(e)")

                self.reset(nextCount)
            }
        }

        delay(gimbal.completionTimeForControlAngleAction + 0.5) {
            if !self.check(pitch: 0, yaw: 0, roll: 0) {
                NSLog("Gimbal not reset count: \(counter)")

                self.reset(nextCount)
            } else {
                NSLog("Gimbal OK reset count: \(counter)")

                self.delegate?.gimbalControllerCompleted()
            }
        }
    }

    private func setAttitude(counter: Int, pitch: Float, yaw: Float, roll: Float) {
        if (status != .Normal) {
            DDLogDebug("Gimbal Controller setAttitude - status was \(status) - returning")

            return
        }

        DDLogDebug("Setting attitude: count \(counter), pitch \(pitch), yaw \(yaw), roll \(roll)")

        if (counter > maxCount) {
            DDLogWarn("Gimbal Controller setAttitude - counter exceeds max count - aborting")

            self.delegate?.gimbalControllerAborted("Unable to set gimbal attitude")
            return
        }

        let nextCount = counter + 1

        // For aircraft gimbal positive values represent clockwise (upward) rotation and negative values represent
        // counter clockwise (downward) rotation
        // DJIGimbalRotateDirection pitchDir = pitch > 0 ? DJIGimbalRotateDirectionClockwise : DJIGimbalRotateDirectionCounterClockwise;
        // Test if we need to set - since for the Osmo it just "did the right thing (tm)"

        var pitchRotation = DJIGimbalAngleRotation()
        var yawRotation = DJIGimbalAngleRotation()
        var rollRotation = DJIGimbalAngleRotation()

        pitchRotation.enabled = ObjCBool(isPitchAdjustable)
        yawRotation.enabled = ObjCBool(isYawAdjustable)
        rollRotation.enabled = ObjCBool(isRollAdjustable)

        if (isPitchAdjustable) {
            pitchRotation.angle = pitch
        }

        if (isYawAdjustable) {
            yawRotation.angle = yaw
        }

        if (isRollAdjustable) {
            rollRotation.angle = roll
        }

        gimbal.rotateGimbalWithAngleMode(.AngleModeAbsoluteAngle, pitch: pitchRotation, roll: rollRotation, yaw: yawRotation, withCompletion: {
            (error) in

            if let e = error {
                DDLogWarn("Gimbal Controller setAttitude - error seen - \(e)")

                self.setAttitude(nextCount, pitch: pitch, yaw: yaw, roll: roll)
            }
        })

        delay(gimbal.completionTimeForControlAngleAction + 0.5) {
            if !self.check(pitch: pitch, yaw: yaw, roll: roll) {
                DDLogWarn("Gimbal Controller setAttitude hasn't completed yet count: \(counter)")

                self.setAttitude(nextCount, pitch: pitch, yaw: yaw, roll: roll)
            } else {
                DDLogDebug("Gimbal Controller setAttitude - OK")

                self.delegate?.gimbalControllerCompleted()
            }
        }
    }

    func gimbal(controller: DJIGimbal, didUpdateGimbalState gimbalState: DJIGimbalState) {
        let atti = gimbalState.attitudeInDegrees

        DDLogVerbose("Gimbal Controller didUpdateGimbalState P:\(atti.pitch) Y:\(atti.yaw) R:\(atti.roll)")

        self.currentPitch = atti.pitch
        self.currentYaw = atti.yaw
        self.currentRoll = atti.roll

        self.delegate?.gimbalAttitudeChanged?(pitch: atti.pitch, yaw: atti.yaw, roll: atti.roll)
    }

}
