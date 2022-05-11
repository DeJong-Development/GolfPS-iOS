//
//  CourseTools.swift
//  GolfPS
//
//  Created by Greg DeJong on 8/7/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation
import FirebaseFirestore

class CourseTools {
    
    static public func updateHoleInfo(for course:Course, completion: @escaping (Bool, Error?) -> ()) {
        
        guard let courseDocRef = course.docReference else {
            completion(false, nil)
            return
        }
        
        courseDocRef.collection("holes")
            .getDocuments() { (querySnapshot, error) in
                
                if let err = error {
                    print("Error getting documents: \(err)")
                    completion(false, err)
                } else {
                    course.holeInfo.removeAll()
                    for document in querySnapshot!.documents {
                        //get all the courses and add to a course list
                        let data = document.data();
                        
                        if let holeNumber:Int = Int(document.documentID) {
                            guard let hole:Hole = Hole(number: holeNumber, data: data) else {
                                continue
                            }
                            course.holeInfo.append(hole)
                        }
                    }
                    completion(true, nil)
                }
        }
    }
    
    ///get the long drive data associated with this hole
    static public func getLongestDrives(for hole: Hole, completion: @escaping (Bool, Error?) -> ()) {
        
        guard let holeDocRef = hole.docReference else {
            completion(false, nil)
            return
        }
        
        holeDocRef.collection("drives")
            .order(by: "distance", descending: true)
            .limit(to: 3)
            .getDocuments { (snapshot, error) in
                if let err = error {
                    print("Error adding long drive: \(err)")
                    completion(false, err)
                } else if let snap = snapshot {
                    
                    hole.longestDrives = [String:GeoPoint]()
                    for driveDoc in snap.documents {
                        let driveData = driveDoc.data()
                        let driveUser = driveDoc.documentID;
                        
                        if let driveDistance = driveData["distance"] as? Int {
                            if (driveUser == AppSingleton.shared.me.id) {
                                hole.myLongestDriveInYards = driveDistance
                                hole.myLongestDriveInMeters = Int(Double(driveDistance) / 1.09361)
                            }
                        }
                        if let driveLocation = driveData["location"] as? GeoPoint {
                            hole.longestDrives[driveUser] = driveLocation
                        }
                    }
                    completion(true, nil)
                }
        }
    }
}
