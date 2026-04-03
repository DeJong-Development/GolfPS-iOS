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
    static private let stateNameLookup:[String:String] = [
        "AL": "Alabama",
        "AK": "Alaska",
        "AZ": "Arizona",
        "AR": "Arkansas",
        "CA": "California",
        "CO": "Colorado",
        "CT": "Connecticut",
        "DE": "Delaware",
        "FL": "Florida",
        "GA": "Georgia",
        "HI": "Hawaii",
        "ID": "Idaho",
        "IL": "Illinois",
        "IN": "Indiana",
        "IA": "Iowa",
        "KS": "Kansas",
        "KY": "Kentucky",
        "LA": "Louisiana",
        "ME": "Maine",
        "MD": "Maryland",
        "MA": "Massachusetts",
        "MI": "Michigan",
        "MN": "Minnesota",
        "MS": "Mississippi",
        "MO": "Missouri",
        "MT": "Montana",
        "NE": "Nebraska",
        "NV": "Nevada",
        "NH": "New Hampshire",
        "NJ": "New Jersey",
        "NM": "New Mexico",
        "NY": "New York",
        "NC": "North Carolina",
        "ND": "North Dakota",
        "OH": "Ohio",
        "OK": "Oklahoma",
        "OR": "Oregon",
        "PA": "Pennsylvania",
        "RI": "Rhode Island",
        "SC": "South Carolina",
        "SD": "South Dakota",
        "TN": "Tennessee",
        "TX": "Texas",
        "UT": "Utah",
        "VT": "Vermont",
        "VA": "Virginia",
        "WA": "Washington",
        "WV": "West Virginia",
        "WI": "Wisconsin",
        "WY": "Wyoming",
        "DC": "District of Columbia",
        "AB": "Alberta",
        "BC": "British Columbia",
        "MB": "Manitoba",
        "NB": "New Brunswick",
        "NL": "Newfoundland and Labrador",
        "NS": "Nova Scotia",
        "NT": "Northwest Territories",
        "NU": "Nunavut",
        "ON": "Ontario",
        "PE": "Prince Edward Island",
        "QC": "Quebec",
        "SK": "Saskatchewan",
        "YT": "Yukon",
        "DR": "Dominican Republic",
        "MX": "Mexico",
        "UK": "United Kingdom"
    ]
    
    static func fullStateName(for code:String) -> String? {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return stateNameLookup[normalizedCode]
    }
    
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
        return Course.fullStateName(for: state)
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
