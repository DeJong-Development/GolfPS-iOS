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
        AppSingleton.shared.db.collection("courses").document(course.id)
            .collection("holes").getDocuments() { (querySnapshot, error) in
                course.holeInfo.removeAll();
                
                if let err = error {
                    print("Error getting documents: \(err)")
                    completion(false, err)
                } else {
                    for document in querySnapshot!.documents {
                        //get all the courses and add to a course list
                        let data = document.data();
                        
                        if let holeNumber:Int = Int(document.documentID) {
                            if let hole:Hole = Hole(number: holeNumber, data: data) {
                                course.holeInfo.append(hole)
                            }
                        }
                    }
                    completion(true, nil)
                }
        }
    }
    
    ///get the long drive data asscociated with this hole
    static public func getLongestDrives(for hole: Hole, completion: @escaping (Bool, Error?) -> ()) {
        
        if let holeDocRef = hole.docReference {
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
                                    hole.myLongestDrive = driveDistance
                                }
                            }
                            if let driveLocation = driveData["location"] as? GeoPoint {
                                hole.longestDrives[driveUser] = driveLocation
                            }
                        }
                        completion(true, nil)
                    }
            }
        } else {
            completion(false, nil)
        }
    }
}
