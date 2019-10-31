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

protocol HoleUpdateDelegate:class {
    func didUpdateLongDrive()
}

public class Hole {
    
    weak var updateDelegate:HoleUpdateDelegate?
    
    var number:Int = 1;
    
    var docReference:DocumentReference? {
        return AppSingleton.shared.course?.docReference?.collection("holes").document("\(self.number)");
    }
    
    var bunkerLocations:[GeoPoint] = [GeoPoint]()
    var teeLocations:[GeoPoint] = [GeoPoint]()
    var pinLocation:GeoPoint?
    var dogLegLocation:GeoPoint?
    var isLongDrive:Bool = false
    var myLongestDriveInYards:Int?
    var myLongestDriveInMeters:Int?
    
    var longestDrives:[String:GeoPoint] = [String:GeoPoint]()
    
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
    
    func setLongestDrive(distance:Int?) {
        guard let d = distance else {
            myLongestDriveInMeters = nil
            myLongestDriveInYards = nil
            return
        }
        
        if AppSingleton.shared.metric {
            myLongestDriveInMeters = d
            myLongestDriveInYards = Int(Double(d) * 1.09361)
        } else {
            myLongestDriveInMeters = Int(Double(d) / 1.09361)
            myLongestDriveInYards = d
        }
    }
    
    init?(number:Int, data:[String:Any]) {
        self.number = number;
        
        bunkerLocations = [GeoPoint]()
        teeLocations = [GeoPoint]()
        pinLocation = nil
        dogLegLocation = nil
        isLongDrive = false
        
        guard let pinObj = data["pin"] as? GeoPoint else {
            print("Invalid hole structure!")
            return nil;
        }
        
        self.pinLocation = pinObj;
        if let bunkerObj = data["bunkers"] as? [GeoPoint] {
            self.bunkerLocations = bunkerObj;
        } else if let bunkerObj = data["bunkers"] as? GeoPoint {
            self.bunkerLocations = [bunkerObj];
        }
        if let teeObj = data["tee"] as? [GeoPoint] {
            self.teeLocations = teeObj;
        } else if let teeObj = data["tee"] as? GeoPoint {
            self.teeLocations = [teeObj]
        }
        if let dlObj = data["dogLeg"] as? GeoPoint {
            self.dogLegLocation = dlObj
        }
        if let ld = data["longDrive"] as? Bool {
            self.isLongDrive = ld
            
            if (ld) {
                CourseTools.getLongestDrives(for: self) { [weak self] (success, error) in
                    if (success) {
                        self?.updateDelegate?.didUpdateLongDrive()
                    }
                }
            }
        }
    }
}
