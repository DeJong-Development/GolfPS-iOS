//
//  PlaySheetUITests.swift
//  PlaySheetUITests
//
//  Created by Greg DeJong on 3/16/23.
//  Copyright © 2023 DeJong Development. All rights reserved.
//

import XCTest

class UI_Screenshots: UI_Tests {
    
    override func setUpWithError() throws {
        continueAfterFailure = false

        app.launchArguments = ["testing", "NoAnimations", "screenshots"]
        app.launch()
    }
    
    func testGetScreenshots() {
        courseSelectionVC.assertExistence(withTimeout: 5)
        
        //Go to Course Selection
        app.tabBars.buttons.element(boundBy: 0).tap()
        //Wait for sheets to load
        sleep(1)
        takeScreenshot(named: "Course Selection")
        
        //get the a specific course
        
        //Go to My Bag
        app.tabBars.buttons.element(boundBy: 1).tap()
        //Wait for bag to load
        sleep(1)
        takeScreenshot(named: "My Bag")
        
        //Go to My Settings
        app.tabBars.buttons.element(boundBy: 2).tap()
        //Wait for settings to load
        sleep(1)
        takeScreenshot(named: "Settings")
    }
    
    ///Take a screenshot and save it to the local device
    ///https://blog.winsmith.de/english/ios/2020/04/14/xcuitest-screenshots.html
    public func takeScreenshot(named name: String) {
        // Take the screenshot
        let fullScreenshot = XCUIScreen.main.screenshot()
        
        // Create a new attachment to save our screenshot
        // and give it a name consisting of the "named"
        // parameter and the device name, so we can find
        // it later.
        let screenshotAttachment = XCTAttachment(
            uniformTypeIdentifier: "public.png",
            name: "Screenshot-\(UIDevice.current.name)-\(name).png",
            payload: fullScreenshot.pngRepresentation,
            userInfo: nil)
            
        // Usually Xcode will delete attachments after
        // the test has run; we don't want that!
        screenshotAttachment.lifetime = .keepAlways
        
        // Add the attachment to the test log,
        // so we can retrieve it later
        add(screenshotAttachment)
    }
}
