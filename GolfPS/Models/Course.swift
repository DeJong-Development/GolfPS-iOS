//
//  Course.swift
//  GolfPS
//
//  Created by Greg DeJong on 4/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import Foundation

public class Course {
    var id:String = ""
    var name:String = ""
    var city:String = ""
    var state:String = ""
    
    var holeInfo:[Hole] = [Hole]();
    
    init(id:String) {
        self.id = id;
    }
}
