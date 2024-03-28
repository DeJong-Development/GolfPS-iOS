//
//  Hole.swift
//  GolfPS
//
//  Created by Greg DeJong on 4/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import Foundation
import FirebaseFirestore
import GoogleMaps

protocol HoleUpdateDelegate:AnyObject {
    func didUpdateLongDrive()
}

public class Hole {
    
    weak var updateDelegate:HoleUpdateDelegate?
    
    private lazy var mapTools = MapTools()
    private(set) var number:Int = 1
    
    var docReference:DocumentReference? {
        return AppSingleton.shared.course?.docReference?.collection("holes").document("\(self.number)")
    }
    
    private(set) var bunkerLocations:[GeoPoint] = [GeoPoint]()
    private(set) var fairwayLocations:[GeoPoint] = [GeoPoint]()
    private(set) var fairwayPath: GMSPath? = nil
    private(set) var teeLocations:[GeoPoint] = [GeoPoint]()
    private(set) var pinLocation:GeoPoint!
    private(set) var dogLegLocation:GeoPoint?
    
    var pinElevation:Double?
    var isLongDrive:Bool = false
    var myLongestDriveInYards:Int?
    var myLongestDriveInMeters:Int?
    
    private var timeUpdatedLongDrive:Double = 0
    var longestDrives:[String:GeoPoint] = [String:GeoPoint]()
    
    var bounds:GMSCoordinateBounds {
        var bounds:GMSCoordinateBounds = GMSCoordinateBounds()
        for tPoint in self.teeLocations {
            bounds = bounds.includingCoordinate(tPoint.location)
        }
        for blPoint in self.bunkerLocations {
            bounds = bounds.includingCoordinate(blPoint.location)
        }
        if let dlPoint = self.dogLegLocation {
            bounds = bounds.includingCoordinate(dlPoint.location)
        }
        if let pinLocation:GeoPoint = self.pinLocation {
            bounds = bounds.includingCoordinate(pinLocation.location)
        }
        return bounds
    }
    
    private(set) var distance:Int = 0
    private(set) var width:Int = 100
    
    init?(number:Int, data:[String:Any]) {
        self.number = number
        
        bunkerLocations = [GeoPoint]()
        fairwayLocations = [GeoPoint]()
        teeLocations = [GeoPoint]()
        pinLocation = nil
        dogLegLocation = nil
        isLongDrive = false
        
        guard let pinObj = data["pin"] as? GeoPoint else {
            DebugLogger.report(error: nil, message: "Invalid hole structure!")
            return nil
        }
        
        self.pinLocation = pinObj
        
        if let teeObj = data["tee"] as? [GeoPoint] {
            self.teeLocations = teeObj
        } else if let teeObj = data["tee"] as? GeoPoint {
            self.teeLocations = [teeObj]
        }
        
        guard !self.teeLocations.isEmpty else {
            return nil
        }
        
        if let fairwayObj = data["fairway"] as? [GeoPoint] {
            self.fairwayLocations = fairwayObj
        } else if let fairwayObj = data["fairway"] as? GeoPoint {
            self.fairwayLocations = [fairwayObj]
        }
        if let bunkerObj = data["bunkers"] as? [GeoPoint] {
            self.bunkerLocations = bunkerObj
        } else if let bunkerObj = data["bunkers"] as? GeoPoint {
            self.bunkerLocations = [bunkerObj]
        }
        if let dlObj = data["dogLeg"] as? GeoPoint {
            self.dogLegLocation = dlObj
        }
        if let pinElevation = data["pinElevation"] as? Double {
            self.pinElevation = pinElevation
        }
        
        self.isLongDrive = data["longDrive"] as? Bool ?? false
        
        self.distance = self.mapTools.distanceFrom(first: self.teeLocations[0], second: self.pinLocation)
        
        if !fairwayLocations.isEmpty && fairwayLocations.count > 2 {
            //create fairway polygon so we can check if we are within it or not
            let path = GMSMutablePath()
            for point in fairwayLocations {
                path.add(point.location)
            }
            // close the path
            path.add(fairwayLocations.first!.location)
            self.fairwayPath = path
        }
    }
    
    func setLongestDrive(distance:Int?) {
        guard let d = distance else {
            myLongestDriveInMeters = nil
            myLongestDriveInYards = nil
            return
        }
        
        if AppSingleton.shared.metric {
            myLongestDriveInMeters = d
            myLongestDriveInYards = d.toYards()
        } else {
            myLongestDriveInMeters = d.toMeters()
            myLongestDriveInYards = d
        }
    }
    
    func getLongestDrives() {
        guard isLongDrive else { return }
        guard CACurrentMediaTime() - self.timeUpdatedLongDrive > 60 else {
            return
        }
        
        CourseTools.getLongestDrives(for: self) { [weak self] (success, error) in
            self?.timeUpdatedLongDrive = CACurrentMediaTime()
            if (success) {
                self?.updateDelegate?.didUpdateLongDrive()
            }
        }
    }
    
    
}
