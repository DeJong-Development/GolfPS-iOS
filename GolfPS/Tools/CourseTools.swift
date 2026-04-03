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
    static public func getAvailableStates(completion: @escaping ([String], Error?) -> ()) {
        AppSingleton.shared.db.collection("courses")
            .order(by: "state")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                
                let states = Array(Set(snapshot?.documents.compactMap { document in
                    (document.data()["state"] as? String)?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .uppercased()
                }.filter { !$0.isEmpty } ?? [])).sorted()
                completion(states, nil)
            }
    }
    
    static public func getCourses(withIDs ids: [String], completion: @escaping ([Course], Error?) -> ()) {
        let uniqueIDs = Array(Set(ids)).filter { !$0.isEmpty }
        guard !uniqueIDs.isEmpty else {
            completion([], nil)
            return
        }
        
        let group = DispatchGroup()
        let lock = NSLock()
        var golfCourses: [Course] = []
        var firstError: Error?
        
        for id in uniqueIDs {
            group.enter()
            AppSingleton.shared.db.collection("courses").document(id).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    lock.lock()
                    if firstError == nil {
                        firstError = error
                    }
                    lock.unlock()
                    return
                }
                
                guard let snapshot = snapshot,
                      let data = snapshot.data(),
                      let course = Course(id: snapshot.documentID, data: data) else {
                    return
                }
                
                lock.lock()
                golfCourses.append(course)
                lock.unlock()
            }
        }
        
        group.notify(queue: .main) {
            completion(golfCourses, firstError)
        }
    }
    
    static public func getCourses(inState state: String, completion: @escaping ([Course], Error?) -> ()) {
        let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedState.isEmpty else {
            completion([], nil)
            return
        }
        
        AppSingleton.shared.db.collection("courses")
            .whereField("state", isEqualTo: trimmedState)
            .order(by: "name")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion([], error)
                    return
                }
                
                let golfCourses = snapshot?.documents.compactMap { document in
                    Course(id: document.documentID, data: document.data())
                } ?? []
                completion(golfCourses, nil)
            }
    }
    
    static public func updateHoleInfo(for course:Course, completion: @escaping (Bool, Error?) -> ()) {
        
        guard let courseDocRef = course.docReference else {
            completion(false, nil)
            return
        }
        
        courseDocRef.collection("holes")
            .getDocuments() { (querySnapshot, error) in
                
                if let err = error {
                    DebugLogger.report(error: error, message: "Error retrieving holes for course: \(course.id)")
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
                    DebugLogger.report(error: err, message: "Error adding long drive")
                    completion(false, err)
                } else if let snap = snapshot {
                    
                    hole.longestDrives = [String:GeoPoint]()
                    for driveDoc in snap.documents {
                        let driveData = driveDoc.data()
                        let driveUser = driveDoc.documentID
                        
                        if let driveDistance = driveData["distance"] as? Int {
                            if (driveUser == AppSingleton.shared.me.id) {
                                hole.myLongestDriveInYards = driveDistance
                                hole.myLongestDriveInMeters = driveDistance.toMeters()
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
