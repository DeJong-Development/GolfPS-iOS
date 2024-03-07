//
//  GolfPSUITests.swift
//  GolfPSUITests
//
//  Created by Greg DeJong on 3/16/23.
//  Copyright © 2023 DeJong Development. All rights reserved.
//

import XCTest

extension XCUIElement {
    var isOn: Bool {
        (value as? String) == "1"
    }
}

extension XCUIElement {
    func clearAndEnter(text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        self.tap()

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)

        self.typeText(deleteString)
        self.typeText(text)
    }
    
    func selectAllClearAndEnter(text: String) {
        tap()
        tap() //When there is some text, its parts can be selected on the first tap, the second tap clears the selection
        press(forDuration: 1.0)
        let selectAll = XCUIApplication().menuItems["Select All"]
        //For empty fields there will be no "Select All", so we need to check
        if selectAll.waitForExistence(timeout: 0.5), selectAll.exists {
            selectAll.tap()
            typeText(String(XCUIKeyboardKey.delete.rawValue))
        }
        typeText(text)
    }
    
    func assertExistence(withTimeout timeout: Double, shouldExist: Bool = true) {
        if !shouldExist && self.exists {
            XCTFail("view should not exist")
        }
        
        //wait for the element to exist or not exist
        let doesExist = self.waitForExistence(timeout: timeout)
        if (shouldExist) {
            XCTAssertTrue(doesExist)
        } else {
            XCTAssertFalse(doesExist)
        }
    }
}

class UI_Tests: XCTestCase {
    
    let app = XCUIApplication()
    
    lazy var courseSelectionVC = app.otherElements["CourseSelectionViewController"]
    lazy var myBagVC = app.otherElements["MyBagViewController"]
    lazy var profileVC = app.otherElements["SettingsViewController"]
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app.launchArguments = ["testing", "NoAnimations"]
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    // -------- SHARED FUNCTIONS --------- //
    //Can these be converted into extensions?
    
    public func scrollToLast(collectionView cv:XCUIElement) -> XCUIElement? {
        let totalUserCount = cv.cells.count - 1
        let lastCell = cv.cells.element(boundBy: totalUserCount)
        
        return scroll(collectionView: cv, toFindCellWithId: lastCell.identifier)
    }
    
    public func scroll(collectionView cv:XCUIElement, toFindCellWithId identifier:String) -> XCUIElement? {
        guard cv.elementType == .collectionView else {
            fatalError("XCUIElement is not a collectionView.")
        }
  
        var reachedTheEnd = false
        var allVisibleElements = [String]()
        
        let cellToFind = cv.cells[identifier]
        
        while !reachedTheEnd {
            
            // Did we find our cell ?
            if cellToFind.exists {
                return cellToFind
            }
 
            // If not: we store the list of all the elements we've got in the CollectionView
            let allElements = cv.cells.allElementsBoundByIndex.map({$0.identifier})
            
            // Did we read then end of the CollectionView ?
            // i.e: do we have the same elements visible than before scrolling ?
            reachedTheEnd = (allElements == allVisibleElements)
            allVisibleElements = allElements
            
//            reachedTheEnd = lastCell.exists
            
            // Then, we do a scroll up on the scrollview
            let startCoordinate = cv.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
            let endCoordinate = cv.coordinate(withNormalizedOffset:CGVector(dx: 0.4, dy: 0.5))
            startCoordinate.press(forDuration: 0.01, thenDragTo: endCoordinate)
        }
        return nil
    }
    
    public func dismissKeyboardIfPresent() {
        guard app.keyboards.element(boundBy: 0).exists else {
            return
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            app.keyboards.buttons["Hide keyboard"].tap()
        } else {
            app.swipeDown()
        }
    }
    
}
