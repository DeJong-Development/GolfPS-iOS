//
//  Club.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/13/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation

public struct Club {
    
    private(set) var number:Int = 1;
    private var defaultName:String {
        switch number {
        case 1: return "Driver";
        case 2: return "5 Wood";
        case 3: return "3 Wood";
        case 4: return "3 Iron";
        case 5: return "4 Iron";
        case 6: return "5 Iron";
        case 7: return "6 Iron";
        case 8: return "7 Iron";
        case 9: return "8 Iron";
        case 10: return "9 Iron";
        case 11: return "Pitching Wedge";
        case 12: return "Gap Wedge";
        case 13: return "Sand Wedge";
        case 14: return "Putter";
        default: return "22";
        }
    }
    private var defaultDistance:Int {
        switch number {
        case 1: return AppSingleton.shared.metric ? 230 : 250;
        case 2: return AppSingleton.shared.metric ? Int(230 * 0.9144) : 230;
        case 3: return AppSingleton.shared.metric ? Int(220 * 0.9144) : 220;
        case 4: return AppSingleton.shared.metric ? Int(205 * 0.9144) : 205;
        case 5: return AppSingleton.shared.metric ? Int(192 * 0.9144) : 192;
        case 6: return AppSingleton.shared.metric ? Int(184 * 0.9144) : 184;
        case 7: return AppSingleton.shared.metric ? Int(173 * 0.9144) : 173;
        case 8: return AppSingleton.shared.metric ? Int(164 * 0.9144) : 164;
        case 9: return AppSingleton.shared.metric ? Int(156 * 0.9144) : 156;
        case 10: return AppSingleton.shared.metric ? Int(140 * 0.9144) : 140;
        case 11: return AppSingleton.shared.metric ? Int(130 * 0.9144) : 130;
        case 12: return AppSingleton.shared.metric ? Int(110 * 0.9144) : 110;
        case 13: return AppSingleton.shared.metric ? Int(80 * 0.9144) : 80;
        case 14: return AppSingleton.shared.metric ? 4 : 5;
        default: return -1;
        }
    }
    
    var name:String {
        get {
            return UserDefaults.standard.string(forKey: "clubname\(number)") ?? defaultName;
        }
        set(newName) {
            UserDefaults.standard.set(newName, forKey: "clubname\(number)")
            UserDefaults.standard.synchronize()
        }
    }
    var distance:Int {
        get {
            let d = UserDefaults.standard.integer(forKey: "clubdistance\(number)")
            if d > 0 { return d }
            return defaultDistance
        }
        set(newDistance) {
            UserDefaults.standard.set(newDistance, forKey: "clubdistance\(number)")
            UserDefaults.standard.synchronize()
        }
    }
    
    init(number:Int) {
        self.number = number
    }
}
