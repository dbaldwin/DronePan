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

class FlightControllerDelegateAdapter: FlightControllerDelegate {
    var asyncExpectation: XCTestExpectation?

    func flightControllerUnableToYaw(reason: String) {
    }

    func flightControllerUpdateDistance(distance: CLLocationDistance) {
    }

    func flightControllerUpdateSatelliteCount(satelliteCount: Int) {
    }

    func flightControllerUpdateHeading(compassHeading: Double) {
    }

    func flightControllerUpdateAltitude(altitude: Float) {
    }

    func flightControllerUnableToSetControlMode() {
    }

    func flightControllerSetControlMode() {
    }
    
    func flightControllerDidYaw() {
    }
}

class FlightControllerSpyDelegate: FlightControllerDelegateAdapter {

    var modeSet: Bool? = .None
    var modeNotSet: Bool? = .None

    var yawFailure: String? = .None
    
    var didYaw: Bool? = .None

    override func flightControllerSetControlMode() {
        guard let expectation = asyncExpectation else {
            XCTFail("CameraControllerVideoSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        modeSet = true

        expectation.fulfill()
    }

    override func flightControllerUnableToSetControlMode() {
        guard let expectation = asyncExpectation else {
            XCTFail("CameraControllerVideoSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        modeNotSet = true

        expectation.fulfill()
    }

    override func flightControllerUnableToYaw(reason: String) {
        guard let expectation = asyncExpectation else {
            XCTFail("CameraControllerVideoSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        yawFailure = reason

        expectation.fulfill()
    }
    
    override func flightControllerDidYaw() {
        guard let expectation = asyncExpectation else {
            XCTFail("CameraControllerVideoSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        
        didYaw = true
        
        expectation.fulfill()
    }
}

class FlightControllerDistanceSpyDelegate: FlightControllerDelegateAdapter {
    var distance: CLLocationDistance? = .None

    override func flightControllerUpdateDistance(distance: CLLocationDistance) {
        guard let expectation = asyncExpectation else {
            XCTFail("CameraControllerVideoSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.distance = distance

        expectation.fulfill()
    }
}

class FlightControllerSatelliteSpyDelegate: FlightControllerDelegateAdapter {
    var satellites: Int? = .None

    override func flightControllerUpdateSatelliteCount(satelliteCount: Int) {
        guard let expectation = asyncExpectation else {
            XCTFail("CameraControllerVideoSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.satellites = satelliteCount

        expectation.fulfill()
    }
}

class FlightControllerHeadingSpyDelegate: FlightControllerDelegateAdapter {
    var heading: Double? = .None

    override func flightControllerUpdateHeading(compassHeading: Double) {
        guard let expectation = asyncExpectation else {
            XCTFail("CameraControllerVideoSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.heading = compassHeading

        expectation.fulfill()
    }
}

class FlightControllerAltitudeSpyDelegate: FlightControllerDelegateAdapter {
    var altitude: Float? = .None

    override func flightControllerUpdateAltitude(altitude: Float) {
        guard let expectation = asyncExpectation else {
            XCTFail("CameraControllerVideoSpyDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }

        self.altitude = altitude

        expectation.fulfill()
    }
}

class FlightControllerStateMock: DJIFlightControllerCurrentState {
    override var satelliteCount: Int32 {
        get {
            return 27
        }
    }

    override var altitude: Float {
        get {
            return 10.5
        }
    }

    override var homeLocation: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: 10, longitude: 10)
        }
    }

    override var aircraftLocation: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: 20, longitude: 20)
        }
    }
}

class CompassMock: DJICompass {
    override var heading: Double {
        get {
            return 12.3
        }
    }
}

class CompassProgressiveMock: DJICompass {
    var headingCount = 30.0
    
    override var heading: Double {
        get {
            self.headingCount -= 1.0
            
            return 12.3 - self.headingCount
        }
    }
}

class FlightControllerCompassMock: DJIFlightController {
    override var compass: DJICompass? {
        return CompassMock()
    }
}

class FlightControllerTests: XCTestCase {

    func testSetControlMode() {

        class FlightControllerMock: DJIFlightController {
            override func enableVirtualStickControlModeWithCompletion(completion: DJICompletionBlock?) {
                completion?(nil)
            }
        }

        let controller = FlightController(fc: FlightControllerMock())

        let spyDelegate = FlightControllerSpyDelegate()

        let expectation = expectationWithDescription("Setting control mode should succeed")
        spyDelegate.asyncExpectation = expectation

        controller.delegate = spyDelegate

        controller.setControlModes()

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let modeSet = spyDelegate.modeSet else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(modeSet, "Control mode not set")
        }
    }

    func testSetControlModeUavailable() {

        class FlightControllerMock: DJIFlightController {
            override func enableVirtualStickControlModeWithCompletion(completion: DJICompletionBlock?) {
                let error = NSError(domain: "Test", code: 1001, userInfo: nil)

                completion?(error)
            }
        }

        let controller = FlightController(fc: FlightControllerMock())

        let spyDelegate = FlightControllerSpyDelegate()

        let expectation = expectationWithDescription("Setting control mode should not succeed if FC errors")
        spyDelegate.asyncExpectation = expectation

        controller.delegate = spyDelegate

        controller.setControlModes()

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let modeNotSet = spyDelegate.modeNotSet else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertTrue(modeNotSet, "Control mode set")
        }
    }

    func testYawFailure() {

        class FlightControllerMock: DJIFlightController {
            override func isVirtualStickControlModeAvailable() -> Bool {
                return true
            }

            override func sendVirtualStickFlightControlData(controlData: DJIVirtualStickFlightControlData, withCompletion completion: DJICompletionBlock?) {
                let error = NSError(domain: "Test", code: 1001, userInfo: nil)

                completion?(error)
            }
        }


        let controller = FlightController(fc: FlightControllerMock())

        let spyDelegate = FlightControllerSpyDelegate()

        let expectation = expectationWithDescription("Yaw should not succeed if FC errors")
        spyDelegate.asyncExpectation = expectation

        controller.delegate = spyDelegate

        controller.yaw(10.0)

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let yawFailure = spyDelegate.yawFailure else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual(yawFailure, "Unable to yaw: Error Domain=Test Code=1001 \"(null)\"", "Incorrect yaw failure reason")
        }
    }
    
    func testYawTimeout() {
        
        class FlightControllerMock: DJIFlightController {
            override func isVirtualStickControlModeAvailable() -> Bool {
                return true
            }
            
            override func sendVirtualStickFlightControlData(controlData: DJIVirtualStickFlightControlData, withCompletion completion: DJICompletionBlock?) {
                self.delegate?.flightController?(self, didUpdateSystemState: FlightControllerStateMock())
            }
            
            override var compass: DJICompass? {
                get {
                    return CompassMock()
                }
            }
        }
        
        let controller = FlightController(fc: FlightControllerMock())
        
        let spyDelegate = FlightControllerSpyDelegate()
        
        let expectation = expectationWithDescription("Yaw should not succeed")
        spyDelegate.asyncExpectation = expectation
        
        controller.delegate = spyDelegate
        
        controller.yawTo(35.3)
        
        waitForExpectationsWithTimeout(6) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
            
            guard let yawFailure = spyDelegate.yawFailure else {
                XCTFail("Expected delegate to be called")
                return
            }
            
            XCTAssertEqual(yawFailure, "Yaw did not complete", "Incorrect yaw failure reason")
        }
    }

    
    func testYaw() {
        
        class FlightControllerMock: DJIFlightController {
            override func isVirtualStickControlModeAvailable() -> Bool {
                return true
            }
            
            override func sendVirtualStickFlightControlData(controlData: DJIVirtualStickFlightControlData, withCompletion completion: DJICompletionBlock?) {
                self.delegate?.flightController?(self, didUpdateSystemState: FlightControllerStateMock())
            }
            
            override var compass: DJICompass? {
                get {
                    return CompassMock()
                }
            }
        }
        
        let controller = FlightController(fc: FlightControllerMock())
        
        let spyDelegate = FlightControllerSpyDelegate()
        
        let expectation = expectationWithDescription("Yaw should succeed")
        spyDelegate.asyncExpectation = expectation
        
        controller.delegate = spyDelegate
        
        controller.yawTo(12.3)
        
        waitForExpectationsWithTimeout(6) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
            
            guard let didYaw = spyDelegate.didYaw else {
                XCTFail("Expected delegate to be called")
                return
            }
            
            XCTAssertTrue(didYaw, "Did not yaw")
        }
    }

    func testProgressiveYaw() {
        
        class FlightControllerMock: DJIFlightController {
            let testCompass = CompassProgressiveMock()
            
            override func isVirtualStickControlModeAvailable() -> Bool {
                return true
            }
            
            override func sendVirtualStickFlightControlData(controlData: DJIVirtualStickFlightControlData, withCompletion completion: DJICompletionBlock?) {
                self.delegate?.flightController?(self, didUpdateSystemState: FlightControllerStateMock())
            }
            
            override var compass: DJICompass? {
                get {
                    return testCompass
                }
            }
        }
        
        let controller = FlightController(fc: FlightControllerMock())
        
        let spyDelegate = FlightControllerSpyDelegate()
        
        let expectation = expectationWithDescription("Yaw should succeed")
        spyDelegate.asyncExpectation = expectation
        
        controller.delegate = spyDelegate
        
        controller.yawTo(12.3)
        
        waitForExpectationsWithTimeout(6) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
            
            guard let didYaw = spyDelegate.didYaw else {
                XCTFail("Expected delegate to be called")
                return
            }
            
            XCTAssertTrue(didYaw, "Did not yaw")
        }
    }
    
    
    func testAltitude() {
        let fc = DJIFlightController()

        let controller = FlightController(fc: fc)

        let spyDelegate = FlightControllerAltitudeSpyDelegate()

        let expectation = expectationWithDescription("Altitude information is passed on")
        spyDelegate.asyncExpectation = expectation

        controller.delegate = spyDelegate

        controller.flightController(fc, didUpdateSystemState: FlightControllerStateMock())

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let altitude = spyDelegate.altitude else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual(altitude, 10.5, "Incorrect altitude \(altitude)")
        }
    }

    func testSatellites() {
        let fc = DJIFlightController()

        let controller = FlightController(fc: fc)

        let spyDelegate = FlightControllerSatelliteSpyDelegate()

        let expectation = expectationWithDescription("Satellite information is passed on")
        spyDelegate.asyncExpectation = expectation

        controller.delegate = spyDelegate

        controller.flightController(fc, didUpdateSystemState: FlightControllerStateMock())

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let satellites = spyDelegate.satellites else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual(satellites, 27, "Incorrect satellites \(satellites)")
        }
    }

    func testDistance() {
        let fc = DJIFlightController()

        let controller = FlightController(fc: fc)

        let spyDelegate = FlightControllerDistanceSpyDelegate()

        let expectation = expectationWithDescription("Distance information is passed on")
        spyDelegate.asyncExpectation = expectation

        controller.delegate = spyDelegate

        controller.flightController(fc, didUpdateSystemState: FlightControllerStateMock())

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let distance = spyDelegate.distance else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual(distance, 1541856.4338872442, "Incorrect distance \(distance)")
        }
    }

    func testHeading() {
        let fc = FlightControllerCompassMock()

        let controller = FlightController(fc: fc)

        let spyDelegate = FlightControllerHeadingSpyDelegate()

        let expectation = expectationWithDescription("Heading information is passed on")
        spyDelegate.asyncExpectation = expectation

        controller.delegate = spyDelegate

        controller.flightController(fc, didUpdateSystemState: FlightControllerStateMock())

        waitForExpectationsWithTimeout(1) {
            error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let heading = spyDelegate.heading else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertEqual(heading, 12.3, "Incorrect heading \(heading)")
        }
    }
    
    /*
     Not currently in use
    func testYawSpeedForAngle() {
        let fc = FlightController(fc: DJIFlightController())
        
        XCTAssertEqual(45.0, fc.yawSpeedForAngle(60), "Incorrect yaw speed for angle")
        XCTAssertEqual(10.0, fc.yawSpeedForAngle(5.5), "Incorrect yaw speed for angle")
        XCTAssertEqual(5.0, fc.yawSpeedForAngle(2.5), "Incorrect yaw speed for angle")
        XCTAssertEqual(2.5, fc.yawSpeedForAngle(1.5), "Incorrect yaw speed for angle")
        XCTAssertEqual(1.0, fc.yawSpeedForAngle(0.5), "Incorrect yaw speed for angle")
    }
    
    func testSpeedForAngleAndHeading() {
        let fc = FlightController(fc: DJIFlightController())
        
        XCTAssertEqual(45.0, fc.getSpeed(60.0, heading: 0.0), "Incorrect speed for angle and heading")
        XCTAssertEqual(45.0, fc.getSpeed(120.0, heading: 60.0), "Incorrect speed for angle and heading")
        XCTAssertEqual(45.0, fc.getSpeed(180.0, heading: 120.0), "Incorrect speed for angle and heading")
        XCTAssertEqual(45.0, fc.getSpeed(240.0, heading: 180.0), "Incorrect speed for angle and heading")
        XCTAssertEqual(45.0, fc.getSpeed(300.0, heading: 240.0), "Incorrect speed for angle and heading")
        XCTAssertEqual(45.0, fc.getSpeed(360.0, heading: 300.0), "Incorrect speed for angle and heading")
        
        XCTAssertEqual(5.0, fc.getSpeed(60.0, heading: 57.0), "Incorrect speed for angle and heading")
        XCTAssertEqual(-5.0, fc.getSpeed(60.0, heading: 63.0), "Incorrect speed for angle and heading")
        
        XCTAssertEqual(5.0, fc.getSpeed(360.0, heading: 357.0), "Incorrect speed for angle and heading")
        XCTAssertEqual(-5.0, fc.getSpeed(360.0, heading: 3.0), "Incorrect speed for angle and heading")
        
        XCTAssertEqual(-45.0, fc.getSpeed(271.0, heading: 89.0), "Incorrect speed for angle and heading")
        XCTAssertEqual(45.0, fc.getSpeed(269.0, heading: 91.0), "Incorrect speed for angle and heading")
        
    }
 */

}
