//
//  GolfShotRoute.swift
//  GolfPS
//
//  Created by Greg DeJong on 3/26/24.
//  Copyright © 2024 DeJong Development. All rights reserved.
//

import Foundation
import FirebaseFirestore
import GoogleMaps

class GolfShotRoute {
    
    private let me:MePlayer = AppSingleton.shared.me
    
    private(set) var teeGeopoint:GeoPoint!
    private(set) var dogLegGeopoint:GeoPoint? = nil
    private(set) var bunkerGeopoints:[GeoPoint] = []
    private(set) var pinGeopoint:GeoPoint!
    private(set) var fairway:GMSPath? = nil
    
    private(set) var club1:Club!
    private(set) var club2:Club!
    
    /// Golf route target that we are attempting to hit to on the tee shot
    private(set) var teeTarget:GeoPoint!
    
    /// Golf route target that we are attempting to hit to on the second shot
    private(set) var secondShotTarget:GeoPoint!
    
    /// The number of shots if every hit was perfect
    private var perfectTeeTarget:GeoPoint!
    private var perfectSecondShotTarget:GeoPoint!
    private(set) var optimalNumberOfShots:Int = 0
    
    private let mapTools = MapTools()
    
    private(set) var totalNumberOfIterations:Double = 0
    private(set) var totalNumberOfShots:Double = 0
    private(set) var averageNumberOfShots:Double = 0
    
    private var didPuttOut:Bool = false
    private var numberOfHits:Int = 0
    
    init(club1: Club, club2: Club, hole: Hole) {
        self.teeGeopoint = hole.teeLocations.first!
        self.dogLegGeopoint = hole.dogLegLocation
        self.bunkerGeopoints = hole.bunkerLocations
        self.pinGeopoint = hole.pinLocation
        self.fairway = hole.fairwayPath
        
        self.club1 = club1
        self.club2 = club2
    }
    
    /// Come up with a first best guess at the locations to hit to from the tee and the second shot. Ideally this should be used for Par 4 golf holes as a Par 5 may require optimization on the 3rd shot as well.
    internal func applyInitialBearingDeviations(teeShotDeviation: Double, secondShotDeviation: Double) {
        
        let teeshotDistance:Double = Double(club1.distance)
        let teeshotTarget:GeoPoint = dogLegGeopoint ?? pinGeopoint
        let teeshotBearing = mapTools.calcBearing(start: teeGeopoint, finish: teeshotTarget)
        self.perfectTeeTarget = mapTools.coordinates(startingCoordinates: teeGeopoint.location, atDistance: teeshotDistance, atAngle: teeshotBearing).geopoint
        self.teeTarget = mapTools.coordinates(startingCoordinates: teeGeopoint.location, atDistance: teeshotDistance, atAngle: teeshotBearing + teeShotDeviation).geopoint
        
        let secondShotTarget:GeoPoint = pinGeopoint
        let secondShotDistance:Double = Double(club2.distance)
        let secondShotBearing = mapTools.calcBearing(start: self.teeTarget, finish: secondShotTarget)
        self.perfectSecondShotTarget = mapTools.coordinates(startingCoordinates: self.teeTarget.location, atDistance: secondShotDistance, atAngle: secondShotBearing).geopoint
        self.secondShotTarget = mapTools.coordinates(startingCoordinates: self.teeTarget.location, atDistance: secondShotDistance, atAngle: secondShotBearing + secondShotDeviation).geopoint
        
        // Generate optimal number of shots for route
        self.playHolePerfectly()
    }
    
    private func playHolePerfectly() {
        self.optimalNumberOfShots = 0
        self.totalNumberOfShots = 0
        self.averageNumberOfShots = 0
        
        self.numberOfHits = 0
        self.didPuttOut = false
        
        self.hitShot(start: self.teeGeopoint, target: self.perfectTeeTarget, shotNum: 1, roundNum: 0, isPerfect: true)
        
        self.optimalNumberOfShots = Int(self.totalNumberOfShots)
        self.totalNumberOfIterations = 1
    }
    
    internal func playHole(numInterations: Int) {
        guard numInterations > 0 else {
            DebugLogger.report(error: nil, message: "Unable to play hole less than 1 time.")
            return
        }
        
        for i in 0..<numInterations {
            self.numberOfHits = 0
            self.didPuttOut = false
            self.hitShot(start: teeGeopoint, target: teeTarget, shotNum: 1, roundNum: i)
        }
        
        if (totalNumberOfShots <= 0) {
            DebugLogger.report(error: nil, message: "There should always be at least 1 shot.")
            return
        }
        
        self.totalNumberOfIterations += Double(numInterations)
        self.averageNumberOfShots = Double(self.totalNumberOfShots) / self.totalNumberOfIterations
        
        if (averageNumberOfShots <= 0) {
            DebugLogger.report(error: nil, message: "There should always be at least 1 shot.")
            return
        }
        
        self.averageNumberOfShots = Double(Int(100 * averageNumberOfShots)) / 100
    }
    
    private func hitShot(start startGP: GeoPoint, target targetGP: GeoPoint, shotNum: Int, roundNum: Int, isPerfect: Bool = false) {
        numberOfHits += 1
        
        let distanceToTarget = mapTools.distanceFrom(first: startGP, second: targetGP)
        let distanceToPin = mapTools.distanceFrom(first: startGP, second: self.pinGeopoint)
        let bearingToTarget = mapTools.calcBearing(start: startGP, finish: targetGP)
        
        var club:Club!
        if shotNum == 1 {
            club = club1
        } else if shotNum == 2 {
            club = club2
        } else {
            club = me.bag.getClubSuggestion(distanceTo: distanceToPin)!
        }
        
        var shotBearing:Double = 0
        var shotDistance:Double = 0
        if isPerfect {
            shotBearing = bearingToTarget
            shotDistance = Double((distanceToTarget > 90) ? club.distance : distanceToTarget)
        } else {
            let angleStdDeviation:Double = 8
            let randomDispersion = Double(0).gaussianRandom(stdDev: angleStdDeviation)
            shotBearing = bearingToTarget + randomDispersion
            
            let targetDistance = (distanceToTarget > 90) ? club.distance : distanceToTarget
            let clubStdDeviation = 0.08 * Double(targetDistance)
            shotDistance = Double(targetDistance).gaussianRandom(stdDev: clubStdDeviation)
        }
        
        let shotLandingCoordinates = mapTools.coordinates(startingCoordinates: startGP.location, atDistance: Double(shotDistance), atAngle: shotBearing)
        let remainingDistanceToPin = mapTools.distanceFrom(first: shotLandingCoordinates.geopoint, second: self.pinGeopoint)
        
        if remainingDistanceToPin < 2 {
            // Close enough for 1 putt
            self.totalNumberOfShots += Double(shotNum + 1)
            self.didPuttOut = true
            return
        } else if distanceToPin < 10 {
            // Close enough for 2 putt or scrambling
            self.totalNumberOfShots += Double(shotNum + 2)
            self.didPuttOut = true
            return
        } else {
            // Not close enough to pin, need to hit again
            var nextShotStartLocation:CLLocationCoordinate2D = shotLandingCoordinates
            
            var shotPenalty:Int = 0
            
            if let fairway = self.fairway, !GMSGeometryContainsLocation(shotLandingCoordinates, fairway, true) {
                // landed outside of the fairway
                
                // add stroke penalty
                shotPenalty = 0
                
                if (shotNum == 1) {
                    // add distance penalty
                    var penaltyDistance:Double = 0
                    var isBackInFairway = false
                    var dropLocation:CLLocationCoordinate2D = nextShotStartLocation
                    while !isBackInFairway && penaltyDistance < shotDistance {
                        penaltyDistance += 5
                        // go back penalty distance and see if it is in the fairway
                        dropLocation = mapTools.coordinates(startingCoordinates: startGP.location, atDistance: shotDistance - penaltyDistance, atAngle: shotBearing)
                        
                        isBackInFairway = GMSGeometryContainsLocation(dropLocation, fairway, true)
                    }
                    
                    nextShotStartLocation = dropLocation
                    
                    // extra penalty for missing safe area with first shot
                    shotPenalty += 2
                } else if (shotNum == 2) {
                    shotPenalty += 1
                }
            }
            
            for bunkerGP in self.bunkerGeopoints {
                let distanceToBunker = mapTools.distanceFrom(first: shotLandingCoordinates, second: bunkerGP.location)
                if distanceToBunker < 10 {
                    // landed in hazard
                    shotPenalty = 3
                    break
                }
            }
            
            if (shotNum == 1) {
                hitShot(start: nextShotStartLocation.geopoint, target: self.secondShotTarget, shotNum: shotNum + 1 + shotPenalty, roundNum: roundNum, isPerfect: isPerfect)
            } else {
                hitShot(start: nextShotStartLocation.geopoint, target: self.pinGeopoint, shotNum: shotNum + 1 + shotPenalty, roundNum: roundNum, isPerfect: isPerfect)
            }
        }
    }
    
}
