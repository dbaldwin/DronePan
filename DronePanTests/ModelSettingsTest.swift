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

class ModelSettingsTest: XCTestCase {

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
        let value = ModelSettings.startDelay(model)

        XCTAssertEqual(5, value, "Incorrect default start delay \(value)")
    }

    func testDefaultPhotosPerRow() {
        let value = ModelSettings.photosPerRow(model)

        XCTAssertEqual(6, value, "Incorrect default photos per row \(value)")
    }

    func testDefaultNumberOfRows() {
        let value = ModelSettings.numberOfRows(model)

        XCTAssertEqual(3, value, "Incorrect default number of rows \(value)")
    }

    func testDefaultMaxPitch() {
        let value = ModelSettings.maxPitch(model)
        
        XCTAssertEqual(0, value, "Incorrect default max pitch \(value)")
        
    }
    
    func testDefaultMaxPitchEnabled() {
        let value = ModelSettings.maxPitchEnabled(model)

        XCTAssertTrue(value, "Incorrect default max pitch enabled \(value)")
    }

    func testStoreStartDelay() {
        let settings: [SettingsKeys:AnyObject] = [
                .StartDelay: 10
        ]

        ModelSettings.updateSettings(model, settings: settings)

        let value = ModelSettings.startDelay(model)

        XCTAssertEqual(10, value, "Incorrect start delay \(value)")
    }

    func testStorePhotosPerRow() {
        let settings: [SettingsKeys:AnyObject] = [
                .PhotosPerRow: 15
        ]

        ModelSettings.updateSettings(model, settings: settings)

        let value = ModelSettings.photosPerRow(model)

        XCTAssertEqual(15, value, "Incorrect photos per row \(value)")
    }

    func testStoreNumberOfRows() {
        let settings: [SettingsKeys:AnyObject] = [
                .NumberOfRows: 20
        ]

        ModelSettings.updateSettings(model, settings: settings)

        let value = ModelSettings.numberOfRows(model)

        XCTAssertEqual(20, value, "Incorrect number of rows \(value)")
    }

    func testStoreMaxPitch() {
        let settings: [SettingsKeys:AnyObject] = [
            .MaxPitch: 30
        ]
        
        ModelSettings.updateSettings(model, settings: settings)
        
        let value = ModelSettings.maxPitch(model)
        
        XCTAssertEqual(30, value, "Incorrect max pitch \(value)")
    }
    
    func testStoreMaxPitchEnabled() {
        let settings: [SettingsKeys:AnyObject] = [
                .MaxPitchEnabled: true
        ]

        ModelSettings.updateSettings(model, settings: settings)

        let value = ModelSettings.maxPitchEnabled(model)

        XCTAssertTrue(value, "Incorrect max pitch enabled \(value)")
    }

    func testNumberOfImagesForCurrentSettingsDefault() {
        let value = ModelSettings.numberOfImagesForCurrentSettings(model)

        XCTAssertEqual(19, value, "Incorrect default number of images \(value)")
    }

    func testNumberOfImagesForCurrentSettings() {
        let settings: [SettingsKeys:AnyObject] = [
                .NumberOfRows: 5,
                .PhotosPerRow: 12
        ]

        ModelSettings.updateSettings(model, settings: settings)

        let value = ModelSettings.numberOfImagesForCurrentSettings(model)

        XCTAssertEqual(61, value, "Incorrect sky row false number of images \(value)")
    }
    
    func testStoreMaxPitchNumberOfRowsOK() {
        let settings: [SettingsKeys:AnyObject] = [
            .MaxPitch: 30,
            .NumberOfRows: 5
        ]
        
        ModelSettings.updateSettings(model, settings: settings)
        
        let value = ModelSettings.maxPitch(model)
        
        XCTAssertEqual(30, value, "Incorrect max pitch \(value)")
        
        let rowValue = ModelSettings.numberOfRows(model)

        XCTAssertEqual(5, rowValue, "Incorrect number of rows \(value)")
    }
    
    func testStoreMaxPitchNumberOfRowsNotOK() {
        let settings: [SettingsKeys:AnyObject] = [
            .MaxPitch: 30,
            .NumberOfRows: 3
        ]
        
        ModelSettings.updateSettings(model, settings: settings)
        
        let value = ModelSettings.maxPitch(model)
        
        XCTAssertEqual(30, value, "Incorrect max pitch \(value)")
        
        let rowValue = ModelSettings.numberOfRows(model)
        
        XCTAssertEqual(4, rowValue, "Incorrect number of rows \(value)")
    }
}

