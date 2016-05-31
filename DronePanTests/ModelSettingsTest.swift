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

class ModelSettingsTest: XCTestCase, ModelSettings {

    let model = "TestModel"

    override func setUp() {
        super.setUp()

        let appDomain = NSBundle.mainBundle().bundleIdentifier!

        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDefaultStartDelay() {
        let value = startDelay(model)

        XCTAssertEqual(5, value, "Incorrect default start delay")
    }

    func testDefaultPhotosPerRow() {
        let value = photosPerRow(model)

        XCTAssertEqual(6, value, "Incorrect default photos per row")
    }

    func testDefaultNumberOfRows() {
        let value = numberOfRows(model)

        XCTAssertEqual(3, value, "Incorrect default number of rows")
    }

    func testDefaultMaxPitch() {
        let value = maxPitch(model)
        
        XCTAssertEqual(0, value, "Incorrect default max pitch")
        
    }
    
    func testDefaultMaxPitchEnabled() {
        let value = maxPitchEnabled(model)

        XCTAssertTrue(value, "Incorrect default max pitch enabled")
    }

    func testDefaultACGimbalYaw() {
        let value = acGimbalYaw(model)
        
        XCTAssertFalse(value, "Incorrect default ac gimbal yaw")
    }
    func testStoreStartDelay() {
        let settings: [SettingsKeys:AnyObject] = [
                .StartDelay: 10
        ]

        updateSettings(model, settings: settings)

        let value = startDelay(model)

        XCTAssertEqual(10, value, "Incorrect start delay")
    }

    func testStorePhotosPerRow() {
        let settings: [SettingsKeys:AnyObject] = [
                .PhotosPerRow: 15
        ]

        updateSettings(model, settings: settings)

        let value = photosPerRow(model)

        XCTAssertEqual(15, value, "Incorrect photos per row")
    }

    func testStoreNumberOfRows() {
        let settings: [SettingsKeys:AnyObject] = [
                .NumberOfRows: 20
        ]

        updateSettings(model, settings: settings)

        let value = numberOfRows(model)

        XCTAssertEqual(20, value, "Incorrect number of rows")
    }

    func testStoreMaxPitch() {
        let settings: [SettingsKeys:AnyObject] = [
            .MaxPitch: 30
        ]
        
        updateSettings(model, settings: settings)
        
        let value = maxPitch(model)
        
        XCTAssertEqual(30, value, "Incorrect max pitch")
    }
    
    func testStoreMaxPitchEnabled() {
        let settings: [SettingsKeys:AnyObject] = [
                .MaxPitchEnabled: true
        ]

        updateSettings(model, settings: settings)

        let value = maxPitchEnabled(model)

        XCTAssertTrue(value, "Incorrect max pitch enabled")
    }

    func testNumberOfImagesForCurrentSettingsDefault() {
        let value = numberOfImagesForCurrentSettings(model)

        XCTAssertEqual(19, value, "Incorrect default number of images")
    }

    func testNumberOfImagesForCurrentSettings() {
        let settings: [SettingsKeys:AnyObject] = [
                .NumberOfRows: 5,
                .PhotosPerRow: 12
        ]

        updateSettings(model, settings: settings)

        let value = numberOfImagesForCurrentSettings(model)

        XCTAssertEqual(61, value, "Incorrect sky row false number of images")
    }
    
    func testStoreMaxPitchNumberOfRowsOK() {
        let settings: [SettingsKeys:AnyObject] = [
            .MaxPitch: 30,
            .NumberOfRows: 5
        ]
        
        updateSettings(model, settings: settings)
        
        let value = maxPitch(model)
        
        XCTAssertEqual(30, value, "Incorrect max pitch")
        
        let rowValue = numberOfRows(model)

        XCTAssertEqual(5, rowValue, "Incorrect number of rows")
    }
    
    func testStoreMaxPitchNumberOfRowsNotOK() {
        let settings: [SettingsKeys:AnyObject] = [
            .MaxPitch: 30,
            .NumberOfRows: 3
        ]
        
        updateSettings(model, settings: settings)
        
        let value = maxPitch(model)
        
        XCTAssertEqual(30, value, "Incorrect max pitch")
        
        let rowValue = numberOfRows(model)
        
        XCTAssertEqual(4, rowValue, "Incorrect number of rows")
    }

    func testStoreACGimbalYaw() {
        let settings: [SettingsKeys:AnyObject] = [
            .ACGimbalYaw: true
        ]
        
        updateSettings(model, settings: settings)
        
        let value = acGimbalYaw(model)
        
        XCTAssertTrue(value, "Incorrect stored ac gimbal yaw")
    }
}

