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
    
    private(set) var bunkerGeoPoints:[GeoPoint] = [GeoPoint]()
    private(set) var fairwayGeoPoints:[GeoPoint] = [GeoPoint]()
    private(set) var fairwayPath: GMSPath? = nil
    private(set) var teeGeoPoints:[GeoPoint] = [GeoPoint]()
    private(set) var pinGeoPoint:GeoPoint!
    private(set) var dogLegGeoPoint:GeoPoint?
    
    var pinElevation:Double?
    var isLongDrive:Bool = false
    var myLongestDriveInYards:Int?
    var myLongestDriveInMeters:Int?
    
    private var timeUpdatedLongDrive:Double = 0
    var longestDrives:[String:GeoPoint] = [String:GeoPoint]()
    
    var bounds:GMSCoordinateBounds {
        var bounds:GMSCoordinateBounds = GMSCoordinateBounds()
        for tPoint in self.teeGeoPoints {
            bounds = bounds.includingCoordinate(tPoint.location)
        }
        for blPoint in self.bunkerGeoPoints {
            bounds = bounds.includingCoordinate(blPoint.location)
        }
        if let dlPoint = self.dogLegGeoPoint {
            bounds = bounds.includingCoordinate(dlPoint.location)
        }
        if let pinLocation:GeoPoint = self.pinGeoPoint {
            bounds = bounds.includingCoordinate(pinLocation.location)
        }
        return bounds
    }
    
    private(set) var distance:Int = 0
    private(set) var width:Int = 100
    
    init?(number:Int, data:[String:Any]) {
        self.number = number
        
        bunkerGeoPoints = [GeoPoint]()
        fairwayGeoPoints = [GeoPoint]()
        teeGeoPoints = [GeoPoint]()
        pinGeoPoint = nil
        dogLegGeoPoint = nil
        isLongDrive = false
        
        guard let pinObj = data["pin"] as? GeoPoint else {
            DebugLogger.report(error: nil, message: "Invalid hole structure!")
            return nil
        }
        
        self.pinGeoPoint = pinObj
        
        if let teeObj = data["tee"] as? [GeoPoint] {
            self.teeGeoPoints = teeObj
        } else if let teeObj = data["tee"] as? GeoPoint {
            self.teeGeoPoints = [teeObj]
        }
        
        guard !self.teeGeoPoints.isEmpty else {
            return nil
        }
        
        if let fairwayObj = data["fairway"] as? [GeoPoint] {
            self.fairwayGeoPoints = fairwayObj
        } else if let fairwayObj = data["fairway"] as? GeoPoint {
            self.fairwayGeoPoints = [fairwayObj]
        }
        if let bunkerObj = data["bunkers"] as? [GeoPoint] {
            self.bunkerGeoPoints = bunkerObj
        } else if let bunkerObj = data["bunkers"] as? GeoPoint {
            self.bunkerGeoPoints = [bunkerObj]
        }
        if let dlObj = data["dogLeg"] as? GeoPoint {
            self.dogLegGeoPoint = dlObj
        }
        if let pinElevation = data["pinElevation"] as? Double {
            self.pinElevation = pinElevation
        }
        
        self.isLongDrive = data["longDrive"] as? Bool ?? false
        
        self.distance = self.mapTools.distanceFrom(first: self.teeGeoPoints[0], second: self.pinGeoPoint)
        
        if !fairwayGeoPoints.isEmpty && fairwayGeoPoints.count > 2 {
            //create fairway polygon so we can check if we are within it or not
            let path = GMSMutablePath()
            for point in fairwayGeoPoints {
                path.add(point.location)
            }
            // close the path
            path.add(fairwayGeoPoints.first!.location)
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
    
    func saveNewTeeLocation(_ location: CLLocationCoordinate2D) -> Bool {
        // check to make sure tee location is reasonable
        if mapTools.distanceFrom(first: location, second: self.pinGeoPoint.location) > 800 {
            DebugLogger.report(error: nil, message: "Ambassador moved tee to unreasonable location: \(AppSingleton.shared.me.id)")
            return false
        }
        
        self.docReference!.setData([
            "tee": [location.geopoint],
            "updateTime": Timestamp(),
            "updatedBy": AppSingleton.shared.me.id
        ], merge: true)
        
        // update the local location of the tee
        self.teeGeoPoints = [location.geopoint]
        
        return true
    }
    
    func saveNewPinLocation(_ location: CLLocationCoordinate2D) -> Bool {
        // check to make sure tee location is reasonable
        if mapTools.distanceFrom(first: location, second: self.teeGeoPoints[0].location) > 800 {
            DebugLogger.report(error: nil, message: "Ambassador moved pin to unreasonable location: \(AppSingleton.shared.me.id)")
            return false
        }
        
        self.docReference!.setData([
            "pin": location.geopoint,
            "updateTime": Timestamp(),
            "updatedBy": AppSingleton.shared.me.id
        ], merge: true)
        
        // update the local location of the pin
        self.pinGeoPoint = location.geopoint
        
        //TODO: get new elevation value?
        
        return true
    }
    
    func saveNewBunkerLocations(_ locations: [CLLocationCoordinate2D]) -> Bool {
        // check to make sure tee location is reasonable
        for bl in locations {
            if mapTools.distanceFrom(first: bl, second: self.pinGeoPoint.location) > 800 {
                DebugLogger.report(error: nil, message: "Ambassador moved bunker to unreasonable location: \(AppSingleton.shared.me.id)")
                return false
            }
        }
        
        self.docReference!.setData([
            "bunkers": locations.compactMap({$0.geopoint}),
            "updateTime": Timestamp(),
            "updatedBy": AppSingleton.shared.me.id
        ], merge: true)
        
        // update the local location of the pin
        self.bunkerGeoPoints = locations.compactMap({$0.geopoint})
        
        return true
    }
    
    
}
