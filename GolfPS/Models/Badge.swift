//
//  Badge.swift
//  Instinct
//
//  Created by Greg DeJong on 8/30/19.
//  Copyright © 2019 Sports Academy. All rights reserved.
//

import UIKit

class Badge {
    
    var id:String = ""
    var title:String = "ACHIEVEMENT TITLE"
    var description:String = ""
    var icon:UIImage?
    var background:UIImage!
    
    fileprivate var me:Player {
        return AppSingleton.shared.me
    }
    
    var progress:CGFloat {
        return 0
    }
    var isUnlocked:Bool {
        return false
    }
    
    init(id: String) {
        self.id = id
    }
}

//ideas
//number of courses played at (actually at the course and not spectating)
//number of holes seen
//number of days spent golfing (actually at the course and not spectating)
//logged a long drive
//attempted to log unrealistically long long drive
//recorded longest drive on hole
//linked snapchat and shared location with everyone
//customized my bag with appropriate distances

class ExplorerBadge: Badge {
    
    override var progress:CGFloat {
        return 100 * CGFloat(me.numUniqueCourses) / 5
    }
    override var isUnlocked:Bool {
        return me.numUniqueCourses >= 5
    }
    
    override init(id: String) {
        super.init(id: id)
        
        self.title = "EXPLORER"
        self.description = "Go to 5 or more unique courses and explore using the app! Spectating a round from a distance doesn't count..."
        self.icon = #imageLiteral(resourceName: "explorer_achievement")
        self.background = #imageLiteral(resourceName: "golf_ball_blank")
    }
}
