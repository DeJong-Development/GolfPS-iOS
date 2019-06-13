//
//  Hole.swift
//  GolfPS
//
//  Created by Greg DeJong on 4/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import Foundation
import Firebase
import GoogleMaps

public class Hole {
    
    var holeNumber:Int = 1;
    
    var bunkerLocations:[GeoPoint] = [GeoPoint]()
    var teeLocations:[GeoPoint] = [GeoPoint]()
    var pinLocation:GeoPoint?
    var dogLegLocation:GeoPoint?
    
    var bounds:GMSCoordinateBounds {
        var bounds:GMSCoordinateBounds = GMSCoordinateBounds();
        for tPoint in self.teeLocations {
            let coordinate = CLLocationCoordinate2D(latitude: tPoint.latitude, longitude: tPoint.longitude)
            bounds = bounds.includingCoordinate(coordinate);
        }
        for blPoint in self.bunkerLocations {
            let coordinate = CLLocationCoordinate2D(latitude: blPoint.latitude, longitude: blPoint.longitude)
            bounds = bounds.includingCoordinate(coordinate);
        }
        if let dlPoint = self.dogLegLocation {
            let coordinate = CLLocationCoordinate2D(latitude: dlPoint.latitude, longitude: dlPoint.longitude)
            bounds = bounds.includingCoordinate(coordinate);
        }
        if let pinLocation:GeoPoint = self.pinLocation {
            let pinCoordinate = CLLocationCoordinate2D(latitude: pinLocation.latitude, longitude: pinLocation.longitude)
            bounds = bounds.includingCoordinate(pinCoordinate);
        }
        return bounds;
    }
    
    init(number:Int) {
        self.holeNumber = number;
        
        bunkerLocations = [GeoPoint]()
        teeLocations = [GeoPoint]()
        pinLocation = nil
        dogLegLocation = nil
    }
}
