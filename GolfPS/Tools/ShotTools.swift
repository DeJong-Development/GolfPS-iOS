//
//  ShotTools.swift
//  GolfPS
//
//  Created by Greg DeJong on 4/7/21.
//  Copyright © 2021 DeJong Development. All rights reserved.
//

import Foundation
import FirebaseFirestore

class ShotTools {
    
    static public func getElevationChange(start: GeoPoint, finish: GeoPoint, completion: @escaping (_ startElevation:Double, _ finishElevation:Double, _ distance:Double, _ elevation:Double, _ error:String?) -> ()) {

        var startElevation:Double = 0
        var finishElevation:Double = 0
        getElevation(atLocation: start, completion: { se in
            startElevation = se
            getElevation(atLocation: finish, completion: { fe in
                finishElevation = fe

                let elevationChange = finishElevation - startElevation
                let distance = elevationChange / tan(45)
                if (AppSingleton.shared.metric) {
                    completion(startElevation, finishElevation, distance, elevationChange, nil)
                } else {
                    //results are in meters, convert to yards
                    completion(startElevation, finishElevation, distance.toYards(), elevationChange, nil)
                }
            })
        })
    }
    static public func getElevationChange(start: GeoPoint, finishElevation: Double, completion: @escaping (_ startElevation:Double, _ finishElevation:Double, _ distance:Double, _ elevation:Double, _ error:String?) -> ()) {
        
        func completeElevation(calculatedElevation:Double) {
            if (calculatedElevation < -1000) {
                completion(calculatedElevation, finishElevation, 0, 0, "Invalid elevation change.")
                return
            }
            startElevation = calculatedElevation
            
            let elevationChange = finishElevation - startElevation
            let distance = elevationChange / tan(45)
            if (AppSingleton.shared.metric) {
                completion(startElevation, finishElevation, distance, elevationChange, nil)
            } else {
                //results are in meters, convert to yards
                completion(startElevation, finishElevation, distance.toYards(), elevationChange, nil)
            }
        }
        
        var startElevation:Double = 0
        //randomly get an elevation api and call it so that we split the load?
        //could cause inaccurate answers?
        switch Int.random(in: 0..<2) {
        case 0:
            DebugLogger.log(message: "Using Elevation API 1")
            getElevation(atLocation: start, completion: completeElevation)
        case 1:
            DebugLogger.log(message: "Using Elevation API 2")
            getElevation2(atLocation: start, completion: completeElevation)
        case 2:
            DebugLogger.log(message: "Using Elevation API 3")
            getElevation3(atLocation: start, completion: completeElevation)
        default: ()
        }
    }
    
    static private func getElevation(atLocation location:GeoPoint, completion: @escaping (Double) -> ()) {
        let url = URL(string: "https://api.opentopodata.org/v1/ned10m?locations=\(location.latitude),\(location.longitude)")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else {
                completion(-1)
                return
            }
            guard let elevationData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                completion(-1)
                return
            }
            
            if let results = elevationData["results"] as? [[String:Any]], let resultsData = results.first, let elevation = resultsData["elevation"] as? Double {
                completion(elevation)
            } else {
                completion(-1)
            }
        }
        task.resume()
    }
    static private func getElevation2(atLocation location:GeoPoint, completion: @escaping (Double) -> ()) {
        let url = URL(string: "https://api.open-elevation.com/api/v1/lookup?locations=\(location.latitude),\(location.longitude)")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else {
                completion(-1)
                return }
            guard let elevationData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                completion(-1)
                return
            }
            
            if let results = elevationData["results"] as? [[String:Any]], let resultsData = results.first, let elevation = resultsData["elevation"] as? Double {
                completion(elevation)
            } else {
                completion(-1)
            }
        }
        task.resume()
    }
    static private func getElevation3(atLocation location:GeoPoint, completion: @escaping (Double) -> ()) {
        let url = URL(string: "https://nationalmap.gov/epqs/pqs.php?x=\(location.latitude)&y=\(location.longitude)&units=Meters&output=json")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else {
                completion(-1)
                return
            }
            guard let elevationData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                completion(-1)
                return
            }
            
            if let results = elevationData["results"] as? [[String:Any]], let resultsData = results.first, let elevation = resultsData["elevation"] as? Double {
                completion(elevation)
            } else {
                completion(-1)
            }
        }
        task.resume()
    }
}
