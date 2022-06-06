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

public class Course: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.name)
    }
    public var hashValue: Int {
        return id.hashValue ^ name.hashValue
    }
    public static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
    
    private let preferences = UserDefaults.standard
    
    private(set) var id:String = ""
    private(set) var name:String = ""
    private(set) var city:String = ""
    private(set) var state:String = ""
    private(set) var spectation:GeoPoint?
    
    var fullStateName:String? {
        switch state.uppercased() {
        case "AL": return "alabama"
        case "AK": return "alaska"
        case "AZ": return "arizona"
        case "AR": return "arkansas"
        case "CA": return "california"
        case "CO": return "colorado"
        case "CT": return "connecticut"
        case "DE": return "delaware"
        case "FL": return "florida"
        case "GA": return "georgia"
        case "HI": return "hawaii"
        case "ID": return "idaho"
        case "IL": return "illinois"
        case "IN": return "indiana"
        case "IA": return "iowa"
        case "KS": return "kansas"
        case "KY": return "kentucky"
        case "LA": return "louisiana"
        case "ME": return "maine"
        case "MD": return "maryland"
        case "MA": return "massachusetts"
        case "MI": return "michigan"
        case "MN": return "minnesota"
        case "MS": return "mississippi"
        case "MO": return "missouri"
        case "MT": return "montana"
        case "NE": return "nebraska"
        case "NV": return "nevada"
        case "NH": return "new hampshire"
        case "NJ": return "new jersy"
        case "NM": return "new mexico"
        case "NY": return "new york"
        case "NC": return "north carolina"
        case "ND": return "north dakota"
        case "OH": return "ohio"
        case "OK": return "oklahoma"
        case "OR": return "oregon"
        case "PA": return "pennsylvania"
        case "RI": return "rhode island"
        case "SC": return "south carolina"
        case "SD": return "south dakota"
        case "TN": return "tennessee"
        case "TX": return "texas"
        case "UT": return "utah"
        case "VT": return "vermont"
        case "VA": return "virginia"
        case "WA": return "washington"
        case "WV": return "west virginia"
        case "WI": return "wisconsin"
        case "WY": return "wyoming"
        default: return nil
        }
    }
    
    var holeInfo:[Hole] = [Hole]()
    
    var didPlayHere:Bool {
        get { return self.preferences.bool(forKey: "played_at_\(id)") }
        set(newSharePreference) {
            self.preferences.setValue(newSharePreference, forKey: "played_at_\(id)")
            self.preferences.synchronize()
        }
    }
    
    var docReference:DocumentReference? {
        if id == "" { return nil }
        return AppSingleton.shared.db.collection("courses").document(self.id)
    }
    
    var bounds:GMSCoordinateBounds {
        var bounds:GMSCoordinateBounds = GMSCoordinateBounds()
        for hole in self.holeInfo {
            bounds = bounds.includingBounds(hole.bounds)
        }
        if let s = spectation {
            bounds = bounds.includingCoordinate(CLLocationCoordinate2D(latitude: s.latitude, longitude: s.longitude))
        }
        return bounds
    }
    
    init?(id:String, data:[String:Any]) {
        guard let realCourseName:String = data["name"] as? String,
              let city:String = data["city"] as? String,
              let state:String = data["state"] as? String else {
            return nil
        }
        self.id = id
        self.name = realCourseName
        self.city = city
        self.state = state
        self.spectation = data["spectation"] as? GeoPoint
    }
}
