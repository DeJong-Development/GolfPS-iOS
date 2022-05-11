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
