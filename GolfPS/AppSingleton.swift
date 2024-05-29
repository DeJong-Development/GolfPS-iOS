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
    
    var testing:Bool = false
    
    var metric:Bool {
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: "using_metric")
        }
        get {
            return UserDefaults.standard.bool(forKey: "using_metric")
        }
    }
    var cupholderMode:Bool {
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: "cupholder_mode")
        }
        get {
            return UserDefaults.standard.bool(forKey: "cupholder_mode")
        }
    }
    
    // Wrapper for obtaining keys from keys.plist
    func valueForAPIKey(keyname:String) -> String {
        // Get the file path for keys.plist
        guard let filePath = Bundle.main.path(forResource: "ApiKeys", ofType: "plist"), let plist = NSDictionary(contentsOfFile: filePath), let value:String = plist.object(forKey: keyname) as? String else {
            return "no-key-found"
        }
        return value
    }
    
    init() {
        #if DEBUG
        #else
        self.testing = false
        #endif
    }
}

