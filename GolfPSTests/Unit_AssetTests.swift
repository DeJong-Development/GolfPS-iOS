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
        XCTAssertNotNil(UIImage(named: "compass_black"))
        XCTAssertNil(NSDataAsset(name: "not_a_real_image"))
        XCTAssertNil(UIImage(named: "not_a_real_image"))
    }
    
    func testBackgroundAssets() throws {
        XCTAssertNotNil(UIImage(named: "golf_splash"))
       
    }
    
    func testStateAssets() throws {
        XCTAssertNotNil(UIImage(named: "noun_California_3180613"))
    }
    
}
