//
//  MainViewControllerTests.swift
//  DronePan
//
//  Created by Chris Searle on 18/05/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

import XCTest

@testable import DronePan


class MainViewControllerTests: XCTestCase {
    var viewController : MainViewController!
    
    // Need to run some different things before building view - so can't be in setup
    func buildView() {
        let storyboard = UIStoryboard(name: "Main",
                                      bundle: NSBundle.mainBundle())
        viewController = storyboard.instantiateInitialViewController() as! MainViewController
        
        UIApplication.sharedApplication().keyWindow!.rootViewController = viewController
        
        // The One Weird Trick!
        let _ = viewController.view
    }
    
    func testDefaultInit() {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "infoOverride")

        buildView()
        
        XCTAssertFalse(viewController.rcInFMode, "RC was in F mode at startup")
        
        [viewController.sequenceLabel, viewController.batteryLabel, viewController.altitudeLabel, viewController.satelliteLabel, viewController.distanceLabel].forEach { (label) in
            XCTAssertTrue(label.hidden, "Label \(label.text) was visible at startup")
        }
        
        XCTAssertEqual(viewController.warningView.alpha, 0, "Warning view was visible at start")
        XCTAssertEqual(viewController.warningOffset.constant, 0, "Warning view was onscreen at start")

        XCTAssertEqual(viewController.infoView.alpha, 0, "Info view was visible at start")
        XCTAssertEqual(viewController.infoOffset.constant, 0, "Info view was onscreen at start")
    }
    
    func testInfoInit() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "infoOverride")
        
        buildView()
        
        XCTAssertEqual(viewController.infoView.alpha, 1, "Info view was not visible at start")
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            XCTAssertEqual(self.viewController.infoOffset.constant, -self.viewController.infoView.frame.size.height, "Info view was offscreen at start")
        }
    }
}

