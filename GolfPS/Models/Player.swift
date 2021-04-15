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
    
    private(set) var name:String = "Incognito";
    private(set) var id:String = UUID().uuidString;
    
    var geoPoint:GeoPoint?
    var lastLocationUpdate:Date?
    var avatarURL:URL?
    
    init(id: String) {
        self.id = id;
    }
}

class MePlayer:Player {
    private let preferences = UserDefaults.standard;
    
    var numStrokes:Int = 0
    
    private(set) var badges:[Badge] = [Badge]()
    private(set) var bag:Bag = Bag()
    
    var numUniqueCourses:Int {
        return coursesVisited?.count ?? 0
    }
    var coursesVisited:[String]? {
        return self.preferences.stringArray(forKey: "player_courses_visited")
    }
    internal func addCourseVisitation(courseId:String) {
        var newCoursesVisited:[String] = [String]()
        if let cv = coursesVisited {
            newCoursesVisited.append(contentsOf: cv)
        }
        newCoursesVisited.append(courseId)
        self.preferences.setValue(newCoursesVisited, forKey: "player_courses_visited")
        self.preferences.synchronize()
    }
    var didLogLongDrive:Bool {
        get { return self.preferences.bool(forKey: "player_logged_long_drive") }
        set(didLongDrive) {
           self.preferences.setValue(didLongDrive, forKey: "player_logged_long_drive")
           self.preferences.synchronize()
        }
    }
    var didCustomizeBag:Bool {
        get { return self.preferences.bool(forKey: "player_customize_bag") }
        set(didLongDrive) {
           self.preferences.setValue(didLongDrive, forKey: "player_customize_bag")
           self.preferences.synchronize()
        }
    }
    
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
    
    override init(id: String) {
        super.init(id: id)
        
        self.badges = [ExplorerBadge(id: "explorer"),
                       LongDriveBadge(id: "longdrive"),
                       CustomizerBadge(id: "bagcustomize")
        ]
    }
}
