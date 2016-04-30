//
//  DronePanUITests.swift
//  DronePanUITests
//
//  Created by Chris Searle on 30/04/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

import XCTest

class DronePanUITests: XCTestCase {
        
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        app.launch()
    }
    
    func testDisconnectedAtStart() {
        XCTAssert(app.staticTexts["Disconnected"].exists, "Couldn't find disconnected text")
        XCTAssert(app.buttons["Settings2"].exists, "Couldn't find settings button")
    }
}
