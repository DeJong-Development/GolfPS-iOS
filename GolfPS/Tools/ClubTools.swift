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
    
    public func getClubName(clubNum i:Int) -> String {
        var clubName:String = "";
        switch (i) {
        case 1: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "Driver"; break;
        case 2: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "5 Wood"; break;
        case 3: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "3 Wood"; break;
        case 4: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "3 Iron"; break;
        case 5: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "4 Iron"; break;
        case 6: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "5 Iron"; break;
        case 7: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "6 Iron"; break;
        case 8: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "7 Iron"; break;
        case 9: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "8 Iron"; break;
        case 10: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "9 Iron"; break;
        case 11: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "Pitching Wedge"; break;
        case 12: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "Gap Wedge"; break;
        case 13: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "Sand Wedge"; break;
        case 14: clubName = self.preferences.string(forKey: "clubname\(i)") ?? "Putter"; break;
        default: break;
        }
        return clubName;
    }
    
    public func getClubDistance(num:Int) -> Int {
        var distance:Int = 275;
        
        if (self.preferences.value(forKey: "clubdistance\(num)") != nil) {
            distance = self.preferences.integer(forKey: "clubdistance\(num)")
        } else {
            switch (num) {
            case 1: distance = 250; break;
            case 2: distance = 230; break;
            case 3: distance = 220; break;
            case 4: distance = 205; break;
            case 5: distance = 192; break;
            case 6: distance = 184; break;
            case 7: distance = 173; break;
            case 8: distance = 164; break;
            case 9: distance = 156; break;
            case 10: distance = 140; break;
            case 11: distance = 130; break;
            case 12: distance = 110; break;
            case 13: distance = 80; break;
            case 14: distance = 5; break;
            default: distance = 275; break;
            }
        }
        
        return distance
    }
    
    public func getClubSuggestionNum(ydsTo: Int) -> Int {
        var avgDistances:[Int] = [Int]()
        var distance:Int = -1;
        
        for i in 1..<14 {
            distance = getClubDistance(num: i);
            avgDistances.append(distance)
        }
        
        var clubNum:Int = 0;
        while (ydsTo < avgDistances[clubNum] && clubNum < 12) { clubNum += 1; } //iterate until we hit the appropriate club
        return (clubNum + 1) //driver is club 1 not club 0
    }
    
    public func getClubSuggestion(ydsTo: Int) -> String {
        var clubNames:[String] = [String]();
        var clubName:String = "";
        
        for i in 1..<14 {
            clubName = getClubName(clubNum: i)
            clubNames.append(clubName);
        }
        
        let clubNum = getClubSuggestionNum(ydsTo: ydsTo)
        return clubNames[clubNum - 1];
    }
    
    public func saveClubName(name:String, number:Int) {
        self.preferences.set(name, forKey: "clubname\(number)")
        self.preferences.synchronize()
    }
    public func saveClubDistance(distance:Int, number:Int) {
        self.preferences.set(distance, forKey: "clubdistance\(number)")
        self.preferences.synchronize()
    }
}
