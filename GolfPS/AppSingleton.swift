//
//  AppSingleton.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/3/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation
import Firebase

class AppSingleton {
    static let shared = AppSingleton()
    
    //------------------------------------------------------------
    
    var appPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    var db:Firestore!
    let me:Player = Player()
}

