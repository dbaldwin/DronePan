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

import XCTest
import DJISDK

@testable import DronePan

class GimbalControllerAdapterSpyDelegate: GimbalControllerDelegate {

    func gimbalControllerCompleted() {
    }

    func gimbalMoveOutOfRange(reason: String) {
    }

    func gimbalControllerAborted(reason: String) {
    }

    func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float) {
    }
}

class GimbalControllerCompletedSpyDelegate: GimbalControllerAdapterSpyDelegate {
    var completed: Bool? = .None

    var asyncExpectation: XCTestExpectation?

    override func gimbalControllerCompleted() {
        guard let expectation = asyncExpectation else {
            XCTFail("ConnectionControllerSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        completed = true

        expectation.fulfill()
    }
}

class GimbalControllerTests: XCTestCase {
    var gimbalController: GimbalController?

    override func setUp() {
        super.setUp()

        let gimbal = DJIGimbal()

        self.gimbalController = GimbalController(gimbal: gimbal)
    }

    func compare(angle: Float, heading: Float) {
        let value = gimbalController!.gimbalAngleForHeading(heading)

        XCTAssertEqual(angle, value, "Incorrect angle \(value) for heading \(heading)")
    }

    func testGimbalAngleForHeading() {
        compare(0, heading: 0)
        compare(90, heading: 90)
        compare(180, heading: 180)
        compare(-179, heading: 181)
        compare(-90, heading: 270)
        compare(-1, heading: 359)
        compare(0, heading: 360)
        compare(-90, heading: -90)
        compare(-180, heading: -180)
        compare(179, heading: -181)
        compare(90, heading: -270)
        compare(1, heading: -359)
        compare(0, heading: 720)
        compare(0, heading: -720)
        compare(1, heading: 721)
        compare(-1, heading: -721)
        compare(-144, heading: 216)
    }

    func testInRange() {
        let value = gimbalController!.inRange(10, range: 9 ..< 11, available: true)

        XCTAssertTrue(value, "In range was out of range")
    }

    func testInRangeNotAvailable() {
        let value = gimbalController!.inRange(10, range: 9 ..< 11, available: false)

        XCTAssertFalse(value, "In range was in range when not available")
    }

    func testBelowRange() {
        let value = gimbalController!.inRange(7, range: 9 ..< 11, available: true)

        XCTAssertFalse(value, "Below range was in range")
    }

    func testBelowRangeNotAvailable() {
        let value = gimbalController!.inRange(7, range: 9 ..< 11, available: false)

        XCTAssertFalse(value, "Below range was in range when not available")
    }

    func testAboveRange() {
        let value = gimbalController!.inRange(13, range: 9 ..< 11, available: true)

        XCTAssertFalse(value, "Above range was in range")
    }

    func testAboveRangeNotAvailable() {
        let value = gimbalController!.inRange(13, range: 9 ..< 11, available: false)

        XCTAssertFalse(value, "Above range was in range when not available")
    }

    func testNoRange() {
        let value = gimbalController!.inRange(13, range: nil, available: true)

        XCTAssertFalse(value, "No range was in range")
    }

    func testValueInRange() {
        let value = gimbalController!.valueInRange(true, value: 10, currentValue: 10)

        XCTAssertTrue(value, "Value was not in range")
    }

    func testValueBelowRange() {
        let value = gimbalController!.valueInRange(true, value: 10 - gimbalController!.allowedOffset - 0.1, currentValue: 10)

        XCTAssertFalse(value, "Value was not out of range")
    }

    func testValueAboveRange() {
        let value = gimbalController!.valueInRange(true, value: 10 + gimbalController!.allowedOffset + 0.1, currentValue: 10)

        XCTAssertFalse(value, "Value was not out of range")
    }

    func testCheck() {
        gimbalController!.currentPitch = 90
        gimbalController!.currentYaw = 120
        gimbalController!.currentRoll = 110

        let value = gimbalController!.check(pitch: 9, yaw: 12, roll: 11)

        XCTAssertTrue(value, "Test gimbal has no capabilities but still checked range")

    }

    class ParamMock: DJIParamCapability {
        let supported: Bool

        init(supported: Bool) {
            self.supported = supported
        }

        override var isSupported: Bool {
            get {
                return self.supported
            }
        }
    }

    class RangeParamMock: DJIParamCapabilityMinMax {
        let supported: Bool

        init(supported: Bool) {
            self.supported = supported
        }

        override var isSupported: Bool {
            get {
                return self.supported
            }
        }

        override var max: NSNumber! {
            get {
                return 30
            }
        }

        override var min: NSNumber! {
            get {
                return -30
            }
        }
    }

    class GimbalMock: DJIGimbal {
        let testKey: String
        let supported: Bool
        let range: Bool

        init(testKey: String, supported: Bool, range: Bool = true) {
            self.testKey = testKey
            self.supported = supported
            self.range = range
        }

        override var gimbalCapability: [NSObject:AnyObject] {
            get {
                if (range) {
                    return [testKey: RangeParamMock(supported: supported)]
                } else {
                    return [testKey: ParamMock(supported: supported)]
                }
            }
        }
    }

    class StateMock: DJIGimbalState {
        let p: Float
        let r: Float
        let y: Float

        init(p: Float, r: Float, y: Float) {
            self.p = p
            self.r = r
            self.y = y
        }

        override var attitudeInDegrees: DJIGimbalAttitude {
            get {
                return DJIGimbalAttitude(pitch: p, roll: r, yaw: y)
            }
        }
    }

    func testPitchCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalKeyAdjustPitch, supported: true)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertTrue(controller.isPitchAdjustable, "Pitch was not adjustable")
        XCTAssertEqual(controller.pitchRange, -30 ... 30, "Incorrect range seen for pitch \(controller.pitchRange)")
    }

    func testNoPitchCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalKeyAdjustPitch, supported: false)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertFalse(controller.isPitchAdjustable, "Pitch was adjustable")
        XCTAssertNil(controller.pitchRange, "Range was not nil for pitch \(controller.pitchRange)")
    }

    func testYawCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalKeyAdjustYaw, supported: true)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertTrue(controller.isYawAdjustable, "Yaw was not adjustable")
        XCTAssertEqual(controller.yawRange, -30 ... 30, "Incorrect range seen for yaw \(controller.yawRange)")
    }

    func testYawCapabilitiesOverride() {
        let gimbal = GimbalMock(testKey: DJIGimbalKeyAdjustYaw, supported: true)

        let controller = GimbalController(gimbal: gimbal, supportsSDKYaw: false)

        XCTAssertFalse(controller.isYawAdjustable, "Yaw was adjustable when sdk support was set false")
        XCTAssertNil(controller.yawRange, "Range was not nil for yaw when sdk support was set false \(controller.yawRange)")
    }

    func testNoYawCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalKeyAdjustYaw, supported: false)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertFalse(controller.isYawAdjustable, "Yaw was adjustable")
        XCTAssertNil(controller.yawRange, "Range was not nil for yaw \(controller.yawRange)")
    }

    func testRollCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalKeyAdjustRoll, supported: true)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertTrue(controller.isRollAdjustable, "Roll was not adjustable")
        XCTAssertEqual(controller.rollRange, -30 ... 30, "Incorrect range seen for roll \(controller.rollRange)")
    }

    func testNoRollCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalKeyAdjustRoll, supported: false)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertFalse(controller.isRollAdjustable, "Roll was adjustable")
        XCTAssertNil(controller.rollRange, "Range was not nil for roll \(controller.rollRange)")
    }

    func testPitchExtension() {
        let gimbal = GimbalMock(testKey: DJIGimbalKeyPitchRangeExtension, supported: true, range: false)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertTrue(controller.supportsRangeExtension, "Range extension was not supported")
    }

    func testNoPitchExtension() {
        let gimbal = GimbalMock(testKey: DJIGimbalKeyPitchRangeExtension, supported: false, range: false)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertFalse(controller.supportsRangeExtension, "Range extension was supported")
    }

    func testSetACYaw() {
        let controller = GimbalController(gimbal: DJIGimbal())

        XCTAssertEqual(Float(0), controller.currentACYaw, "Initial AC yaw was not 0 \(controller.currentACYaw)")

        controller.setACYaw(Float(33.09))

        XCTAssertEqual(Float(33.09), controller.currentACYaw, "Updated AC yaw was not correct \(controller.currentACYaw)")
    }

    func testReset() {

        class GimbalAttitudeMock: DJIGimbal {
            override var gimbalCapability: [NSObject:AnyObject] {
                get {
                    return [
                            DJIGimbalKeyAdjustYaw: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustRoll: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustPitch: RangeParamMock(supported: true)
                    ]
                }
            }

            override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {

                self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 0, r: 0, y: 0))
            }
        }

        let gimbal = GimbalAttitudeMock()

        let controller = GimbalController(gimbal: gimbal)

        controller.currentPitch = 20.3
        controller.currentYaw = 19.3
        controller.currentRoll = -2.8


        let spyDelegate = GimbalControllerCompletedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Reset should complete")
        spyDelegate.asyncExpectation = expectation

        controller.reset()

        waitForExpectationsWithTimeout(1.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Reset did not complete")
            XCTAssertEqual(controller.currentYaw, 0, "Incorrect yaw after reset \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after reset \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after reset \(controller.currentPitch)")
        }

    }

    func testSlowReset() {

        class GimbalAttitudeMock: DJIGimbal {
            var firstRunComplete = false

            override var gimbalCapability: [NSObject:AnyObject] {
                get {
                    return [
                            DJIGimbalKeyAdjustYaw: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustRoll: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustPitch: RangeParamMock(supported: true)
                    ]
                }
            }

            override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {

                if (!self.firstRunComplete) {
                    firstRunComplete = true

                    // Current gimbal allowed offset is 2.5
                    self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 2.6, r: -2.6, y: 2.6))
                } else {
                    self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 0, r: 0, y: 0))
                }
            }
        }

        let gimbal = GimbalAttitudeMock()

        let controller = GimbalController(gimbal: gimbal)

        controller.currentPitch = 20.3
        controller.currentYaw = 19.3
        controller.currentRoll = -2.8


        let spyDelegate = GimbalControllerCompletedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Reset should complete")
        spyDelegate.asyncExpectation = expectation

        controller.reset()

        waitForExpectationsWithTimeout(3.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Reset did not complete")
            XCTAssertEqual(controller.currentYaw, 0, "Incorrect yaw after reset \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after reset \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after reset \(controller.currentPitch)")
        }

    }

    func testSetPitch() {

        class GimbalAttitudeMock: DJIGimbal {
            override var gimbalCapability: [NSObject:AnyObject] {
                get {
                    return [
                            DJIGimbalKeyAdjustYaw: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustRoll: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustPitch: RangeParamMock(supported: true)
                    ]
                }
            }

            override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {

                self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 15.6, r: 0, y: 0))
            }
        }

        let gimbal = GimbalAttitudeMock()

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerCompletedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set pitch should complete")
        spyDelegate.asyncExpectation = expectation

        controller.setPitch(15.6)

        waitForExpectationsWithTimeout(1.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Reset did not complete")
            XCTAssertEqual(controller.currentYaw, 0, "Incorrect yaw after set pitch \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after set pitch \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 15.6, "Incorrect pitch after set pitch \(controller.currentPitch)")
        }

    }

    func testSlowSetPitch() {

        class GimbalAttitudeMock: DJIGimbal {
            var firstRunComplete = false

            override var gimbalCapability: [NSObject:AnyObject] {
                get {
                    return [
                            DJIGimbalKeyAdjustYaw: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustRoll: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustPitch: RangeParamMock(supported: true)
                    ]
                }
            }

            override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {

                if (!self.firstRunComplete) {
                    firstRunComplete = true

                    // Current gimbal allowed offset is 2.5
                    self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 2.6, r: -2.6, y: 2.6))
                } else {
                    self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 15.6, r: 0, y: 0))
                }
            }
        }

        let gimbal = GimbalAttitudeMock()

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerCompletedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set pitch should complete")
        spyDelegate.asyncExpectation = expectation

        controller.setPitch(15.6)

        waitForExpectationsWithTimeout(3.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Reset did not complete")
            XCTAssertEqual(controller.currentYaw, 0, "Incorrect yaw after set pitch \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after set pitch \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 15.6, "Incorrect pitch after set pitch \(controller.currentPitch)")
        }

    }

    func testSetYaw() {

        class GimbalAttitudeMock: DJIGimbal {
            override var gimbalCapability: [NSObject:AnyObject] {
                get {
                    return [
                            DJIGimbalKeyAdjustYaw: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustRoll: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustPitch: RangeParamMock(supported: true)
                    ]
                }
            }

            override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {

                self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 0, r: 0, y: 15.6))
            }
        }

        let gimbal = GimbalAttitudeMock()

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerCompletedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set yaw should complete")
        spyDelegate.asyncExpectation = expectation

        controller.setYaw(15.6)

        waitForExpectationsWithTimeout(1.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Reset did not complete")
            XCTAssertEqual(controller.currentYaw, 15.6, "Incorrect yaw after set yaw \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after set yaw \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after set yaw \(controller.currentPitch)")
        }

    }

    func testSlowSetYaw() {

        class GimbalAttitudeMock: DJIGimbal {
            var firstRunComplete = false

            override var gimbalCapability: [NSObject:AnyObject] {
                get {
                    return [
                            DJIGimbalKeyAdjustYaw: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustRoll: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustPitch: RangeParamMock(supported: true)
                    ]
                }
            }

            override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {

                if (!self.firstRunComplete) {
                    firstRunComplete = true

                    // Current gimbal allowed offset is 2.5
                    self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 2.6, r: -2.6, y: 2.6))
                } else {
                    self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 0, r: 0, y: 15.6))
                }
            }
        }

        let gimbal = GimbalAttitudeMock()

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerCompletedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set yaw should complete")
        spyDelegate.asyncExpectation = expectation

        controller.setYaw(15.6)

        waitForExpectationsWithTimeout(3.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Reset did not complete")
            XCTAssertEqual(controller.currentYaw, 15.6, "Incorrect yaw after set yaw \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after set yaw \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after set yaw \(controller.currentPitch)")
        }

    }

    func testSetRoll() {

        class GimbalAttitudeMock: DJIGimbal {
            override var gimbalCapability: [NSObject:AnyObject] {
                get {
                    return [
                            DJIGimbalKeyAdjustYaw: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustRoll: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustPitch: RangeParamMock(supported: true)
                    ]
                }
            }

            override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {

                self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 0, r: 15.6, y: 0))
            }
        }

        let gimbal = GimbalAttitudeMock()

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerCompletedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set roll should complete")
        spyDelegate.asyncExpectation = expectation

        controller.setRoll(15.6)

        waitForExpectationsWithTimeout(1.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Reset did not complete")
            XCTAssertEqual(controller.currentYaw, 0, "Incorrect yaw after set roll \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 15.6, "Incorrect roll after set roll \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after set roll \(controller.currentPitch)")
        }

    }

    func testSlowSetRoll() {

        class GimbalAttitudeMock: DJIGimbal {
            var firstRunComplete = false

            override var gimbalCapability: [NSObject:AnyObject] {
                get {
                    return [
                            DJIGimbalKeyAdjustYaw: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustRoll: RangeParamMock(supported: true),
                            DJIGimbalKeyAdjustPitch: RangeParamMock(supported: true)
                    ]
                }
            }

            override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {

                if (!self.firstRunComplete) {
                    firstRunComplete = true

                    // Current gimbal allowed offset is 2.5
                    self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 2.6, r: -2.6, y: 2.6))
                } else {
                    self.delegate?.gimbal!(self, didUpdateGimbalState: StateMock(p: 0, r: 15.6, y: 0))
                }
            }
        }

        let gimbal = GimbalAttitudeMock()

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerCompletedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set roll should complete")
        spyDelegate.asyncExpectation = expectation

        controller.setRoll(15.6)

        waitForExpectationsWithTimeout(3.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let completed = spyDelegate.completed else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(completed, "Reset did not complete")
            XCTAssertEqual(controller.currentYaw, 0, "Incorrect yaw after set roll \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 15.6, "Incorrect roll after set roll \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after set roll \(controller.currentPitch)")
        }

    }
}

