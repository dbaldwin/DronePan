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

@objc protocol GimbalControllerDelegate {
    func gimbalControllerCompleted()

    func gimbalControllerAborted(reason: String)
    
    func gimbalMoveOutOfRange(reason: String)
}

@objc class GimbalController: NSObject, DJIGimbalDelegate {
    let gimbal: DJIGimbal

    var delegate: GimbalControllerDelegate?
    var status : ControllerStatus = .Normal

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

    let gimbalWorkQueue = dispatch_queue_create("com.dronepan.queue.gimbal", DISPATCH_QUEUE_CONCURRENT)

    var constraints : DJIGimbalConstraints?
    
    init(gimbal: DJIGimbal) {
        self.gimbal = gimbal

        if let constraints = gimbal.getGimbalConstraints() {
            isPitchAdjustable = constraints.isPitchAdjustable
            isYawAdjustable = constraints.isYawAdjustable
            isRollAdjustable = constraints.isRollAdjustable
        } else {
            isPitchAdjustable = false
            isYawAdjustable = false
            isRollAdjustable = false
        }

        if let c = gimbal.getGimbalConstraints() {
            constraints = c
        }
        
        super.init()

        gimbal.completionTimeForControlAngleAction = 0.5
        gimbal.delegate = self
    }

    func reset() {
        self.status = .Normal

        dispatch_async(self.gimbalWorkQueue) {
            self.reset(0)
        }
    }

    func setPitch(pitch: Float) {
        if let constraints = self.constraints {
            if (!(constraints.pitchStopMin...constraints.pitchStopMax ~= pitch)) {
                self.delegate?.gimbalMoveOutOfRange("Pitch \(pitch) was out of range")
                
                return
            }
        }
        
        self.status = .Normal

        let pitchInRange = self.gimbalAngleForHeading(pitch)
        self.lastSetPitch = pitchInRange
        dispatch_async(self.gimbalWorkQueue) {
            self.setAttitude(0, pitch: pitchInRange, yaw: self.lastSetYaw, roll: self.lastSetRoll)
        }
    }

    func setYaw(yaw: Float) {
        if let constraints = self.constraints {
            if (!(constraints.yawStopMin...constraints.yawStopMax ~= yaw)) {
                self.delegate?.gimbalMoveOutOfRange("Yaw \(yaw) was out of range")
                
                return
            }
        }

        self.status = .Normal

        let yawInRange = self.gimbalAngleForHeading(yaw)
        self.lastSetYaw = yawInRange
        dispatch_async(self.gimbalWorkQueue) {
            self.setAttitude(0, pitch: self.lastSetPitch, yaw: yawInRange, roll: self.lastSetRoll)
        }
    }

    func setRoll(roll: Float) {
        if let constraints = self.constraints {
            if (!(constraints.rollStopMin...constraints.rollStopMax ~= roll)) {
                self.delegate?.gimbalMoveOutOfRange("Roll \(roll) was out of range")
                
                return
            }
        }

        self.status = .Normal

        let rollInRange = self.gimbalAngleForHeading(roll)
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

        return angleInRange * sign
    }

    private func delay(delay: Double, closure: () -> ()) {
        if (status != .Normal) {
            return
        }
        
        ControllerUtils.delay(delay, queue: self.gimbalWorkQueue, closure: closure)
    }

    private func valueInRange(adjustable: Bool, value: Float, currentValue: Float) -> Bool {
        return !adjustable || ((value - allowedOffset) ... (value + allowedOffset) ~= currentValue)
    }

    private func check(pitch p: Float, yaw y: Float, roll r: Float) -> Bool {
        return valueInRange(isPitchAdjustable, value: p, currentValue: self.currentPitch) &&
                valueInRange(isYawAdjustable, value: y, currentValue: self.currentYaw) &&
                valueInRange(isRollAdjustable, value: r, currentValue: self.currentRoll)
    }

    private func reset(counter: Int) {
        if (status != .Normal) {
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
            return
        }
        
        NSLog("Setting attitude: count \(counter), pitch \(pitch), yaw \(yaw), roll \(roll)")

        if (counter > maxCount) {
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
                NSLog("Error setting attitude on gimbal: \(e)")

                self.setAttitude(nextCount, pitch: pitch, yaw: yaw, roll: roll)
            }
        })

        delay(gimbal.completionTimeForControlAngleAction + 0.5) {
            if !self.check(pitch: pitch, yaw: yaw, roll: roll) {
                NSLog("Gimbal attitude not set count: \(counter)")

                self.setAttitude(nextCount, pitch: pitch, yaw: yaw, roll: roll)
            } else {
                self.delegate?.gimbalControllerCompleted()
            }
        }
    }

    func gimbalController(controller: DJIGimbal, didUpdateGimbalState gimbalState: DJIGimbalState) {
        let atti = gimbalState.attitudeInDegrees

        self.currentPitch = atti.pitch
        self.currentYaw = atti.yaw
        self.currentRoll = atti.roll
    }
    
}
