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
    
    fileprivate var me:MePlayer {
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

class LongDriveBadge: Badge {
    
    override var progress:CGFloat {
        return me.didLogLongDrive ? 100 : 0
    }
    override var isUnlocked:Bool {
        return me.didLogLongDrive
    }
    
    override init(id: String) {
        super.init(id: id)
        
        self.title = "DRIVER"
        self.description = "Play a course with a valid long drive hole, tap the Longest Drive button, tap Mark, and successfully record a long drive."
        self.icon = #imageLiteral(resourceName: "golf_hole_black")
        self.background = #imageLiteral(resourceName: "golf_ball_blank")
    }
}

class CustomizerBadge: Badge {
    
    override var progress:CGFloat {
        return me.didCustomizeBag ? 100 : 0
    }
    override var isUnlocked:Bool {
        return me.didCustomizeBag
    }
    
    override init(id: String) {
        super.init(id: id)
        
        self.title = "CUSTOMIZER"
        self.description = "Update your golf bag with your clubs and distances. Get better club suggestions."
        self.icon = #imageLiteral(resourceName: "customize")
        self.background = #imageLiteral(resourceName: "golf_ball_blank")
    }
}

class AmbassadorBadge: Badge {
    
    override var progress:CGFloat {
        return me.didSeeAmbassadorMessage ? 100 : 0
    }
    override var isUnlocked:Bool {
        return me.didSeeAmbassadorMessage
    }
    
    override init(id: String) {
        super.init(id: id)
        
        self.title = "AMBASSADOR"
        self.description = "Become a course ambassador by convincing the app developer that you are worthy."
        self.icon = #imageLiteral(resourceName: "ambassador")
        self.background = #imageLiteral(resourceName: "golf_ball_blank")
    }
}

class ActiveAmbassadorBadge: Badge {
    
    override var progress:CGFloat {
        return me.didModifyAmbassadorCourse ? 100 : 0
    }
    override var isUnlocked:Bool {
        return me.didModifyAmbassadorCourse
    }
    
    override init(id: String) {
        super.init(id: id)
        
        self.title = "EDITOR"
        self.description = "Contribute to the community by keeping your course data up to date. Update the position of a tee, pin, or bunker."
        self.icon = #imageLiteral(resourceName: "surveyor")
        self.background = #imageLiteral(resourceName: "golf_ball_blank")
    }
}
