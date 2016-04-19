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

    func testDefaultSkyRow() {
        let value = ModelSettings.skyRow(model)
        
        XCTAssertFalse(value, "Incorrect default sky row \(value)")
    }
    
    func testStoreStartDelay() {
        let settings : [SettingsKeys : AnyObject] = [
            .StartDelay : 10
        ]
        
        ModelSettings.updateSettings(model, settings: settings)
        
        let value = ModelSettings.startDelay(model)
        
        XCTAssertEqual(10, value, "Incorrect start delay \(value)")
    }

    func testStorePhotosPerRow() {
        let settings : [SettingsKeys : AnyObject] = [
            .PhotosPerRow : 15
        ]
        
        ModelSettings.updateSettings(model, settings: settings)
        
        let value = ModelSettings.photosPerRow(model)
        
        XCTAssertEqual(15, value, "Incorrect photos per row \(value)")
    }

    func testStoreNumberOfRows() {
        let settings : [SettingsKeys : AnyObject] = [
            .NumberOfRows : 20
        ]
        
        ModelSettings.updateSettings(model, settings: settings)
        
        let value = ModelSettings.numberOfRows(model)
        
        XCTAssertEqual(20, value, "Incorrect number of rows \(value)")
    }

    func testStoreSkyRow() {
        let settings : [SettingsKeys : AnyObject] = [
            .SkyRow : true
        ]
        
        ModelSettings.updateSettings(model, settings: settings)
        
        let value = ModelSettings.skyRow(model)
        
        XCTAssertTrue(value, "Incorrect sky row \(value)")
    }
}

