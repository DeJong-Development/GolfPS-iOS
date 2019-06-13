//
//  ClubTools.swift
//  GolfPS
//
//  Created by Greg DeJong on 4/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import Foundation

class ClubTools {
    
    let preferences = UserDefaults.standard
    var myClubs:[Club] = [Club]()
    
    init() {
        for i in 1..<14 {
            myClubs.append(Club(number: i));
        }
    }
    
    public func getClubSuggestion(ydsTo: Int) -> Club {
        var avgDistances:[Int] = [Int]()
        
        for c in myClubs {
            avgDistances.append(c.distance)
        }
        
        var clubNum:Int = 0;
        while (ydsTo < avgDistances[clubNum] && clubNum < 12) { clubNum += 1; } //iterate until we hit the appropriate club
        
        return myClubs[clubNum]
    }
}
