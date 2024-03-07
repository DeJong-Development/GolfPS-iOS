//
//  Created by Greg DeJong on 5/20/21.
//

import XCTest

class Unit_AssetTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
    
    func testIconAssets() throws {
        XCTAssertNotNil(UIImage(named: "calendar"))
        XCTAssertNotNil(UIImage(named: "close"))
        XCTAssertNotNil(UIImage(named: "double_chevron_right"))
        XCTAssertNotNil(UIImage(named: "draw"))
        XCTAssertNotNil(UIImage(named: "duplicate"))
        XCTAssertNotNil(UIImage(named: "edit"))
        XCTAssertNotNil(UIImage(named: "eye"))
        XCTAssertNotNil(UIImage(named: "gear"))
        XCTAssertNotNil(UIImage(named: "graph"))
        XCTAssertNotNil(UIImage(named: "location"))
        XCTAssertNotNil(UIImage(named: "trash"))
        XCTAssertNotNil(UIImage(named: "trophy"))
        XCTAssertNil(NSDataAsset(name: "not_a_real_image"))
        XCTAssertNil(UIImage(named: "not_a_real_image"))
    }
    
    func testBackgroundAssets() throws {
        XCTAssertNotNil(UIImage(named: "Dashboard"))
        XCTAssertNotNil(UIImage(named: "Splash"))
       
    }
    
    func testImageAssets() throws {
        XCTAssertNotNil(UIImage(named: "PLAYSHEET"))
        XCTAssertNotNil(UIImage(named: "LIVE"))
        XCTAssertNotNil(UIImage(named: "basic_football"))
        XCTAssertNotNil(UIImage(named: "google_g"))
    }
    
}
