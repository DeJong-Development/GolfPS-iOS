//
//  ClubTools.swift
//  GolfPS
//
//  Created by Greg DeJong on 4/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import Foundation

class ClubTools {
    
    let preferences = UserDefaults.standard
    
    static public func cleanClubName(_ name: String?) -> String {
        guard let n = name else {
            return ""
        }
        let regexPattern = "[^a-zA-Z0-9$#! ]"
        do {
            let cleanName:NSMutableString = NSMutableString(string: n)
            let regex = try NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
            let range = NSMakeRange(0, n.count)
            regex.replaceMatches(in: cleanName, options: .withTransparentBounds, range: range, withTemplate: "")
            return String(cleanName)
        } catch {
            fatalError("invalid section name clean")
        }
    }
    static public func cleanClubDistance(_ distance: String?) -> String  {
        guard let d = distance else {
            return ""
        }
        
        let regexPattern = "[^0-9]"
        do {
            let cleanName:NSMutableString = NSMutableString(string: d)
            let regex = try NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
            let range = NSMakeRange(0, d.count)
            regex.replaceMatches(in: cleanName, options: .withTransparentBounds, range: range, withTemplate: "")
            return String(cleanName)
        } catch {
            fatalError("invalid section name clean")
        }
    }
}
