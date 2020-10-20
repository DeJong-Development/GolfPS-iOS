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
            prefs.synchronize()
        }
    }
    
    private(set) var myClubs:[Club] = [Club]()
    
    init() {
        for i in 1..<self.numberOfClubs + 1 {
            myClubs.append(Club(number: i));
        }
        
        sortClubs()
    }
    
    public func getClubSuggestion(distanceTo: Int) -> Club {
        var avgDistances:[Int] = [Int]()
        
        for c in self.myClubs {
            avgDistances.append(c.distance)
        }
        
        var clubNum:Int = 0;
        //iterate until we hit the appropriate club
        //do not select a club num past our number of clubs in the bag
        while (clubNum < avgDistances.count - 1 && distanceTo < avgDistances[clubNum]) {
            clubNum += 1;
        }
        
        return self.myClubs[clubNum]
    }
    
    func removeClubFromBag(withNumber number:Int) {
        guard let foundIndex = myClubs.firstIndex(where: {$0.number == number}) else {
            return
        }
        
        myClubs.remove(at: foundIndex)
        self.numberOfClubs = myClubs.count
    }
    func removeClubFromBag(_ club:Club) {
        guard let foundIndex = myClubs.firstIndex(where: {$0.number == club.number}) else {
            return
        }
        
        myClubs.remove(at: foundIndex)
        self.numberOfClubs = myClubs.count
    }
    
    func addClub(_ club:Club) {
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
    }
}
