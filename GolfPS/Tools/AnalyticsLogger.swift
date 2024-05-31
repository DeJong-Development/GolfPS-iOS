//
//  AnalyticsLogger.swift
//

import os
import Foundation
import FirebaseAnalytics

class AnalyticsLogger {
    
    // ---------------- ANALYTICS EVENTS ------------------- //
    
    static func log(name: String, parameters: [String:Any]? = nil) {
        #if DEBUG
        os_log("LOG: %@", name)
        #endif
        
        Analytics.logEvent(name, parameters: parameters)
    }
    
    static func selectCourse(_ course: Course) {
        self.log(name: "select_course", parameters: ["name": course.name.lowercased()])
    }
    
    
    // ---------------- USER PROPERTY ------------------- //
    
    static func setUserProperty(value: String, name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    static func setSnapchat(usingSnapchat: Bool) {
        self.setUserProperty(value: usingSnapchat ? "true" : "false", name: "snapchat")
    }
    
    static func setDisplayMode(isDefault: Bool) {
        self.setUserProperty(value: isDefault ? "default" : "cupholder", name: "displayMode")
    }
    
    static func setUnits(isMetric: Bool) {
        self.setUserProperty(value: isMetric ? "metric" : "english", name: "units")
    }
    
}
