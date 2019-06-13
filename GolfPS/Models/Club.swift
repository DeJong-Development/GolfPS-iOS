//
//  Club.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/13/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation

public class Club {
    
    var number:Int = 1;
    var defaultName:String = "Driver"
    var defaultDistance:Int = 250
    
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
        self.number = number;
    }
}
