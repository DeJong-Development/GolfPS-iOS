//
//  AppSingleton.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/3/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation
import FirebaseFirestore

class AppSingleton {
    static let shared = AppSingleton()
    
    //------------------------------------------------------------
    
    var appPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    var db:Firestore!
    var me:MePlayer!
    var course:Course? = nil
    
    var metric:Bool {
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: "using_metric")
        }
        get {
            return UserDefaults.standard.bool(forKey: "using_metric")
        }
    }
}

