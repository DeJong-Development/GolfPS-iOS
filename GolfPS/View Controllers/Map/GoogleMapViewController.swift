//
//  GoogleMapViewController.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/19/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import AudioToolbox
import SCSDKBitmojiKit
import SCSDKLoginKit

extension GoogleMapViewController: HoleUpdateDelegate {
    func didUpdateLongDrive() {
        updateLongDriveMarkers()
    }
}

extension GoogleMapViewController: LocationUpdateTimerDelegate, PlayerUpdateTimerDelegate {
    func updatePlayersNow() {
        updateOtherPlayerMarkers();
    }
    
    func updateLocationsNow() {
        if let cpl = currentPlayerLocation {
            
            //get difference in yards between old and new locations
            var yardsBetweenLocations:Int = 25
            if let ppl = previousPlayerLocation {
                yardsBetweenLocations = mapTools.distanceFrom(first: cpl, second: ppl)
            }
            
            //if we are in different location then update the position of the player
            if (cpl != previousPlayerLocation && yardsBetweenLocations >= 25) {
                updateFirestorePlayerPosition(with: cpl.geopoint)
            }
            
            //update previous location on device regardless of distance
            AppSingleton.shared.me.location = cpl.geopoint
        }
    }
}

extension GoogleMapViewController: CLLocationManagerDelegate {
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let isAuthorized:Bool = (status == .authorizedWhenInUse || status == .authorizedAlways)
        self.mapView.isMyLocationEnabled = isAuthorized
        mapView.settings.myLocationButton = isAuthorized
        
        //remove information associated with current locatino if we become unauthorized
        if (!isAuthorized) {
            currentPlayerLocation = nil
        }
    }
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentPlayerLocation = locations.last
        
        if let cpl = currentPlayerLocation {
            if let pm = currentPinMarker {
                let yardsToPin:Int = mapTools.distanceFrom(first: cpl.coordinate, second: pm.position)
                delegate.updateDistanceToPin(distance: yardsToPin)
                
                let suggestedClub:Club = clubTools.getClubSuggestion(ydsTo: yardsToPin)
                delegate.updateSelectedClub(club: suggestedClub)
                
                //update any suggestion lines
                updateSuggestionLines(with: suggestedClub)
            }
            
            //update any distance markers we already have displayed when we update our location
            updateDistanceMarker()
        }
    }
}

class GoogleMapViewController: UIViewController, GMSMapViewDelegate {
    
    let mapTools:MapTools = MapTools();
    let clubTools:ClubTools = ClubTools();
    
    var db:Firestore { return AppSingleton.shared.db }
    var mapView:GMSMapView!
    var delegate:ViewUpdateDelegate!
    
    var locationTimer:LocationUpdateTimer!
    var otherPlayerTimer:PlayerUpdateTimer!
    
    let locationManager = CLLocationManager()
    var previousPlayerLocation:CLLocation? {
        if let gp = AppSingleton.shared.me.location {
            return CLLocation(latitude: gp.latitude, longitude: gp.longitude)
        }
        return nil
    }
    var currentPlayerLocation:CLLocation? {
        didSet {
            if let myMarker = myPlayerMarker, let location = currentPlayerLocation?.coordinate {
                myMarker.position = location
            } else if (currentPlayerLocation?.coordinate) != nil {
                createPlayerMarker()
            }
        }
    }
    
    internal var currentHole:Hole!
    
    private var playerListener:ListenerRegistration? = nil
    
    private var otherPlayers:[Player] = [Player]()
    private var otherPlayerMarkers:[GMSMarker] = [GMSMarker]();
    private var myPlayerMarker:GMSMarker?
    private var myPlayerImage:UIImage? {
        didSet {
            self.createPlayerMarker()
        }
    }
    
    private var myDrivingDistanceMarker:GMSMarker?
    private var currentPinMarker:GMSMarker!
    private var currentTeeMarker:GMSMarker!
    private var currentBunkerMarkers:[GMSMarker] = [GMSMarker]();
    private var currentLongDriveMarkers:[GMSMarker] = [GMSMarker]();
    private var currentDistanceMarker:GMSMarker?
    
    private var isDraggingDistanceMarker:Bool = false
    
    private var drivingDistanceLines:[GMSPolyline] = [GMSPolyline]();
    private let drivingDistanceLineColors:[UIColor] = [UIColor.green, UIColor.yellow, UIColor.orange];
    
    private var suggestedDistanceLines:[GMSPolyline] = [GMSPolyline]();
    
    private var lineToMyLocation:GMSPolyline?
    private var lineToPin:GMSPolyline?
    
    private var yardsToPressFromLocation:Int? {
        if let playerLocation = currentPlayerLocation,
            let pressLocation = currentDistanceMarker?.position {
            return mapTools.distanceFrom(first: playerLocation.coordinate, second: pressLocation)
        }
        return nil
    }
    private var yardsToPressFromTee:Int? {
        if let pressLocation = currentDistanceMarker?.position,
            let teeLocation = currentTeeMarker?.position {
            return mapTools.distanceFrom(first: teeLocation, second: pressLocation)
        }
        return nil
    }
    private var yardsToPinFromMyLocation:Int? {
        if let playerLocation = currentPlayerLocation,
            let pinLocation = currentPinMarker?.position {
            return mapTools.distanceFrom(first: playerLocation.coordinate, second: pinLocation)
        }
        return nil
    }
    private var yardsToTeeFromMyLocation:Int? {
        if let playerCoord = currentPlayerLocation?.coordinate,
            let teeCoord = currentTeeMarker?.position {
            return mapTools.distanceFrom(first: playerCoord, second: teeCoord)
        }
        return nil
    }
    private var yardsToPinFromTee:Int? {
        if let tp = currentTeeMarker?.position,
            let pp = currentPinMarker?.position {
            return mapTools.distanceFrom(first: tp, second: pp)
        }
        return nil
    }
    
    private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    // Wrapper for obtaining keys from keys.plist
    private func valueForAPIKey(keyname:String) -> String {
        // Get the file path for keys.plist
        if let filePath = Bundle.main.path(forResource: "ApiKeys", ofType: "plist") {
            // Put the keys in a dictionary
            if let plist = NSDictionary(contentsOfFile: filePath) {
                // Pull the value for the key
                if let value:String = plist.object(forKey: keyname) as? String {
                    return value
                }
            }
        }
        return "no-key-found"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !SCSDKLoginClient.isUserLoggedIn {
            myPlayerImage = nil
        } else if myPlayerImage == nil {
            downloadBitmojiImage()
        }
        
        AppSingleton.shared.me.lastLocationUpdate = nil
        AppSingleton.shared.me.location = nil
        
        if let course = AppSingleton.shared.course {
            locationTimer.invalidate()
            locationTimer.delegate = self
            locationTimer.startNewTimer(interval: 15)
            
            listenToPlayerLocationsOnCourse(with: course.id)
            
            self.goToHole()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerListener?.remove()
    }
    
    //first
    override func loadView() {
        super.loadView()
        GMSServices.provideAPIKey(valueForAPIKey(keyname: "GoogleMaps"))

        self.view = mapView
        
        let camera = GMSCameraPosition.camera(withLatitude: 40, longitude: -75, zoom: 2.0)
        self.mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        self.mapView.mapType = GMSMapViewType.satellite
        view = mapView
    }
    
    //second
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.delegate = self;
        
        locationManager.delegate = self;
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        
        locationManager.startUpdatingLocation()
        
        locationTimer = LocationUpdateTimer()
        locationTimer.delegate = self
        
        otherPlayerTimer = PlayerUpdateTimer()
        otherPlayerTimer.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func downloadBitmojiImage() {
        SCSDKBitmojiClient.fetchAvatarURL { (avatarURL: String?, error: Error?) in
            if let urlString = avatarURL, let url = URL(string: urlString) {
                self.getData(from: url) { data, response, error in
                    guard let data = data, error == nil else { return }
                    DispatchQueue.main.async() {
                        self.myPlayerImage = UIImage(data: data)
                    }
                }
            }
        }
    }
    
    private func updateFirestorePlayerPosition(with location: GeoPoint) {
        let userId = AppSingleton.shared.me.id
        
        if AppSingleton.shared.me.shareLocation {
            if let id = AppSingleton.shared.course?.id {
                db.collection("players")
                    .document(userId)
                    .setData([
                        "course": id,
                        "location": location,
                        "updateTime": Date().iso8601
                        ], merge: true, completion: { (err) in
                            if let err = err {
                                print("Error updating location: \(err)")
                            } else {
                                print("Document successfully written!")
                            }
                    })
            } else {
                //no course so delete
                db.collection("players").document(userId).delete()
                locationTimer.invalidate()
            }
        } else {
            locationTimer.invalidate()
        }
    }
    
    private func listenToPlayerLocationsOnCourse(with id: String) {
        otherPlayerTimer.invalidate()
        otherPlayerTimer.delegate = self
        otherPlayerTimer.startNewTimer(interval: 15)
        
        playerListener?.remove();
        
        //grab course hole information
        playerListener = db.collection("players")
            .whereField("course", isEqualTo: id)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                let location = documents.map { $0["location"]! }
                print("Current players on course: \(location)")
                
                self.otherPlayers.removeAll()
                for document in documents {
                    let otherPlayer = Player()
                    otherPlayer.id = document.documentID;
                    otherPlayer.location = document["location"] as? GeoPoint
                    otherPlayer.lastLocationUpdate = (document["updateTime"] as? String)?.dateFromISO8601
                    
                    if let imageStr = document["image"] as? String, imageStr != "" {
                        otherPlayer.avatarURL = URL(string: imageStr)
                    }
                    
                    if let timeSinceLastLocationUpdate = otherPlayer.lastLocationUpdate?.timeIntervalSinceNow,
                        timeSinceLastLocationUpdate > -14400 {
                        //only add player to array if they are within the correct time period
                        self.otherPlayers.append(otherPlayer)
                    }
                }
                
                self.updateOtherPlayerMarkers()
        }
    }
    
    public func goToHole(increment: Int = 0) {
        guard let course = AppSingleton.shared.course else {
            return
        }
        
        currentDistanceMarker?.map = nil;
        currentDistanceMarker = nil;
        lineToPin?.map = nil;
        lineToMyLocation?.map = nil;
        
        //remove old listener just in case we are still loading the driving distance markers
        //could result in a race condition while we are searching for the new current hole?
        currentHole?.updateDelegate = nil
        
        var holeNum = currentHole?.number ?? 1 //default to hole number 1
        holeNum += increment;
        if (holeNum > course.holeInfo.count) {
            holeNum = 1;
        } else if holeNum <= 0 {
            holeNum = course.holeInfo.count
        }
        for hole in course.holeInfo {
            if (hole.number == holeNum) {
                currentHole = hole
                break;
            }
        }
        
        currentHole.updateDelegate = self
        
        delegate.updateCurrentHole(hole: currentHole);
        
        if (currentHole != nil) {
            updatePinMarker();
            updateTeeMarker();
            updateBunkerMarkers();
            updateLongDriveMarkers();
            
            //TODO update ui if hole is long drive hole
            
            moveCamera(to: currentHole.bounds, orientToHole: true);
            
            mapView.selectedMarker = currentPinMarker
            
            var ydsToUseInSuggestion:Int = 300
            if let ydsPinMe = yardsToPinFromMyLocation {
                ydsToUseInSuggestion = ydsPinMe
                delegate.updateDistanceToPin(distance: ydsPinMe)
            } else if let ydsPinTee = yardsToPinFromTee {
                ydsToUseInSuggestion = ydsPinTee
                delegate.updateDistanceToPin(distance: ydsPinTee)
            }
            
            let suggestedClub:Club = clubTools.getClubSuggestion(ydsTo: ydsToUseInSuggestion)
            delegate.updateSelectedClub(club: suggestedClub)
            
            updateSuggestionLines(with: suggestedClub)
        }
    }
    
    private func moveCamera(to bounds:GMSCoordinateBounds, orientToHole:Bool) {
        let zoom:Float = mapTools.getBoundsZoomLevel(bounds: bounds, screenSize: view.frame)
        let center:CLLocationCoordinate2D = mapTools.getBoundsCenter(bounds);
        
        var bearing:Double = 0
        var viewingAngle:Double = 0
        if (orientToHole) {
            let teeLocation:GeoPoint = currentHole.teeLocations[0]
            let pinLocation:GeoPoint = currentHole.pinLocation!
            bearing = mapTools.calcBearing(start: teeLocation, finish: pinLocation) - 20
            viewingAngle = 45
        }
//        if let dlLocation = currentHole.dogLegLocation {
//            bearing = mapTools.calcBearing(start: teeLocation, finish: dlLocation)
//        }
        let newCameraView:GMSCameraPosition = GMSCameraPosition(target: center,
                                                                zoom: zoom,
                                                                bearing: bearing,
                                                                viewingAngle: viewingAngle)
        mapView.animate(to: newCameraView)
    }
    
    
    private func removeOldPlayerMarkers() {
        for marker in otherPlayerMarkers {
            if let markerUserData = marker.userData as? [String:Any],
                let markerPlayerId = markerUserData["userId"] as? String {
                
                var foundValidPlayer:Bool = false
                for player in self.otherPlayers {
                    if player.id == markerPlayerId {
                        if let updateDate = player.lastLocationUpdate {
                            let timeSinceLastLocationUpdate = updateDate.timeIntervalSinceNow
                            if (timeSinceLastLocationUpdate > -14400) { //remove after 4 hours
                                foundValidPlayer = true
                            }
                        }
                        break;
                    }
                }
                
                if (!foundValidPlayer) {
                    marker.map = nil
                }
            } else {
                marker.map = nil
            }
        }
    }
    
    private func updateOtherPlayerMarkers() {
        //remove old markers from the array
        removeOldPlayerMarkers()
        
        guard let course = AppSingleton.shared.course else {
            return
        }
        
        var newPlayerMarkers:[GMSMarker] = otherPlayerMarkers.filter { $0.map != nil }
        
        for player in self.otherPlayers {
            if let playerGeoPoint:GeoPoint = player.location,
                player.id != AppSingleton.shared.me.id {
                
                var markerTitle:String = "Golfer"
                
                var playerLocation = CLLocationCoordinate2D(latitude: playerGeoPoint.latitude, longitude: playerGeoPoint.longitude)
                if let courseSpec = course.spectation, !course.bounds.contains(playerLocation) {
                    //not within course bounds - lets put them as spectator
                    let randomDoubleLat = Double.random(in: -0.00001...0.00001)
                    let randomDoubleLng = Double.random(in: -0.00001...0.00001)
                    playerLocation = CLLocationCoordinate2D(latitude: courseSpec.latitude + randomDoubleLat,
                                                            longitude: courseSpec.longitude + randomDoubleLng)
                    markerTitle = "Spectator"
                }
                
                var userDataForMarker:[String:Any] = ["userId":player.id, "snap":false]
                var opMarker:GMSMarker! = nil
                
                //check for existing markers first
                //update icon if there was some sort of change to the player
                for marker in newPlayerMarkers {
                    if let data = marker.userData as? [String:Any], data["userId"] as? String == player.id {
                        opMarker = marker;
                        
                        marker.position = playerLocation
                        if let avatar = player.avatarURL, data["snap"] == nil || data["snap"] as? Bool == false {
                            //did not store icon on marker initially but now have player avatar url
                            //add snap icon
                            userDataForMarker["snap"] = true
                            self.getData(from: avatar) { data, response, error in
                                guard let data = data, error == nil else { return }
                                DispatchQueue.main.async() {
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
                            DispatchQueue.main.async() {
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
                
                let timeSinceLastLocationUpdate = player.lastLocationUpdate?.timeIntervalSinceNow ?? 1000
                opMarker.opacity = timeSinceLastLocationUpdate < -60 ? 0.75 : 1
                opMarker.map = self.mapView
            } else {
                //no location data available for user or myself
            }
        }
        
        //update the array
        otherPlayerMarkers = newPlayerMarkers.filter { $0.map != nil }
    }
    
    internal func addDrivePrompt() {
        let ac = UIAlertController(title: "Add Long Drive Here?", message: "Your drive will be added to this hole and potentially be used in future long drive competitions (testing this feature).", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Yes", style: .default) { action in
            //add a driving distance marker and select it
            if (self.myDrivingDistanceMarker != nil) {
                self.myDrivingDistanceMarker!.map = nil
            }
            
            if let loc:CLLocationCoordinate2D = self.currentPlayerLocation?.coordinate {
                let yardsToTee:Int = self.mapTools.distanceFrom(first: self.currentHole.teeLocations[0], second: loc.geopoint)
                
                if (yardsToTee > 500) {
                    //prompt some sort of alert saying this is just ridiculous
                } else {
                    self.myDrivingDistanceMarker = GMSMarker(position: loc)
                    self.myDrivingDistanceMarker!.title = "My Drive"
                    self.myDrivingDistanceMarker!.snippet = "\(yardsToTee) yds"
                    self.myDrivingDistanceMarker!.icon = #imageLiteral(resourceName: "marker-distance-longdrive").toNewSize(CGSize(width: 30, height: 30))
                    self.myDrivingDistanceMarker!.userData = "Drive";
                    self.myDrivingDistanceMarker!.map = self.mapView;
                    self.mapView.selectedMarker = self.myDrivingDistanceMarker!;
                    
                    //update my drive data on hole object
                    self.currentHole.myLongestDrive = yardsToTee
                    self.currentHole.longestDrives[AppSingleton.shared.me.id] = loc.geopoint
                    
                    //send drive data to the firestore
                    self.updateFirestoreLongDrive(distance: yardsToTee, location: loc.geopoint)
                    
                    //inform delegate of new hole characteristics
                    self.delegate?.updateCurrentHole(hole: self.currentHole)
                }
            }
        })
        ac.addAction(UIAlertAction(title: "No", style: .default))
        self.present(ac, animated: true)
    }
    
    private func updateFirestoreLongDrive(distance:Int, location: GeoPoint) {
        let userId = AppSingleton.shared.me.id
        
        if let holeDocRef = currentHole.docReference {
            let myLongDriveDoc = holeDocRef.collection("drives").document(userId);
            myLongDriveDoc.setData([
                "location": location,
                "distance": distance,
                "date": Date().iso8601
            ]) { (error) in
                if let err = error {
                    print("Error adding long drive: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
        }
    }
    
    private func createPlayerMarker() {
        if (myPlayerMarker != nil) {
            myPlayerMarker!.map = nil
        }
        if let loc:CLLocationCoordinate2D = currentPlayerLocation?.coordinate,
            let bitmojiImage = self.myPlayerImage {
            myPlayerMarker = GMSMarker(position: loc)
            myPlayerMarker!.title = "Me"
            myPlayerMarker!.icon = bitmojiImage.toNewSize(CGSize(width: 55, height: 55))
            myPlayerMarker!.userData = "ME";
            myPlayerMarker!.map = mapView;
        }
    }
    
    private func updateTeeMarker() {
        if (currentTeeMarker != nil) {
            currentTeeMarker.map = nil
        }
        let teePoint:GeoPoint = currentHole.teeLocations[0];
        let loc:CLLocationCoordinate2D = teePoint.location
        
        currentTeeMarker = GMSMarker(position: loc)
        currentTeeMarker.title = "Tee #\(currentHole.number)"
        currentTeeMarker.icon = #imageLiteral(resourceName: "tee_marker").toNewSize(CGSize(width: 55, height: 55))
        currentTeeMarker.userData = "\(currentHole.number):T";
        currentTeeMarker.map = mapView;
    }
    private func updatePinMarker() {
        let pinPoint:GeoPoint = currentHole.pinLocation!
        let pinLoc:CLLocationCoordinate2D = pinPoint.location
        
        let teePoint:GeoPoint = currentHole.teeLocations[0]
        let teeLoc:CLLocationCoordinate2D = teePoint.location
        let yardsToPin:Int = mapTools.distanceFrom(first: pinLoc, second: teeLoc)
        
        if (currentPinMarker != nil) {
            currentPinMarker.map = nil
        }
        currentPinMarker = GMSMarker(position: pinLoc)
        currentPinMarker.title = "Pin #\(currentHole.number)"
        currentPinMarker.snippet = "\(yardsToPin) yds"
        currentPinMarker.icon = #imageLiteral(resourceName: "flag_marker").toNewSize(CGSize(width: 55, height: 55))
        currentPinMarker.userData = "\(currentHole.number):P";
        currentPinMarker.map = mapView;
    }
    private func updateBunkerMarkers() {
        for bunkerMarker in currentBunkerMarkers {
            bunkerMarker.map = nil
        }
        currentBunkerMarkers.removeAll()
        
        let bunkerLocationsForHole:[GeoPoint] = currentHole.bunkerLocations
        for (bunkerIndex,bunkerLocation) in bunkerLocationsForHole.enumerated() {
            let bunkerLoc = bunkerLocation.location
            let teeLoc = currentTeeMarker.position
            let yardsToBunker:Int = mapTools.distanceFrom(first: bunkerLoc, second: teeLoc)
            
            let bunkerMarker = GMSMarker(position: bunkerLoc)
            bunkerMarker.title = "Hazard"
            bunkerMarker.snippet = "\(yardsToBunker) yds"
            bunkerMarker.icon = #imageLiteral(resourceName: "hazard_marker").toNewSize(CGSize(width: 35, height: 35))
            bunkerMarker.userData = "\(currentHole.number):B\(bunkerIndex)";
            bunkerMarker.map = mapView;
            
            currentBunkerMarkers.append(bunkerMarker);
        }
    }
    private func updateLongDriveMarkers() {
        for ldMarker in currentLongDriveMarkers {
            ldMarker.map = nil
        }
        currentLongDriveMarkers.removeAll()
        
        //remove my drive marker from the map
        if (self.myDrivingDistanceMarker != nil) {
            self.myDrivingDistanceMarker!.map = nil
        }
        self.myDrivingDistanceMarker = nil
        
        for longDrive in currentHole.longestDrives {
            let longDriveUser = longDrive.key
            let longDriveLocation = longDrive.value
            
            let ldLoc = longDriveLocation.location
            let teeLoc = currentTeeMarker.position
            
            let yardsToTee:Int = mapTools.distanceFrom(first: ldLoc, second: teeLoc)
            
            if (longDriveUser == AppSingleton.shared.me.id) {
                self.myDrivingDistanceMarker = GMSMarker(position: ldLoc)
                self.myDrivingDistanceMarker!.title = "My Drive"
                self.myDrivingDistanceMarker!.snippet = "\(yardsToTee) yds"
                self.myDrivingDistanceMarker!.icon = #imageLiteral(resourceName: "marker-distance-longdrive").toNewSize(CGSize(width: 30, height: 30))
                self.myDrivingDistanceMarker!.userData = "Drive";
                self.myDrivingDistanceMarker!.map = self.mapView;
                currentLongDriveMarkers.append(myDrivingDistanceMarker!);
            } else {
                let driveMarker = GMSMarker(position: ldLoc)
                driveMarker.title = "Long Drive"
                driveMarker.snippet = "\(yardsToTee) yds"
                driveMarker.icon = #imageLiteral(resourceName: "marker-distance").toNewSize(CGSize(width: 25, height: 25))
                driveMarker.userData = "Drive";
                driveMarker.map = self.mapView;
                currentLongDriveMarkers.append(driveMarker);
            }
        }
    }
    
    internal func removeMyDriveMarker() {
        if (self.myDrivingDistanceMarker != nil) {
            self.myDrivingDistanceMarker!.map = nil
        }
        self.myDrivingDistanceMarker = nil
        
        //remove any data associated with my drive
        self.currentHole.myLongestDrive = nil
        self.currentHole.longestDrives.removeValue(forKey: AppSingleton.shared.me.id)
    }
    
    internal func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        //Long press interferes with dragging - make new marker if not already dragging it
        if !isDraggingDistanceMarker {
            AudioServicesPlaySystemSound(1519)
            currentDistanceMarker?.map = nil
            currentDistanceMarker = GMSMarker(position: coordinate)
            currentDistanceMarker!.isDraggable = true
            currentDistanceMarker!.map = mapView;
            currentDistanceMarker!.icon = #imageLiteral(resourceName: "golf_ball_blank").toNewSize(CGSize(width: 30, height: 30))
            currentDistanceMarker!.userData = "distance_marker";
            
            mapView.selectedMarker = currentDistanceMarker;
            
            updateDistanceMarker()
        }
    }
    
    internal func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        AudioServicesPlaySystemSound(1519)
        self.isDraggingDistanceMarker = true
        mapView.selectedMarker = currentDistanceMarker;
    }
    internal func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        self.isDraggingDistanceMarker = false
    }
    internal func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        if (marker == currentDistanceMarker) {
            updateDistanceMarker()
        }
    }
    
    internal func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if (marker == myPlayerMarker && currentHole.isLongDrive) {
            addDrivePrompt();
        } else {
            mapView.selectedMarker = marker;
        }
        return true;
    }
    
    internal func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        currentDistanceMarker?.map = nil
        mapView.selectedMarker = nil
        
        lineToPin?.map = nil;
        lineToMyLocation?.map = nil;
        currentDistanceMarker = nil
    }
    
    internal func mapView(_ mapView: GMSMapView, didTapMyLocation location: CLLocationCoordinate2D) {
        if currentHole.isLongDrive {
            addDrivePrompt();
        }
    }
    
    private func updateSuggestionLines(with club:Club) {
        //if recommending club that is not driver - show recommended club lines
        if let ydsPinTee = yardsToPinFromTee, let ydsPinMe = yardsToPinFromMyLocation, let ydsTeeMe = yardsToTeeFromMyLocation {
            let meIsCloseToPin:Bool = ydsPinMe < ydsPinTee - 30
            let meIsCloseToSelectedHole:Bool = ydsTeeMe + ydsPinMe < ydsPinTee + 75
            
            //if we are not being suggested the driver -> show the resulting suggested club arcs
            if meIsCloseToPin && meIsCloseToSelectedHole {
                updateRecommendedClubLines()
            } else {
                //not close to the pin OR not close to the selected hole
                updateDrivingDistanceLines()
            }
        } else {
            updateDrivingDistanceLines()
        }
    }
    
    private func updateDistanceMarker() {
        guard let cDistanceMarker = currentDistanceMarker else {
            return
        }
            
        var usingMyLocation:Bool = false;
        if let ydsPressTee = yardsToPressFromTee {
            if let ydsPressMe = yardsToPressFromLocation {
                usingMyLocation = ydsPressMe < ydsPressTee + 25
            }
        } else {
            usingMyLocation = true
        }
        
        let playerPath = GMSMutablePath()
        var suggestedClub:Club!
        if usingMyLocation {
            suggestedClub = clubTools.getClubSuggestion(ydsTo: yardsToPressFromLocation!);
            cDistanceMarker.title = "\(yardsToPressFromLocation!) yds"
            
            playerPath.add(currentPlayerLocation!.coordinate)
            playerPath.add(currentDistanceMarker!.position)
        } else {
            suggestedClub = clubTools.getClubSuggestion(ydsTo: yardsToPressFromTee!);
            cDistanceMarker.title = "\(yardsToPressFromTee!) yds"
            
            playerPath.add(currentTeeMarker.position)
            playerPath.add(currentDistanceMarker!.position)
        }
        cDistanceMarker.snippet = suggestedClub.name
        
        if let pm = currentPinMarker {
            let pinPath = GMSMutablePath()
            pinPath.add(cDistanceMarker.position)
            pinPath.add(pm.position)
            
            if (lineToPin == nil) {
                lineToPin = GMSPolyline(path: pinPath)
                lineToPin!.strokeWidth = 2
                lineToPin!.strokeColor = UIColor.white
                lineToPin!.geodesic = true
                lineToPin!.map = mapView
            } else {
                lineToPin!.map = mapView
                lineToPin!.path = pinPath
            }
        }
        
        if (lineToMyLocation == nil) {
            lineToMyLocation = GMSPolyline(path: playerPath)
            lineToMyLocation!.strokeWidth = 2
            lineToMyLocation!.strokeColor = UIColor.white
            lineToMyLocation!.geodesic = true
            lineToMyLocation!.map = mapView
        } else {
            lineToMyLocation!.map = mapView
            lineToMyLocation!.path = playerPath
        }
    }
    
    private func clearDistanceLines() {
        for line in drivingDistanceLines {
            line.map = nil;
        }
        for line in suggestedDistanceLines {
            line.map = nil;
        }
        drivingDistanceLines.removeAll()
        suggestedDistanceLines.removeAll()
    }
    
    private func updateDrivingDistanceLines() {
        clearDistanceLines()
        
        let teeLocation:GeoPoint = currentHole.teeLocations[0];
        let pinLocation:GeoPoint = currentHole.pinLocation!;
        let bearingToPin:Double = mapTools.calcBearing(start: teeLocation, finish: currentHole.pinLocation!)
        var bearingToDogLeg:Double = bearingToPin
        if let dll = currentHole.dogLegLocation {
            bearingToDogLeg = mapTools.calcBearing(start: teeLocation, finish: dll)
        }
        
        let minBearing:Int = Int(bearingToDogLeg - 12)
        let maxBearing:Int = Int(bearingToDogLeg + 12)
        
        let teeLoc:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: teeLocation.latitude, longitude: teeLocation.longitude)
        let pinLoc:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: pinLocation.latitude, longitude: pinLocation.longitude)
        let teeYardsToPin:Int = mapTools.distanceFrom(first: teeLoc, second: pinLoc)
        
        let driver:Club = Club(number: 1)
        if (driver.distance < teeYardsToPin) {
            for i in 0..<3 {
                let drivingClub:Club = Club(number: i + 1)
                let lineColor:UIColor = drivingDistanceLineColors[i]
                
                let distancePath = GMSMutablePath()
                for angle in minBearing..<maxBearing {
                    let distanceCoords = mapTools.coordinates(startingCoordinates: teeLoc, atDistance: Double(drivingClub.distance), atAngle: Double(angle))
                    distancePath.add(distanceCoords)
                }
                let distanceLine = GMSPolyline(path: distancePath)
                distanceLine.strokeColor = lineColor;
                distanceLine.strokeWidth = 2
                distanceLine.map = mapView
                
                drivingDistanceLines.append(distanceLine)
            }
        }
    }
    private func updateRecommendedClubLines() {
        clearDistanceLines()
        
        guard let myLocation = currentPlayerLocation, let ydsPinMe = yardsToPinFromMyLocation else {
            return
        }
        
        let myGeopoint:GeoPoint = GeoPoint(latitude: myLocation.coordinate.latitude, longitude: myLocation.coordinate.longitude)
        let pinGeopoint:GeoPoint = currentHole.pinLocation!;
        let bearingToPin:Double = mapTools.calcBearing(start: myGeopoint, finish: pinGeopoint)
        
        let minBearing:Int = Int(bearingToPin - 12)
        let maxBearing:Int = Int(bearingToPin + 12)
        
        let shortestWedge:Club = Club(number: 13)
        //only show suggestion line if the min distance is less than current distance
        if (shortestWedge.distance < ydsPinMe) {
            let suggestedClub:Club = clubTools.getClubSuggestion(ydsTo: ydsPinMe)
            
            //show up to 2 club ups - if suggesting driver then 0 change allowed
            let clubUps:Int = -min(suggestedClub.number - 1, 2)
            
            //show up to 2 club downs but not past smallest club
            let clubDowns:Int = min(13 - suggestedClub.number, 2) + 1
            
            for i in clubUps..<clubDowns {
                let clubSelectionToShow:Club = Club(number: suggestedClub.number + i)
                
                var lineColor:UIColor = UIColor.white
                switch i {
                case -1: lineColor = UIColor.red;
                case 0: lineColor = UIColor.green;
                case 1: lineColor = UIColor.yellow;
                default: lineColor = UIColor(white: 1, alpha: 0.25)
                }
                
                let distancePath = GMSMutablePath()
                for angle in minBearing..<maxBearing {
                    let distanceCoords = mapTools.coordinates(startingCoordinates: myLocation.coordinate,
                                                              atDistance: Double(clubSelectionToShow.distance),
                                                              atAngle: Double(angle))
                    distancePath.add(distanceCoords)
                }
                let distanceLine = GMSPolyline(path: distancePath)
                distanceLine.strokeColor = lineColor;
                distanceLine.strokeWidth = 2
                distanceLine.map = mapView
                
                suggestedDistanceLines.append(distanceLine)
            }
        }
    }
}
