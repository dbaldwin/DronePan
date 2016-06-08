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
                        DJIGimbalKeyAdjustYaw: RangeParamMock(supported: true),
                        DJIGimbalKeyAdjustRoll: RangeParamMock(supported: true),
                        DJIGimbalKeyAdjustPitch: RangeParamMock(supported: true)
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
                        DJIGimbalKeyAdjustYaw: RangeParamMock(supported: true),
                        DJIGimbalKeyAdjustRoll: RangeParamMock(supported: true),
                        DJIGimbalKeyAdjustPitch: RangeParamMock(supported: true)
                ]
            }
        }

        override func rotateGimbalWithAngleMode(angleMode: DJIGimbalRotateAngleMode, pitch: DJIGimbalAngleRotation, roll: DJIGimbalAngleRotation, yaw: DJIGimbalAngleRotation, withCompletion block: DJICompletionBlock?) {
            let error = NSError(domain: "Test", code: 1001, userInfo: nil)
            block?(error)
        }
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
