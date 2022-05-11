//
//  Club.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/13/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation

public struct Club {
    
    private let prefs:UserDefaults = UserDefaults.standard
    
    private var isMetric:Bool {
        return AppSingleton.shared.metric
    }
    
    private(set) var id: String = "clubid"
    private var defaultName:String {
        switch order {
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
    private var defaultYards:Int {
        switch order {
        case 1: return 250;
        case 2: return 230;
        case 3: return 220;
        case 4: return 205;
        case 5: return 192;
        case 6: return 184;
        case 7: return 173;
        case 8: return 164;
        case 9: return 156;
        case 10: return 140;
        case 11: return 130;
        case 12: return 110;
        case 13: return 80;
        case 14: return 5;
        default: return -1;
        }
    }
    private var defaultDistance:Int {
        return isMetric ? Int(Double(defaultYards) * 0.9144) : defaultYards
    }
    
    var order:Int {
        get {
            return prefs.integer(forKey: "cluborder\(id)")
        }
        set(newOrder) {
            prefs.set(newOrder, forKey: "cluborder\(id)")
        }
    }
    var name:String {
        get {
            return prefs.string(forKey: "clubname\(id)") ?? defaultName;
        }
        set(newName) {
            prefs.set(newName, forKey: "clubname\(id)")
        }
    }
    var distance:Int {
        get {
            let d = prefs.integer(forKey: "clubdistance\(id)")
            if d > 0 { return d }
            return defaultDistance
        }
        set(newDistance) {
            prefs.set(newDistance, forKey: "clubdistance\(id)")
        }
    }
    var isActive:Bool {
        return !prefs.bool(forKey: "clubnotactive\(id)")
    }
    
    init(id:String) {
        self.id = id
    }
    
    init(name:String, distance:Int) {
        self.id = UUID().uuidString
        self.name = name
        self.distance = distance
    }
    
    func activateClub() {
        prefs.set(false, forKey: "clubnotactive\(id)")
    }
    func deactivateClub() {
        prefs.set(true, forKey: "clubnotactive\(id)")
    }
}
