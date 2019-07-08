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
    
    func updateHoleInfo(completion: @escaping (Bool, Error?) -> ()) {
        AppSingleton.shared.db.collection("courses").document(self.id)
            .collection("holes").getDocuments() { (querySnapshot, error) in
                if let err = error {
                    print("Error getting documents: \(err)")
                    completion(false, err)
                } else {
                    
                    self.holeInfo.removeAll();
                    
                    for document in querySnapshot!.documents {
                        //get all the courses and add to a course list
                        let data = document.data();
                        
                        if let holeNumber:Int = Int(document.documentID) {
                            let hole:Hole = Hole(number: holeNumber)
                            
                            guard let pinObj = data["pin"] as? GeoPoint else {
                                print("Invalid hole structure!")
                                return;
                            }
                            
                            hole.pinLocation = pinObj;
                            if let bunkerObj = data["bunkers"] as? [GeoPoint] {
                                hole.bunkerLocations = bunkerObj;
                            } else if let bunkerObj = data["bunkers"] as? GeoPoint {
                                hole.bunkerLocations = [bunkerObj];
                            }
                            if let teeObj = data["tee"] as? [GeoPoint] {
                                hole.teeLocations = teeObj;
                            } else if let teeObj = data["tee"] as? GeoPoint {
                                hole.teeLocations = [teeObj]
                            }
                            if let dlObj = data["dogLeg"] as? GeoPoint {
                                hole.dogLegLocation = dlObj
                            }
                            
                            self.holeInfo.append(hole);
                        }
                    }
                    
                    completion(true, nil)
                }
        }
    }
    
    init(id:String) {
        self.id = id;
    }
}
