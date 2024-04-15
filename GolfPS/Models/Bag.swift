//
//  Bag.swift
//  GolfPS
//
//  Created by Greg DeJong on 10/20/20.
//  Copyright © 2020 DeJong Development. All rights reserved.
//

import Foundation

public class Bag {
    
    private let prefs:UserDefaults = UserDefaults.standard
    
    private let defaultNumberOfClubs:Int = 14
    private var numberOfClubs:Int {
        get {
            let d = prefs.integer(forKey: "numberofclubs")
            if d > 0 && d < 24 {
                return d
            }
            return defaultNumberOfClubs
        }
        set(newNumber) {
            prefs.set(newNumber, forKey: "numberofclubs")
        }
    }
    
    private var clubIds:[String] {
        get {
            return prefs.stringArray(forKey: "assignedclubids") ?? []
        }
        set(newIds) {
            prefs.set(newIds, forKey: "assignedclubids")
        }
    }
    
    private(set) var myClubs:[Club] = [Club]()
    
    init() {
        for clubId in clubIds {
            let club = Club(id: clubId)
            if club.isActive {
                myClubs.append(club)
            }
        }
        
        sortClubs()
    }
    
    public func populateBagLong() {
        let driver = Club(name: "Driver", distance: 300)
        let threeWood = Club(name: "3 Wood", distance: 270)
        let threeHybrid = Club(name: "3 Hybrid", distance: 245)
        let fourIron = Club(name: "4 Iron", distance: 226)
        let fiveIron = Club(name: "5 Iron", distance: 212)
        let sixIron = Club(name: "6 Iron", distance: 198)
        let sevenIron = Club(name: "7 Iron", distance: 184)
        let eightIron = Club(name: "8 Iron", distance: 170)
        let nineIron = Club(name: "9 Iron", distance: 156)
        let pitchingWedge = Club(name: "Pitching Wedge", distance: 144)
        let gapWedge = Club(name: "Gap Wedge", distance: 131)
        let sandWedge = Club(name: "Sand Wedge", distance: 118)
        let logWedge = Club(name: "Lob Wedge", distance: 105)
        
        let clubs = [driver, threeWood, threeHybrid, fourIron, fiveIron, sixIron, sevenIron, eightIron, nineIron, pitchingWedge, gapWedge, sandWedge, logWedge]
        self.activeClubs(clubs)
    }
    
    public func populateBagAverage() {
        let driver = Club(name: "Driver", distance: 260)
        let threeWood = Club(name: "3 Wood", distance: 235)
        let fiveWood = Club(name: "5 Wood", distance: 215)
        let threeHybrid = Club(name: "3 Hybrid", distance: 200)
        let fourIron = Club(name: "4 Iron", distance: 190)
        let fiveIron = Club(name: "5 Iron", distance: 185)
        let sixIron = Club(name: "6 Iron", distance: 177)
        let sevenIron = Club(name: "7 Iron", distance: 168)
        let eightIron = Club(name: "8 Iron", distance: 158)
        let nineIron = Club(name: "9 Iron", distance: 145)
        let pitchingWedge = Club(name: "Pitching Wedge", distance: 125)
        let sandWedge = Club(name: "Sand Wedge", distance: 105)
        let logWedge = Club(name: "Lob Wedge", distance: 90)
        
        let clubs = [driver, threeWood, fiveWood, threeHybrid, fourIron, fiveIron, sixIron, sevenIron, eightIron, nineIron, pitchingWedge, sandWedge, logWedge]
        self.activeClubs(clubs)
    }
    
    public func populateBagShort() {
        let driver = Club(name: "Driver", distance: 217)
        let threeWood = Club(name: "3 Wood", distance: 205)
        let fiveWood = Club(name: "5 Wood", distance: 195)
        let threeHybrid = Club(name: "3 Hybrid", distance: 185)
        let fourIron = Club(name: "4 Iron", distance: 170)
        let fiveIron = Club(name: "5 Iron", distance: 160)
        let sixIron = Club(name: "6 Iron", distance: 150)
        let sevenIron = Club(name: "7 Iron", distance: 140)
        let eightIron = Club(name: "8 Iron", distance: 130)
        let nineIron = Club(name: "9 Iron", distance: 115)
        let pitchingWedge = Club(name: "Pitching Wedge", distance: 105)
        let sandWedge = Club(name: "Sand Wedge", distance: 80)
        let logWedge = Club(name: "Lob Wedge", distance: 70)
        
        let clubs = [driver, threeWood, fiveWood, threeHybrid, fourIron, fiveIron, sixIron, sevenIron, eightIron, nineIron, pitchingWedge, sandWedge, logWedge]
        self.activeClubs(clubs)
    }
    
    private func activeClubs(_ clubs:[Club]) {
        self.clubIds = clubs.map({$0.id})
        
        clubs.forEach({$0.activateClub()})
        
        self.myClubs.append(contentsOf: clubs)
        self.numberOfClubs = self.myClubs.count
    }
    
    public func getClubSuggestion(distanceTo: Int) -> Club? {
        var avgDistances:[Int] = [Int]()
        
        for c in self.myClubs {
            avgDistances.append(c.distance)
        }
        
        var clubNum:Int = 0
        //iterate until we hit the appropriate club
        //do not select a club num past our number of clubs in the bag
        while (clubNum < avgDistances.count - 1 && distanceTo < avgDistances[clubNum]) {
            clubNum += 1
        }
        
        guard clubNum < self.myClubs.count else {
            return nil
        }
        return self.myClubs[clubNum]
    }
    
    func removeClubFromBag(withIndexNumber index:Int) {
        let clubToDeactivate = myClubs.remove(at: index)
        clubToDeactivate.deactivateClub()
        
        self.numberOfClubs = myClubs.count
    }
    func removeClubFromBag(_ club:Club) {
        guard let foundIndex = myClubs.firstIndex(where: {$0.id == club.id}) else {
            return
        }
        
        let clubToDeactivate = myClubs.remove(at: foundIndex)
        clubToDeactivate.deactivateClub()
        self.numberOfClubs = myClubs.count
    }
    
    func addClub(_ club:Club) {
        var existingIds = self.clubIds
        existingIds.append(club.id)
        self.clubIds = existingIds
        
        club.activateClub()
        myClubs.append(club)
        self.numberOfClubs = myClubs.count
    }
    func moveClub(_ club:Club, from source: Int, to destination: Int) {
        self.myClubs.remove(at: source)
        self.myClubs.insert(club, at: destination)
    }
    func sortClubs() {
        //put clubs in proper order
        myClubs.sort(by: {$0.distance > $1.distance })
        
        for i in 0..<myClubs.count {
            myClubs[i].order = i
        }
    }
}
