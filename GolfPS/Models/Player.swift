//
//  User.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/8/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation
import FirebaseFirestore

class Player {
    let preferences = UserDefaults.standard;
    
    var name:String = "Incognito";
    var id:String = UUID().uuidString;
    var location:GeoPoint?
    var lastLocationUpdate:Date?
    var avatarURL:URL?
    
    var numStrokes:Int = 0
    var numUniqueCourses:Int = 0
    
    var badges:[Badge] = [Badge]()
    
    var shareLocation:Bool {
        get { return self.preferences.bool(forKey: "player_share_location") }
        set(newSharePreference) {
            self.preferences.setValue(newSharePreference, forKey: "player_share_location")
            self.preferences.synchronize()
        }
    }
    var shareBitmoji:Bool {
        get { return self.preferences.bool(forKey: "player_share_bitmoji") }
        set(newSharePreference) {
            self.preferences.setValue(newSharePreference, forKey: "player_share_bitmoji")
            self.preferences.synchronize()
        }
    }
    
    init() {
        let explorerBadge:ExplorerBadge = ExplorerBadge(id: "explorer")
        self.badges.append(explorerBadge)
    }
}
