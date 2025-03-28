//
//  MarkerTools.swift
//  GolfPS
//
//  Created by Greg DeJong on 5/29/24.
//  Copyright © 2024 DeJong Development. All rights reserved.
//

import Foundation
import FirebaseFirestore
import GoogleMaps

protocol MarkerToolsDelegate: AnyObject {
    func replacePinMarker(_ marker: GMSMarker?)
    func replaceTeeMarker(_ marker: GMSMarker?)
    func replaceBunkerMarkers(_ markers: [GMSMarker])
    func replaceLongDriveMarkers(_ markers: [GMSMarker])
    func replaceMyDriveMarker(_ marker: GMSMarker?)
    
    
    func replaceMyPlayerMarker(_ marker: GMSMarker?)
    func replaceOtherPlayerMarkers(_ markers: [GMSMarker])
}

class MarkerTools {
    
    //TODO: move markers to this class?
    
    weak var delegate: MarkerToolsDelegate?
    
    /// Update the current markers for the specified hole
    public func updateMarkers(pinMarker: GMSMarker?, teeMarker: GMSMarker?, bunkerMarkers: [GMSMarker], longDriveMarkers: [GMSMarker], myDriveMarker: GMSMarker?, hole: Hole, mapView: GMSMapView) {
        
        self.updatePinMarker(pinMarker, hole: hole, mapView: mapView)
        self.updateTeeMarker(teeMarker, hole: hole, mapView: mapView)
        self.updateBunkerMarkers(bunkerMarkers, hole: hole, mapView: mapView)
        
        self.updateLongDriveMarkers(longDriveMarkers, myDriveMarker: myDriveMarker, hole: hole, mapView: mapView)
    }
    
    public func updateLongDriveMarkers(_ longDriveMarkers: [GMSMarker], myDriveMarker: GMSMarker?, hole: Hole, mapView: GMSMapView) {
        let myDriveMarker = self.updateMyLongDriveMarker(myDriveMarker, hole: hole, mapView: mapView)
        self.delegate?.replaceMyDriveMarker(myDriveMarker)
        
        var longDriveMarkers = self.updateOtherLongDriveMarkers(longDriveMarkers, hole: hole, mapView: mapView)
        if let mydm = myDriveMarker {
            longDriveMarkers.append(mydm)
        }
        self.delegate?.replaceLongDriveMarkers(longDriveMarkers)
    }
    
    public func updatePinMarker(_ pinMarker: GMSMarker?, hole: Hole, mapView: GMSMapView) {
        let me:MePlayer = AppSingleton.shared.me
        let mapTools:MapTools = MapTools()
        
        let pinPoint:GeoPoint = hole.pinGeoPoint!
        let pinLoc:CLLocationCoordinate2D = pinPoint.location
        
        let teePoint:GeoPoint = hole.teeGeoPoints[0]
        let teeLoc:CLLocationCoordinate2D = teePoint.location
        let distanceToPin:Int = mapTools.distanceFrom(first: pinLoc, second: teeLoc)
        
        pinMarker?.map = nil
        
        let marker = GMSMarker(position: pinLoc)
        marker.title = "Pin #\(hole.number)"
        marker.snippet = distanceToPin.distance
        marker.icon = #imageLiteral(resourceName: "flag_marker").toNewSize(CGSize(width: 55, height: 55))
        marker.userData = "\(hole.number):P"
        marker.map = mapView
        marker.isDraggable = me.ambassadorCourses.contains(AppSingleton.shared.course!.id)
        
        self.delegate?.replacePinMarker(marker)
    }
    
    private func updateTeeMarker(_ teeMarker: GMSMarker?, hole: Hole, mapView: GMSMapView) {
        let teePoint:GeoPoint = hole.teeGeoPoints[0]
        let loc:CLLocationCoordinate2D = teePoint.location
        
        teeMarker?.map = nil
        
        let marker = GMSMarker(position: loc)
        marker.title = "Tee #\(hole.number)"
        marker.icon = #imageLiteral(resourceName: "tee_marker").toNewSize(CGSize(width: 55, height: 55))
        marker.userData = "\(hole.number):T"
        marker.map = mapView
        marker.isDraggable = AppSingleton.shared.me.ambassadorCourses.contains(AppSingleton.shared.course!.id)
        
        self.delegate?.replaceTeeMarker(marker)
    }
    
    public func updateBunkerMarkers(_ bunkerMarkers: [GMSMarker], hole: Hole, mapView: GMSMapView) {
        let mapTools:MapTools = MapTools()
        let me:MePlayer = AppSingleton.shared.me
        
        for bunkerMarker in bunkerMarkers {
            bunkerMarker.map = nil
        }
        
        var markers = [GMSMarker]()
        
        let bunkerLocationsForHole:[GeoPoint] = hole.bunkerGeoPoints
        for (bunkerIndex,bunkerLocation) in bunkerLocationsForHole.enumerated() {
            let bunkerLoc = bunkerLocation.location
            let teeLoc = hole.teeGeoPoints[0].location
            let distanceToBunker:Int = mapTools.distanceFrom(first: bunkerLoc, second: teeLoc)
            
            let bunkerMarker = GMSMarker(position: bunkerLoc)
            bunkerMarker.title = "Hazard"
            bunkerMarker.snippet = distanceToBunker.distance
            bunkerMarker.icon = #imageLiteral(resourceName: "hazard_marker").toNewSize(CGSize(width: 35, height: 35))
            bunkerMarker.userData = "\(hole.number):B\(bunkerIndex)"
            bunkerMarker.map = mapView
            bunkerMarker.isDraggable = me.ambassadorCourses.contains(AppSingleton.shared.course!.id)
            
            markers.append(bunkerMarker)
        }
        
        self.delegate?.replaceBunkerMarkers(markers)
    }
    
    private func updateOtherLongDriveMarkers(_ longDriveMarkers: [GMSMarker], hole: Hole, mapView: GMSMapView) -> [GMSMarker] {
        let mapTools:MapTools = MapTools()
        let me:MePlayer = AppSingleton.shared.me
        
        for ldMarker in longDriveMarkers {
            ldMarker.map = nil
        }
        
        var markers = [GMSMarker]()
        
        for longDrive in hole.longestDrives {
            let longDriveUser = longDrive.key
            
            if (longDriveUser == me.id) {
                continue
            } else {
                let longDriveLocation = longDrive.value
                
                let ldLoc = longDriveLocation.location
                let teeLoc = hole.teeGeoPoints[0].location
                
                let distanceToTee:Int = mapTools.distanceFrom(first: ldLoc, second: teeLoc)
                
                let driveMarker = GMSMarker(position: ldLoc)
                driveMarker.title = "Long Drive"
                driveMarker.snippet = distanceToTee.distance
                driveMarker.icon = #imageLiteral(resourceName: "marker-distance").toNewSize(CGSize(width: 25, height: 25))
                driveMarker.userData = "Drive"
                driveMarker.map = mapView
                
                markers.append(driveMarker)
            }
        }
        
        return markers
    }
    
    private func updateMyLongDriveMarker(_ myMarker: GMSMarker?, hole: Hole, mapView: GMSMapView) -> GMSMarker? {
        let mapTools:MapTools = MapTools()
        let me:MePlayer = AppSingleton.shared.me
        
        //remove my drive marker from the map
        myMarker?.map = nil
        
        guard let myLongDrive = hole.longestDrives.first(where: {$0.key == me.id}) else {
            return nil
        }
        
        let ldLoc = myLongDrive.value.location
        let teeLoc = hole.teeGeoPoints[0].location
        
        let distanceToTee:Int = mapTools.distanceFrom(first: ldLoc, second: teeLoc)
        
        let marker = GMSMarker(position: ldLoc)
        marker.title = "My Drive"
        if (AppSingleton.shared.metric) {
            marker.snippet = "\(distanceToTee) m"
        } else {
            marker.snippet = "\(distanceToTee) yds"
        }
        marker.icon = #imageLiteral(resourceName: "marker-distance-longdrive").toNewSize(CGSize(width: 30, height: 30))
        marker.userData = "Drive"
        marker.map = mapView
        
        return marker
    }
    
    
    // --------------------- PLAYER MARKERS -------------------- //
    
    
    public func updatePlayerMarker(_ playerMarker: GMSMarker?, playerImage: UIImage?, mapView: GMSMapView) {
        let me:MePlayer = AppSingleton.shared.me
        
        guard let loc:CLLocationCoordinate2D = me.geoPoint?.location, let bitmojiImage = playerImage else {
            self.delegate?.replaceMyPlayerMarker(nil)
            return
        }
        
        if let myMarker = playerMarker {
            myMarker.position = loc
            return
        }
        
        playerMarker?.map = nil
        
        let marker = GMSMarker(position: loc)
        marker.title = "Me"
        marker.icon = bitmojiImage.toNewSize(CGSize(width: 55, height: 55))
        marker.userData = "ME"
        marker.map = mapView
        
        self.delegate?.replaceMyPlayerMarker(marker)
    }
    
    public func updateOtherPlayerMarkers(_ otherPlayerMarkers: [GMSMarker], otherPlayers: [Player], mapView: GMSMapView) {
        //remove old markers from the array
        self.removeOldPlayerMarkers(otherPlayerMarkers, otherPlayers: otherPlayers)
        
        guard let course = AppSingleton.shared.course else {
            self.delegate?.replaceOtherPlayerMarkers([])
            return
        }
        
        var newPlayerMarkers:[GMSMarker] = otherPlayerMarkers.filter { $0.map != nil }
        
        for player in otherPlayers {
            var markerTitle:String = "Golfer"
            
            let randomDoubleLat = Double.random(in: -0.00001...0.00001)
            let randomDoubleLng = Double.random(in: -0.00001...0.00001)
            
            var playerLocation:CLLocationCoordinate2D!
            if let playerGeoPoint:GeoPoint = player.geoPoint {
                playerLocation = playerGeoPoint.location
                
                // Check to see if player is within course bounds
                if let courseSpec = course.spectation, !course.bounds.contains(playerLocation) {
                    //not within course bounds - lets put them as spectator
                    playerLocation = CLLocationCoordinate2D(latitude: courseSpec.latitude + randomDoubleLat, longitude: courseSpec.longitude + randomDoubleLng)
                    markerTitle = "Spectator"
                }
            } else if let courseSpec = course.spectation {
                playerLocation = CLLocationCoordinate2D(latitude: courseSpec.latitude + randomDoubleLat, longitude: courseSpec.longitude + randomDoubleLng)
                markerTitle = "Spectator"
            } else {
                print("No valid player or course location")
                continue
            }
            
            var userDataForMarker:[String:Any] = ["userId":player.id, "snap":false]
            var opMarker:GMSMarker! = nil
            
            //check for existing markers first
            //update icon if there was some sort of change to the player
            for marker in newPlayerMarkers {
                guard let data = marker.userData as? [String:Any], data["userId"] as? String == player.id else {
                    continue
                }
                
                opMarker = marker
                
                marker.position = playerLocation
                if let avatar = player.avatarURL, data["snap"] == nil || data["snap"] as? Bool == false {
                    //did not store icon on marker initially but now have player avatar url
                    //add snap icon
                    userDataForMarker["snap"] = true
                    self.getData(from: avatar) { data, response, error in
                        guard let data = data, error == nil else { return }
                        DispatchQueue.main.async {
                            opMarker.icon = UIImage(data: data)?.toNewSize(CGSize(width: 35, height: 35))
                        }
                    }
                } else if data["snap"] as? Bool == true && player.avatarURL == nil {
                    //did store icon on marker initially but now have no player avatar url
                    //remove snap icon
                    userDataForMarker["snap"] = false
                    opMarker.icon =  #imageLiteral(resourceName: "player_marker").toNewSize(CGSize(width: 35, height: 35))
                } else {
                    userDataForMarker["snap"] = data["snap"] as? Bool ?? false
                }
                break;
            }
        
            //if no existing marker was found for this player, then create a new one
            if opMarker == nil {
                
                opMarker = GMSMarker(position: playerLocation)
                opMarker.icon =  #imageLiteral(resourceName: "player_marker").toNewSize(CGSize(width: 35, height: 35))
                
                //if player has specified avatar then add the icon to the marker
                if let avatar = player.avatarURL {
                    userDataForMarker["snap"] = true
                    self.getData(from: avatar) { data, response, error in
                        guard let data = data, error == nil else { return }
                        DispatchQueue.main.async {
                            opMarker.icon = UIImage(data: data)?.toNewSize(CGSize(width: 35, height: 35))
                        }
                    }
                } else {
                    userDataForMarker["snap"] = false
                }
                
                newPlayerMarkers.append(opMarker)
            }
            
            //attached the potentially updated user data to the marker
            opMarker.userData = userDataForMarker
            opMarker.title = markerTitle
            
            let timeSinceLastLocationUpdate = player.lastLocationUpdate?.dateValue().timeIntervalSinceNow ?? 1000
            opMarker.opacity = timeSinceLastLocationUpdate < -60 ? 0.75 : 1
            opMarker.map = mapView
        }
        
        //update the array
        let markers = newPlayerMarkers.filter { $0.map != nil }
        
        self.delegate?.replaceOtherPlayerMarkers(markers)
    }
    
    private func removeOldPlayerMarkers(_ otherPlayerMarkers: [GMSMarker], otherPlayers: [Player]) {
        for marker in otherPlayerMarkers {
            guard let markerUserData = marker.userData as? [String:Any],
                let markerPlayerId = markerUserData["userId"] as? String else {
                marker.map = nil
                continue
            }
                
            var foundValidPlayer:Bool = false
            for player in otherPlayers {
                if player.id == markerPlayerId {
                    if let updateDate = player.lastLocationUpdate?.dateValue() {
                        let timeSinceLastLocationUpdate = updateDate.timeIntervalSinceNow
                        if (timeSinceLastLocationUpdate > -14400) { //remove after 4 hours
                            foundValidPlayer = true
                        }
                    }
                    break
                }
            }
            
            if (!foundValidPlayer) {
                marker.map = nil
            }
        }
    }
    
    private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
}
