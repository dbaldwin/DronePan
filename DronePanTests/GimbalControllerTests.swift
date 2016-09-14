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

    func gimbalControllerStopped() {
    }
    
    func gimbalMaxPitchSeen(pitch: Int) {
    }
}

class GimbalControllerCompletedSpyDelegate: GimbalControllerAdapterSpyDelegate {
    var completed: Bool? = .None

    var asyncExpectation: XCTestExpectation?

    override func gimbalControllerCompleted() {
        guard let expectation = asyncExpectation else {
            XCTFail("GimbalControllerCompletedSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        completed = true

        expectation.fulfill()
    }
}

class GimbalControllerAbortedSpyDelegate: GimbalControllerAdapterSpyDelegate {
    var aborted: Bool? = .None
    var reason: String? = .None

    var asyncExpectation: XCTestExpectation?

    override func gimbalControllerCompleted() {
        XCTFail("Completed when expecting abort")
    }

    override func gimbalControllerAborted(reason: String) {
        guard let expectation = asyncExpectation else {
            XCTFail("GimbalControllerAbortedSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.aborted = true
        self.reason = reason

        expectation.fulfill()
    }
}

class GimbalControllerRangeSpyDelegate: GimbalControllerAdapterSpyDelegate {
    var aborted: Bool? = .None
    var reason: String? = .None

    var asyncExpectation: XCTestExpectation?

    override func gimbalMoveOutOfRange(reason: String) {
        guard let expectation = asyncExpectation else {
            XCTFail("GimbalControllerRangeSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.aborted = true
        self.reason = reason

        expectation.fulfill()
    }
}

class GimbalControllerStoppedSpyDelegate: GimbalControllerAdapterSpyDelegate {
    var stopped: Bool? = .None

    var asyncExpectation: XCTestExpectation?

    override func gimbalControllerCompleted() {
        XCTFail("Completed when expecting stop")
    }

    override func gimbalControllerStopped() {
        guard let expectation = asyncExpectation else {
            XCTFail("GimbalControllerStoppedSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.stopped = true

        expectation.fulfill()
    }
}

class GimbalControllerAttitudeSpyDelegate: GimbalControllerAdapterSpyDelegate {

    var pitch: Float? = .None
    var roll: Float? = .None
    var yaw: Float? = .None

    var asyncExpectation: XCTestExpectation?

    override func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float) {
        guard let expectation = asyncExpectation else {
            XCTFail("GimbalControllerAttitudeSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw

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

    class GimbalAttitudeMock: DJIGimbal {
        let firstState: DJIGimbalState
        let secondState: DJIGimbalState

        var firstStateRun = false

        init(first: DJIGimbalState, second: DJIGimbalState) {
            firstState = first
            secondState = second
        }

        override var gimbalCapability: [NSObject:AnyObject] {
            get {
                return [
                        DJIGimbalParamAdjustYaw: RangeParamMock(supported: true),
                        DJIGimbalParamAdjustRoll: RangeParamMock(supported: true),
                        DJIGimbalParamAdjustPitch: RangeParamMock(supported: true)
                ]
            }
        }

        override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {

            if !firstStateRun {
                firstStateRun = true

                self.delegate?.gimbal?(self, didUpdateGimbalState: firstState)
            } else {
                self.delegate?.gimbal?(self, didUpdateGimbalState: secondState)
            }
        }
    }


    class GimbalErrorMock: DJIGimbal {
        override var gimbalCapability: [NSObject:AnyObject] {
            get {
                return [
                        DJIGimbalParamAdjustYaw: RangeParamMock(supported: true),
                        DJIGimbalParamAdjustRoll: RangeParamMock(supported: true),
                        DJIGimbalParamAdjustPitch: RangeParamMock(supported: true)
                ]
            }
        }

        override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {
            let error = NSError(domain: "Test", code: 1001, userInfo: nil)
            block?(error)
        }
    }

    func testPitchCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalParamAdjustPitch, supported: true)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertTrue(controller.isPitchAdjustable, "Pitch was not adjustable")
        XCTAssertEqual(controller.pitchRange, -30 ... 30, "Incorrect range seen for pitch \(controller.pitchRange)")
    }

    func testNoPitchCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalParamAdjustPitch, supported: false)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertFalse(controller.isPitchAdjustable, "Pitch was adjustable")
        XCTAssertNil(controller.pitchRange, "Range was not nil for pitch \(controller.pitchRange)")
    }

    func testYawCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalParamAdjustYaw, supported: true)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertTrue(controller.isYawAdjustable, "Yaw was not adjustable")
        XCTAssertEqual(controller.yawRange, -30 ... 30, "Incorrect range seen for yaw \(controller.yawRange)")
    }

    func testYawCapabilitiesRelative() {
        let gimbal = GimbalMock(testKey: DJIGimbalParamAdjustYaw, supported: true)

        let controller = GimbalController(gimbal: gimbal, gimbalYawIsRelativeToAircraft: true)

        XCTAssertTrue(controller.isYawAdjustable, "Yaw was not adjustable")
        XCTAssertEqual(controller.yawRange, -30 ... 30, "Incorrect range seen for yaw \(controller.yawRange)")
    }

    func testNoYawCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalParamAdjustYaw, supported: false)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertFalse(controller.isYawAdjustable, "Yaw was adjustable")
        XCTAssertNil(controller.yawRange, "Range was not nil for yaw \(controller.yawRange)")
    }

    func testRollCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalParamAdjustRoll, supported: true)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertTrue(controller.isRollAdjustable, "Roll was not adjustable")
        XCTAssertEqual(controller.rollRange, -30 ... 30, "Incorrect range seen for roll \(controller.rollRange)")
    }

    func testNoRollCapabilities() {
        let gimbal = GimbalMock(testKey: DJIGimbalParamAdjustRoll, supported: false)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertFalse(controller.isRollAdjustable, "Roll was adjustable")
        XCTAssertNil(controller.rollRange, "Range was not nil for roll \(controller.rollRange)")
    }

    func testPitchExtension() {
        let gimbal = GimbalMock(testKey: DJIGimbalParamPitchRangeExtensionEnabled, supported: true, range: false)

        let controller = GimbalController(gimbal: gimbal)

        XCTAssertTrue(controller.supportsRangeExtension, "Range extension was not supported")
    }

    func testNoPitchExtension() {
        let gimbal = GimbalMock(testKey: DJIGimbalParamPitchRangeExtensionEnabled, supported: false, range: false)

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
        let state = StateMock(p: 0, r: 0, y: 0)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

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

    func testResetRelative() {
        // GC works with 0-360 AC yaw but -180-180 Gimbal yaw - so - this test should pass by setting the gimbal to the same angle
        // as the aircraft but adjusted to those ranges
        let acYaw = Float(230)
        let gimbalYaw = Float(-130)

        let state = StateMock(p: 0, r: 0, y: gimbalYaw)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal, gimbalYawIsRelativeToAircraft: true)

        controller.currentPitch = 20.3
        controller.currentYaw = 19.3
        controller.currentRoll = -2.8
        controller.setACYaw(acYaw)

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
            XCTAssertEqual(controller.currentYaw, gimbalYaw, "Incorrect yaw after reset \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after reset \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after reset \(controller.currentPitch)")
        }

    }

    func testSlowReset() {
        let state1 = StateMock(p: 2.6, r: -2.6, y: 2.6)
        let state2 = StateMock(p: 0, r: 0, y: 0)

        let gimbal = GimbalAttitudeMock(first: state1, second: state2)

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

    func testTooSlowReset() {

        let state = StateMock(p: 2.6, r: -2.6, y: 2.6)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal)

        controller.currentPitch = 20.3
        controller.currentYaw = 19.3
        controller.currentRoll = -2.8


        let spyDelegate = GimbalControllerAbortedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Reset should give up")
        spyDelegate.asyncExpectation = expectation

        controller.reset()

        waitForExpectationsWithTimeout(7.5) {
            error in

            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Reset did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called with reason")
                return
            }

            XCTAssertEqual("Unable to set gimbal attitude", reason, "Incorrect reason given \(reason)")
        }

    }

    func testErrorReset() {

        let gimbal = GimbalErrorMock()

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerAbortedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Reset should abort on error")
        spyDelegate.asyncExpectation = expectation

        controller.reset()

        waitForExpectationsWithTimeout(1.5) {
            error in

            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Reset did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called with reason")
                return
            }

            XCTAssertEqual("Unable to set gimbal attitude", reason, "Incorrect reason given \(reason)")
        }
    }

    func testResetStopping() {

        let state = StateMock(p: 0, r: 0, y: 0)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerStoppedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Reset should not complete if stopping")
        spyDelegate.asyncExpectation = expectation

        controller.reset()
        controller.status = .Stopping

        waitForExpectationsWithTimeout(3) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let stopped = spyDelegate.stopped else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(stopped, "Reset completed while stopping")
        }
    }

    func testSetPitch() {
        let state = StateMock(p: 15.6, r: 10, y: -10)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal)

        controller.lastSetYaw = -10
        controller.lastSetRoll = 10

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

            XCTAssertTrue(completed, "Set pitch did not complete")
            XCTAssertEqual(controller.currentYaw, -10, "Incorrect yaw after set pitch \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 10, "Incorrect roll after set pitch \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 15.6, "Incorrect pitch after set pitch \(controller.currentPitch)")
        }

    }

    func testSlowSetPitch() {
        let state1 = StateMock(p: 2.6, r: -2.6, y: 2.6)
        let state2 = StateMock(p: 15.6, r: 0, y: 0)

        let gimbal = GimbalAttitudeMock(first: state1, second: state2)

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

            XCTAssertTrue(completed, "Set pitch did not complete")
            XCTAssertEqual(controller.currentYaw, 0, "Incorrect yaw after set pitch \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after set pitch \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 15.6, "Incorrect pitch after set pitch \(controller.currentPitch)")
        }

    }

    func testTooSlowSetPitch() {

        let state = StateMock(p: 2.6, r: -2.6, y: 2.6)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerAbortedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set pitch should abort")
        spyDelegate.asyncExpectation = expectation

        controller.setPitch(15.6)

        waitForExpectationsWithTimeout(7.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Set pitch did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual("Unable to set gimbal attitude", reason, "Incorrect reason given \(reason)")
        }
    }

    func testErrorPitch() {

        let gimbal = GimbalErrorMock()

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerAbortedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Pitch should abort on error")
        spyDelegate.asyncExpectation = expectation

        controller.setPitch(0)

        waitForExpectationsWithTimeout(1.5) {
            error in

            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Pitch did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called with reason")
                return
            }

            XCTAssertEqual("Unable to set gimbal attitude", reason, "Incorrect reason given \(reason)")
        }
    }

    func testPitchStopping() {
        let state = StateMock(p: 0, r: 0, y: 0)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerStoppedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set pitch should not complete if stopping")
        spyDelegate.asyncExpectation = expectation

        controller.setPitch(0)
        controller.status = .Stopping

        waitForExpectationsWithTimeout(3) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let stopped = spyDelegate.stopped else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(stopped, "Set pitch completed while stopping")
        }
    }

    func testSetYaw() {
        let state = StateMock(p: 0, r: 0, y: 15.6)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

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

            XCTAssertTrue(completed, "Set yaw did not complete")
            XCTAssertEqual(controller.currentYaw, 15.6, "Incorrect yaw after set yaw \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after set yaw \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after set yaw \(controller.currentPitch)")
        }

    }

    func testSetYawRelative() {
        // GC works with 0-360 AC yaw but -180-180 Gimbal yaw - so - this test should pass by setting the gimbal to the same angle
        // as the aircraft but adjusted to those ranges
        let acYaw = Float(230)
        let gimbalYaw = Float(-130 - 15.6)

        let state = StateMock(p: 0, r: 0, y: gimbalYaw)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal, gimbalYawIsRelativeToAircraft: true)

        let spyDelegate = GimbalControllerCompletedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set yaw should complete")
        spyDelegate.asyncExpectation = expectation

        controller.setACYaw(acYaw)

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

            XCTAssertTrue(completed, "Set yaw did not complete")
            XCTAssertEqual(controller.currentYaw, gimbalYaw, "Incorrect yaw after set yaw \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after set yaw \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after set yaw \(controller.currentPitch)")
        }

    }

    func testSlowSetYaw() {
        let state1 = StateMock(p: 2.6, r: -2.6, y: 2.6)
        let state2 = StateMock(p: 0, r: 0, y: 15.6)

        let gimbal = GimbalAttitudeMock(first: state1, second: state2)

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

            XCTAssertTrue(completed, "Set yaw did not complete")
            XCTAssertEqual(controller.currentYaw, 15.6, "Incorrect yaw after set yaw \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 0, "Incorrect roll after set yaw \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after set yaw \(controller.currentPitch)")
        }

    }

    func testTooSlowSetYaw() {
        let state = StateMock(p: 2.6, r: -2.6, y: 2.6)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerAbortedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set yaw should abort")
        spyDelegate.asyncExpectation = expectation

        controller.setYaw(15.6)

        waitForExpectationsWithTimeout(7.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Set yaw did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual("Unable to set gimbal attitude", reason, "Incorrect reason given \(reason)")
        }

    }

    func testErrorYaw() {

        let gimbal = GimbalErrorMock()

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerAbortedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Yaw should abort on error")
        spyDelegate.asyncExpectation = expectation

        controller.setYaw(0)

        waitForExpectationsWithTimeout(1.5) {
            error in

            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Yaw did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called with reason")
                return
            }

            XCTAssertEqual("Unable to set gimbal attitude", reason, "Incorrect reason given \(reason)")
        }
    }

    func testYawStopping() {

        let state = StateMock(p: 0, r: 0, y: 0)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerStoppedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set yaw should not complete if stopping")
        spyDelegate.asyncExpectation = expectation

        controller.setYaw(0)
        controller.status = .Stopping

        waitForExpectationsWithTimeout(3) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let stopped = spyDelegate.stopped else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(stopped, "Set yaw completed while stopping")
        }
    }

    func testSetRoll() {
        let state = StateMock(p: 0, r: 15.6, y: 0)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

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

            XCTAssertTrue(completed, "Set roll did not complete")
            XCTAssertEqual(controller.currentYaw, 0, "Incorrect yaw after set roll \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 15.6, "Incorrect roll after set roll \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after set roll \(controller.currentPitch)")
        }

    }

    func testSlowSetRoll() {
        let state1 = StateMock(p: 2.6, r: -2.6, y: 2.6)
        let state2 = StateMock(p: 0, r: 15.6, y: 0)

        let gimbal = GimbalAttitudeMock(first: state1, second: state2)

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

            XCTAssertTrue(completed, "Set roll did not complete")
            XCTAssertEqual(controller.currentYaw, 0, "Incorrect yaw after set roll \(controller.currentYaw)")
            XCTAssertEqual(controller.currentRoll, 15.6, "Incorrect roll after set roll \(controller.currentRoll)")
            XCTAssertEqual(controller.currentPitch, 0, "Incorrect pitch after set roll \(controller.currentPitch)")
        }

    }

    func testTooSlowSetRoll() {
        let state = StateMock(p: 2.6, r: -2.6, y: 2.6)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerAbortedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set roll should abort")
        spyDelegate.asyncExpectation = expectation

        controller.setRoll(15.6)

        waitForExpectationsWithTimeout(7.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Set roll did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual("Unable to set gimbal attitude", reason, "Incorrect reason given \(reason)")
        }
    }

    func testErrorRoll() {

        let gimbal = GimbalErrorMock()

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerAbortedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Roll should abort on error")
        spyDelegate.asyncExpectation = expectation

        controller.setRoll(0)

        waitForExpectationsWithTimeout(1.5) {
            error in

            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Roll did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called with reason")
                return
            }

            XCTAssertEqual("Unable to set gimbal attitude", reason, "Incorrect reason given \(reason)")
        }
    }

    func testRollStopping() {

        let state = StateMock(p: 0, r: 0, y: 0)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerStoppedSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Set roll should not complete if stopping")
        spyDelegate.asyncExpectation = expectation

        controller.setRoll(0)
        controller.status = .Stopping

        waitForExpectationsWithTimeout(3) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let stopped = spyDelegate.stopped else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(stopped, "Set roll completed while stopping")
        }
    }

    func testPitchRange() {
        let controller = GimbalController(gimbal: DJIGimbal())

        let spyDelegate = GimbalControllerRangeSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Pitch range should error")
        spyDelegate.asyncExpectation = expectation

        controller.setPitch(200)

        waitForExpectationsWithTimeout(1.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Set pitch out of range did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual("Pitch -160.0 was out of range", reason, "Incorrect reason given \(reason)")
        }
    }

    func testYawRange() {
        let controller = GimbalController(gimbal: DJIGimbal())

        let spyDelegate = GimbalControllerRangeSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Yaw range should error")
        spyDelegate.asyncExpectation = expectation

        controller.setYaw(210)

        waitForExpectationsWithTimeout(1.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Set yaw out of range did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual("Yaw -150.0 was out of range", reason, "Incorrect reason given \(reason)")
        }
    }

    func testRollRange() {
        let controller = GimbalController(gimbal: DJIGimbal())

        let spyDelegate = GimbalControllerRangeSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Roll range should error")
        spyDelegate.asyncExpectation = expectation

        controller.setRoll(-200)

        waitForExpectationsWithTimeout(1.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let aborted = spyDelegate.aborted else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(aborted, "Set roll out of range did not abort")

            guard let reason = spyDelegate.reason else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual("Roll 160.0 was out of range", reason, "Incorrect reason given \(reason)")
        }
    }

    func testAttitude() {
        let state = StateMock(p: 0, r: 0, y: 0)

        let gimbal = GimbalAttitudeMock(first: state, second: state)

        let controller = GimbalController(gimbal: gimbal)

        let spyDelegate = GimbalControllerAttitudeSpyDelegate()
        controller.delegate = spyDelegate

        let expectation = expectationWithDescription("Attitude information should be passed on")
        spyDelegate.asyncExpectation = expectation

        let targetState = StateMock(p: 12.3, r: 45.6, y: -78.9)

        controller.gimbal(gimbal, didUpdateGimbalState: targetState)

        waitForExpectationsWithTimeout(1.5) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let pitch = spyDelegate.pitch, roll = spyDelegate.roll, yaw = spyDelegate.yaw else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual(12.3, pitch, "Incorrect pitch seen \(pitch)")
            XCTAssertEqual(45.6, roll, "Incorrect roll seen \(roll)")
            XCTAssertEqual(-78.9, yaw, "Incorrect yaw seen \(yaw)")
        }
    }
}
