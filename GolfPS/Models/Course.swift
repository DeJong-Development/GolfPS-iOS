//
//  Course.swift
//  GolfPS
//
//  Created by Greg DeJong on 4/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import Foundation
import GoogleMaps
import FirebaseFirestore

public class Course {
    var id:String = ""
    var name:String = ""
    var city:String = ""
    var state:String = ""
    var spectation:GeoPoint?
    
    var holeInfo:[Hole] = [Hole]();
    
    var docReference:DocumentReference? {
        if id == "" { return nil }
        return AppSingleton.shared.db.collection("courses").document(self.id)
    }
    
    var bounds:GMSCoordinateBounds {
        var bounds:GMSCoordinateBounds = GMSCoordinateBounds();
        for hole in self.holeInfo {
            bounds = bounds.includingBounds(hole.bounds);
        }
        if let s = spectation {
            bounds = bounds.includingCoordinate(CLLocationCoordinate2D(latitude: s.latitude, longitude: s.longitude))
        }
        return bounds;
    }
    
    init(id:String) {
        self.id = id;
    }
}
