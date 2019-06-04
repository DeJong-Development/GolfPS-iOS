//
//  Hole.swift
//  GolfPS
//
//  Created by Greg DeJong on 4/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import Foundation
import Firebase

public class Hole {
    
    var holeNumber:Int = 1;
    
    var bunkerLocations:[GeoPoint] = [GeoPoint]()
    var teeLocations:[GeoPoint] = [GeoPoint]()
    var pinLocation:GeoPoint?
    
    init(number:Int) {
        self.holeNumber = number;
        
        bunkerLocations = [GeoPoint]()
        teeLocations = [GeoPoint]()
        pinLocation = nil
    }
}
