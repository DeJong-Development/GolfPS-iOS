//
//  GoogleMapViewController.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/19/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import GoogleMaps
import FirebaseFirestore
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
        updateOtherPlayerMarkers()
    }
    
    //update our location on server every 30 seconds
    func updateLocationsNow() {
        guard let cpgp = self.me.geoPoint else {
            return
        }
            
        //get difference between old and new locations
        var distanceBetweenLocations:Int = 0
        if let ppgp = previousPlayerGeoPoint {
            distanceBetweenLocations = mapTools.distanceFrom(first: cpgp, second: ppgp)
        }
        
        //if we are in different location then update the position of the player
        if (cpgp != previousPlayerGeoPoint && distanceBetweenLocations >= 25) {
            
            if let hole = currentHole {
                //update elevation numbers since we changed places!
                if let pinElevation = hole.pinElevation {
                    ShotTools.getElevationChange(start: cpgp, finishElevation: pinElevation) { (start, finish, distanceEffect, elevation, error) in
                        self.delegate?.updateElevationEffect(height: elevation, distance: distanceEffect)
                    }
                } else if let pinPosition = hole.pinLocation {
                    ShotTools.getElevationChange(start: cpgp, finish: pinPosition) { (start, finish, distanceEffect, elevation, error) in
                        self.delegate?.updateElevationEffect(height: elevation, distance: distanceEffect)
                    }
                }
            }
            
            updateFirestorePlayerPosition(with: cpgp)
        }
        
        //update previous location on device regardless of distance
        self.me.geoPoint = cpgp
    }
}

extension GoogleMapViewController: CLLocationManagerDelegate {
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let isAuthorized:Bool = (status == .authorizedWhenInUse || status == .authorizedAlways)
        self.mapView.isMyLocationEnabled = isAuthorized
        mapView.settings.myLocationButton = isAuthorized
        
        //remove information associated with current locatino if we become unauthorized
        if !isAuthorized {
            self.me.geoPoint = nil
        }
    }
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let cpl = locations.last else {
            return
        }
        
        self.me.geoPoint = cpl.geopoint
        
        if let myMarker = myPlayerMarker {
            myMarker.position = cpl.coordinate
        } else {
            createPlayerMarker()
        }
        
        if let pm = currentPinMarker {
            let distanceToPin:Int = mapTools.distanceFrom(first: cpl.coordinate, second: pm.position)
            delegate?.updateDistanceToPin(distance: distanceToPin)
            
            if let suggestedClub:Club = me.bag.getClubSuggestion(distanceTo: distanceToPin) {
                delegate?.updateSelectedClub(club: suggestedClub)
                
                //update any suggestion lines
                updateSuggestionLines(with: suggestedClub)
            }
        }
        
        //add course visitation
        if let course = AppSingleton.shared.course,
            !(self.me.coursesVisited?.contains(course.id) ?? false),
            course.bounds.contains(cpl.coordinate) {
            self.me.addCourseVisitation(courseId: course.id)
        }
        
        //update any distance markers we already have displayed when we update our location
        updateDistanceMarker()
    }
}

class GoogleMapViewController: UIViewController, GMSMapViewDelegate {
    
    private let me:MePlayer = AppSingleton.shared.me
    
    private let mapTools:MapTools = MapTools()
    private let clubTools:ClubTools = ClubTools()
    
    private var db:Firestore { return AppSingleton.shared.db }
    private var mapView:GMSMapView!
    weak var delegate:ViewUpdateDelegate?
    
    private var locationTimer:LocationUpdateTimer!
    private var otherPlayerTimer:PlayerUpdateTimer!
    
    private let locationManager = CLLocationManager()
    private var previousPlayerGeoPoint:GeoPoint?
    
    internal var currentHole:Hole!
    
    private var playerListener:ListenerRegistration? = nil
    
    private var otherPlayers:[Player] = [Player]()
    private var otherPlayerMarkers:[GMSMarker] = [GMSMarker]()
    private var myPlayerMarker:GMSMarker?
    private var myPlayerImage:UIImage? {
        didSet {
            self.createPlayerMarker()
        }
    }
    
    private var myDrivingDistanceMarker:GMSMarker?
    private var currentPinMarker:GMSMarker!
    private var currentTeeMarker:GMSMarker!
    private var currentBunkerMarkers:[GMSMarker] = [GMSMarker]()
    private var currentLongDriveMarkers:[GMSMarker] = [GMSMarker]()
    private var currentDistanceMarker:GMSMarker?
    
    private var isDraggingDistanceMarker:Bool = false
    
    private var drivingDistanceLines:[GMSPolyline] = [GMSPolyline]()
    private let drivingDistanceLineColors:[UIColor] = [UIColor.green, UIColor.yellow, UIColor.orange]
    
    private var suggestedDistanceLines:[GMSPolyline] = [GMSPolyline]()
    
    private var lineToMyLocation:GMSPolyline?
    private var lineToPin:GMSPolyline?
    
    private var distanceToPressFromLocation:Int? {
        guard let playerLocation = self.me.geoPoint,
            let pressLocation = currentDistanceMarker?.position else {
            return nil
        }
        return mapTools.distanceFrom(first: playerLocation.location, second: pressLocation)
    }
    private var distanceToPressFromTee:Int? {
        guard let pressLocation = currentDistanceMarker?.position,
              let teeLocation = currentTeeMarker?.position else {
            return nil
        }
        return mapTools.distanceFrom(first: teeLocation, second: pressLocation)
    }
    private var distanceToPinFromMyLocation:Int? {
        guard let playerLocation = self.me.geoPoint,
            let pinLocation = currentPinMarker?.position else {
            return nil
        }
        return mapTools.distanceFrom(first: playerLocation.location, second: pinLocation)
    }
    private var distanceToTeeFromMyLocation:Int? {
        guard let playerCoord = self.me.geoPoint,
            let teeCoord = currentTeeMarker?.position else {
            return nil
        }
        return mapTools.distanceFrom(first: playerCoord.location, second: teeCoord)
    }
    private var distanceToPinFromTee:Int? {
        guard let tp = currentTeeMarker?.position,
            let pp = currentPinMarker?.position else {
            return nil
        }
        return mapTools.distanceFrom(first: tp, second: pp)
    }
    
    private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !SCSDKLoginClient.isUserLoggedIn {
            myPlayerImage = nil
        } else if myPlayerImage == nil {
            downloadBitmojiImage()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let course = AppSingleton.shared.course {
            locationTimer.invalidate()
            locationTimer.delegate = self
            locationTimer.startNewTimer(interval: 5)
            
            listenToPlayerLocationsOnCourse(with: course.id)
            
            self.goToHole()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerListener?.remove()
    }
    
    override func loadView() {
        super.loadView()
        
        let camera = GMSCameraPosition.camera(withLatitude: 40, longitude: -75, zoom: 3.5)
        self.mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        self.mapView.mapType = GMSMapViewType.satellite
        view = mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.delegate = self
        
        //need to set up the camera; there is a bug that exists if we don't do this
        if let course = AppSingleton.shared.course, let firstHole = course.holeInfo.first(where: {$0.number == 1}) {
            self.mapView.moveCamera(GMSCameraUpdate.setTarget(firstHole.pinLocation.location))
        }
        
        locationManager.delegate = self;
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        
        locationTimer = LocationUpdateTimer()
        locationTimer.delegate = self
        
        otherPlayerTimer = PlayerUpdateTimer()
        otherPlayerTimer.delegate = self
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
        let userId = self.me.id
        
        guard self.me.shareLocation else {
            locationTimer.invalidate()
            return
        }
        
        if let id = AppSingleton.shared.course?.id {
            db.collection("players")
                .document(userId)
                .setData([
                    "course": id,
                    "location": location,
                    "updateTime": Date().iso8601
                    ], merge: true)
        } else {
            //no course so delete
            db.collection("players").document(userId).delete()
            locationTimer.invalidate()
        }
    }
    
    private func listenToPlayerLocationsOnCourse(with id: String) {
        otherPlayerTimer.invalidate()
        otherPlayerTimer.delegate = self
        otherPlayerTimer.startNewTimer(interval: 30)
        
        playerListener?.remove()
        
        var playersOnCourse:[Player] = [Player]()
        
        //grab course hole information
        playerListener = db.collection("players")
            .whereField("course", isEqualTo: id)
            .addSnapshotListener { querySnapshot, error in
                
                if let documents = querySnapshot?.documents {
                    for document in documents {
                        let otherPlayer = Player(id: document.documentID, data: document.data())
                        
                        if let timeSinceLastLocationUpdate = otherPlayer.lastLocationUpdate?.timeIntervalSinceNow,
                            timeSinceLastLocationUpdate > -14400 {
                            //only add player to array if they are within the correct time period
                            playersOnCourse.append(otherPlayer)
                        }
                    }
                } else {
                    DebugLogger.report(error: error, message: "Error fetching other player location information")
                }
                
                self.otherPlayers = playersOnCourse
                
                self.updateOtherPlayerMarkers()
        }
    }
    
    public func goToHole(increment: Int = 0) {
        guard let course = AppSingleton.shared.course else {
            return
        }
        
        currentDistanceMarker?.map = nil
        currentDistanceMarker = nil
        lineToPin?.map = nil
        lineToMyLocation?.map = nil
        
        //remove old listener just in case we are still loading the driving distance markers
        //could result in a race condition while we are searching for the new current hole?
        currentHole?.updateDelegate = nil
        
        var holeNum = currentHole?.number ?? 1 //default to hole number 1
        holeNum += increment
        if (holeNum > course.holeInfo.count) {
            holeNum = 1
        } else if holeNum <= 0 {
            holeNum = course.holeInfo.count
        }
        
        guard let nextHole = course.holeInfo.first(where: {$0.number == holeNum}) else {
            return
        }
        
        currentHole = nextHole
        currentHole.updateDelegate = self
        delegate?.updateCurrentHole(hole: currentHole)
        
        updatePinMarker()
        updateTeeMarker()
        updateBunkerMarkers()
        updateLongDriveMarkers()
        
        //check if we have played at this course before
        updateDidPlayHere()
        
        moveCamera(to: currentHole, orientToHole: true)
        
        mapView.selectedMarker = currentPinMarker
        
        //location manager will update elevation effect
        //trigger once in case we haven't moved yet
        guard let hole = currentHole else {
            return
        }
        if let myGeoPoint = self.me.geoPoint {
            //update elevation numbers since we changed places!
            if let pinElevation = hole.pinElevation {
                ShotTools.getElevationChange(start: myGeoPoint, finishElevation: pinElevation, completion: calculateElevation)
            } else if let pinPosition = hole.pinLocation {
                ShotTools.getElevationChange(start: myGeoPoint, finish: pinPosition, completion: calculateElevation)
            }
        } else if let pinElevation = currentHole.pinElevation {
            ShotTools.getElevationChange(start: hole.teeLocations.first!, finishElevation: pinElevation, completion: calculateElevation)
        } else {
            ShotTools.getElevationChange(start: hole.teeLocations.first!, finish: hole.pinLocation!, completion: calculateElevation)
        }
    }
    
    private func calculateElevation(_ start:Double, _ finish: Double, _ distance:Double, _ elevation:Double, _ error:String?) {
        DispatchQueue.main.async {
            self.delegate?.updateElevationEffect(height: elevation, distance: distance)
            
            var distanceToUseInSuggestion:Int = 300
            if let distancePinMe = self.distanceToPinFromMyLocation {
                distanceToUseInSuggestion = distancePinMe
            } else if let distancePinTee = self.distanceToPinFromTee {
                distanceToUseInSuggestion = distancePinTee
            }
            self.delegate?.updateDistanceToPin(distance: distanceToUseInSuggestion)
            
            if let suggestedClub:Club = self.me.bag.getClubSuggestion(distanceTo: distanceToUseInSuggestion + Int(distance)) {
                self.delegate?.updateSelectedClub(club: suggestedClub)
                self.updateSuggestionLines(with: suggestedClub)
            }
        }
    }
    
    private func moveCamera(to hole:Hole, orientToHole:Bool) {
        let center:CLLocationCoordinate2D = mapTools.getBoundsCenter(hole.bounds)
        
        var bearing:Double = 0
        var viewingAngle:Double = 0
        if (orientToHole) {
            let teeLocation:GeoPoint = hole.teeLocations[0]
            let pinLocation:GeoPoint = hole.pinLocation
            bearing = mapTools.calcBearing(start: teeLocation, finish: pinLocation) - 20
            viewingAngle = 45
        }
        
        let boxFitZoom:Float = mapTools.getBoundsZoomLevel(bounds: hole.bounds, screenSize: view.bounds)
        
        let newZoom:Float = mapTools.getCircularFitZoomLevel(holeLength: Double(hole.distance), holeWidth: 100, screenSize: view.bounds)
        
        let cameraView:GMSCameraPosition = GMSCameraPosition(target: center,
                                                             zoom: newZoom,
                                                             bearing: bearing,
                                                             viewingAngle: viewingAngle)
        mapView.animate(to: cameraView)
    }
    
    private func removeOldPlayerMarkers() {
        for marker in otherPlayerMarkers {
            guard let markerUserData = marker.userData as? [String:Any],
                let markerPlayerId = markerUserData["userId"] as? String else {
                marker.map = nil
                continue
            }
                
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
            guard let playerGeoPoint:GeoPoint = player.geoPoint,
                player.id != self.me.id else {
                //no location data available for user or myself
                continue
            }
                
            var markerTitle:String = "Golfer"
            
            var playerLocation = CLLocationCoordinate2D(latitude: playerGeoPoint.latitude, longitude: playerGeoPoint.longitude)
            if let courseSpec = course.spectation, !course.bounds.contains(playerLocation) {
                //not within course bounds - lets put them as spectator
                let randomDoubleLat = Double.random(in: -0.00001...0.00001)
                let randomDoubleLng = Double.random(in: -0.00001...0.00001)
                playerLocation = CLLocationCoordinate2D(latitude: courseSpec.latitude + randomDoubleLat, longitude: courseSpec.longitude + randomDoubleLng)
                markerTitle = "Spectator"
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
        }
        
        //update the array
        otherPlayerMarkers = newPlayerMarkers.filter { $0.map != nil }
    }
    
    ///assign the fact that we played at this course, push to server
    private func updateDidPlayHere() {
        guard let course = AppSingleton.shared.course,
            let myGeoPoint = self.me.geoPoint,
            course.bounds.contains(myGeoPoint.location) && !course.didPlayHere else {
            return
        }
        course.didPlayHere = true
    }
    
    internal func addDrivePrompt() {
        let ac = UIAlertController(title: "Add Long Drive Here?", message: "Your drive will be added to this hole and potentially be used in future long drive competitions (testing this feature).", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Yes", style: .default) { action in
            //add a driving distance marker and select it
            self.myDrivingDistanceMarker?.map = nil
            
            guard let loc:CLLocationCoordinate2D = self.me.geoPoint?.location else {
                //do not have current location for player
                return
            }
            
            let distanceToTee:Int = self.mapTools.distanceFrom(first: self.currentHole.teeLocations[0], second: loc.geopoint)
            
            if (distanceToTee > 500) {
                //prompt some sort of alert saying this is just ridiculous
            } else {
                self.myDrivingDistanceMarker = GMSMarker(position: loc)
                self.myDrivingDistanceMarker!.title = "My Drive"
                self.myDrivingDistanceMarker!.snippet = distanceToTee.distance
                self.myDrivingDistanceMarker!.icon = #imageLiteral(resourceName: "marker-distance-longdrive").toNewSize(CGSize(width: 30, height: 30))
                self.myDrivingDistanceMarker!.userData = "Drive";
                self.myDrivingDistanceMarker!.map = self.mapView;
                self.mapView.selectedMarker = self.myDrivingDistanceMarker!;
                
                //update my drive data on hole object
                self.currentHole.setLongestDrive(distance: distanceToTee)
                self.currentHole.longestDrives[self.me.id] = loc.geopoint
                
                self.me.didLogLongDrive = true
                
                //send drive data to the firestore
                self.updateFirestoreLongDrive(distance: distanceToTee, location: loc.geopoint)
                
                //inform delegate of new hole characteristics
                self.delegate?.updateCurrentHole(hole: self.currentHole)
            }
        })
        ac.addAction(UIAlertAction(title: "No", style: .default))
        self.present(ac, animated: true)
    }
    
    ///Always store distance in same units so we can be consistent
    private func updateFirestoreLongDrive(distance:Int, location: GeoPoint) {
        let userId = self.me.id
        
        var yards:Double = Double(distance)
        if AppSingleton.shared.metric {
            //convert distance to meters
            yards = Double(distance).toMeters()
        }
        
        if let holeDocRef = currentHole.docReference {
            let myLongDriveDoc = holeDocRef.collection("drives").document(userId)
            myLongDriveDoc.setData([
                "location": location,
                "distance": yards.rounded(),
                "date": Date().iso8601
            ])
        }
    }
    
    private func createPlayerMarker() {
        myPlayerMarker?.map = nil
        if let loc:CLLocationCoordinate2D = self.me.geoPoint?.location,
            let bitmojiImage = self.myPlayerImage {
            myPlayerMarker = GMSMarker(position: loc)
            myPlayerMarker!.title = "Me"
            myPlayerMarker!.icon = bitmojiImage.toNewSize(CGSize(width: 55, height: 55))
            myPlayerMarker!.userData = "ME";
            myPlayerMarker!.map = mapView;
        }
    }
    
    private func updateTeeMarker() {
        let teePoint:GeoPoint = currentHole.teeLocations[0];
        let loc:CLLocationCoordinate2D = teePoint.location
        
        currentTeeMarker?.map = nil
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
        let distanceToPin:Int = mapTools.distanceFrom(first: pinLoc, second: teeLoc)
        
        if let pinMarker = currentPinMarker {
            pinMarker.map = nil
        }
        currentPinMarker = GMSMarker(position: pinLoc)
        currentPinMarker.title = "Pin #\(currentHole.number)"
        currentPinMarker.snippet = distanceToPin.distance
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
            let distanceToBunker:Int = mapTools.distanceFrom(first: bunkerLoc, second: teeLoc)
            
            let bunkerMarker = GMSMarker(position: bunkerLoc)
            bunkerMarker.title = "Hazard"
            bunkerMarker.snippet = distanceToBunker.distance
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
        self.myDrivingDistanceMarker?.map = nil
        self.myDrivingDistanceMarker = nil
        
        for longDrive in currentHole.longestDrives {
            let longDriveUser = longDrive.key
            let longDriveLocation = longDrive.value
            
            let ldLoc = longDriveLocation.location
            let teeLoc = currentTeeMarker.position
            
            let distanceToTee:Int = mapTools.distanceFrom(first: ldLoc, second: teeLoc)
            
            if (longDriveUser == self.me.id) {
                self.myDrivingDistanceMarker = GMSMarker(position: ldLoc)
                self.myDrivingDistanceMarker!.title = "My Drive"
                if (AppSingleton.shared.metric) {
                    self.myDrivingDistanceMarker!.snippet = "\(distanceToTee) m"
                } else {
                    self.myDrivingDistanceMarker!.snippet = "\(distanceToTee) yds"
                }
                self.myDrivingDistanceMarker!.icon = #imageLiteral(resourceName: "marker-distance-longdrive").toNewSize(CGSize(width: 30, height: 30))
                self.myDrivingDistanceMarker!.userData = "Drive";
                self.myDrivingDistanceMarker!.map = self.mapView;
                currentLongDriveMarkers.append(myDrivingDistanceMarker!);
            } else {
                let driveMarker = GMSMarker(position: ldLoc)
                driveMarker.title = "Long Drive"
                driveMarker.snippet = distanceToTee.distance
                driveMarker.icon = #imageLiteral(resourceName: "marker-distance").toNewSize(CGSize(width: 25, height: 25))
                driveMarker.userData = "Drive";
                driveMarker.map = self.mapView;
                currentLongDriveMarkers.append(driveMarker);
            }
        }
    }
    
    internal func removeMyDriveMarker() {
        self.myDrivingDistanceMarker?.map = nil
        self.myDrivingDistanceMarker = nil
        
        //remove any data associated with my drive
        self.currentHole.setLongestDrive(distance: nil)
        self.currentHole.longestDrives.removeValue(forKey: self.me.id)
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
        mapView.selectedMarker = currentDistanceMarker
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
            addDrivePrompt()
        } else {
            mapView.selectedMarker = marker
        }
        return true;
    }
    
    internal func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        currentDistanceMarker?.map = nil
        mapView.selectedMarker = nil
        
        lineToPin?.map = nil
        lineToMyLocation?.map = nil
        currentDistanceMarker = nil
    }
    
    internal func mapView(_ mapView: GMSMapView, didTapMyLocation location: CLLocationCoordinate2D) {
        if currentHole.isLongDrive {
            addDrivePrompt()
        }
    }
    
    private func updateSuggestionLines(with club:Club) {
        //if recommending club that is not driver - show recommended club lines
        if let distancePinTee = distanceToPinFromTee,
            let distancePinMe = distanceToPinFromMyLocation,
            let distanceTeeMe = distanceToTeeFromMyLocation {
            let meIsNearPin = distancePinMe < 300
            let meIsNearTeeBox = distanceTeeMe < 100
            let meIsCloseToSelectedHole = distanceTeeMe + distancePinMe < distancePinTee + 100
            
            if meIsNearTeeBox {
                updateDrivingDistanceLines(useMyLocation: true)
            } else if meIsNearPin || meIsCloseToSelectedHole {
                updateRecommendedClubLines(club)
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
        if let distancePressTee = distanceToPressFromTee {
            if let distancePressMe = distanceToPressFromLocation {
                usingMyLocation = distancePressMe < distancePressTee + 25
            }
        } else {
            usingMyLocation = true
        }
        
        let playerPath = GMSMutablePath()
        var suggestedClub:Club?
        if usingMyLocation {
            suggestedClub = me.bag.getClubSuggestion(distanceTo: distanceToPressFromLocation!)
            cDistanceMarker.title = distanceToPressFromLocation!.distance
            
            playerPath.add(self.me.geoPoint!.location)
            playerPath.add(currentDistanceMarker!.position)
        } else {
            suggestedClub = me.bag.getClubSuggestion(distanceTo: distanceToPressFromTee!)
            cDistanceMarker.title = distanceToPressFromTee!.distance
            
            playerPath.add(currentTeeMarker.position)
            playerPath.add(currentDistanceMarker!.position)
        }
        cDistanceMarker.snippet = suggestedClub?.name
        
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
    
    private func updateDrivingDistanceLines(useMyLocation: Bool = false) {
        clearDistanceLines()
        
        guard let pinGP:GeoPoint = currentHole.pinLocation else {
            DebugLogger.report(error: nil, message: "Hole does not have a pin!")
            return
        }
        
        let startGP:GeoPoint
        if useMyLocation {
            startGP = self.me.geoPoint ?? currentHole.teeLocations[0]
        } else {
            startGP = currentHole.teeLocations[0]
        }
        
        let bearingToPin:Double = mapTools.calcBearing(start: startGP, finish: pinGP)
        
        var bearingToDogLeg:Double = bearingToPin
        if let dll = currentHole.dogLegLocation {
            bearingToDogLeg = mapTools.calcBearing(start: startGP, finish: dll)
        }
        
        let minBearing:Int = Int(bearingToDogLeg - 12)
        let maxBearing:Int = Int(bearingToDogLeg + 12)
        
        let teeYardsToPin:Int = mapTools.distanceFrom(first: startGP.location, second: pinGP.location)
        
        let myClubs = self.me.bag.myClubs
        guard let driver:Club = myClubs.first else {
            return
        }
        
        if (driver.distance < teeYardsToPin) {
            for i in 0..<3 {
                guard (myClubs.count > i) else { break }
                let drivingClub:Club = myClubs[i]
                let lineColor:UIColor = drivingDistanceLineColors[i]
                
                let distancePath = GMSMutablePath()
                for angle in minBearing..<maxBearing {
                    let distanceCoords = mapTools.coordinates(startingCoordinates: startGP.location, atDistance: Double(drivingClub.distance), atAngle: Double(angle))
                    distancePath.add(distanceCoords)
                }
                let distanceLine = GMSPolyline(path: distancePath)
                distanceLine.strokeColor = lineColor
                distanceLine.strokeWidth = 2
                distanceLine.map = mapView
                
                drivingDistanceLines.append(distanceLine)
            }
        }
    }
    private func updateRecommendedClubLines(_ suggestedClub:Club) {
        clearDistanceLines()
        
        guard let myGeopoint = self.me.geoPoint,
            let distancePinMe = distanceToPinFromMyLocation else {
            return
        }
        
        let pinGeopoint:GeoPoint = currentHole.pinLocation!;
        let bearingToPin:Double = mapTools.calcBearing(start: myGeopoint, finish: pinGeopoint)
        
        let minBearing:Int = Int(bearingToPin - 12)
        let maxBearing:Int = Int(bearingToPin + 12)
        
        //only show suggestion line if the min distance is less than current distance
        guard let shortestWedge:Club = self.me.bag.myClubs.last, shortestWedge.distance < distancePinMe else {
            return
        }
        
        //show up to 3 club ups - if suggesting driver then 0 change allowed
        let clubUps:Int = -min(suggestedClub.order, 3)
        
        //show up to 3 club downs but not past smallest club
        let clubDowns:Int = min(self.me.bag.myClubs.count - suggestedClub.order, 3) + 1
        
        for i in clubUps..<clubDowns {
            guard (self.me.bag.myClubs.count > suggestedClub.order + i) else { break }
            
            let clubSelectionToShow:Club = self.me.bag.myClubs[suggestedClub.order + i]
            
            print("Club \(clubSelectionToShow.name) @ distance \(clubSelectionToShow.distance)")
            
            var lineColor:UIColor = UIColor.white
            switch i {
                case -1: lineColor = UIColor.red
                case 0: lineColor = UIColor.green
                case 1: lineColor = UIColor.yellow
                default: lineColor = UIColor(white: 1, alpha: 0.25)
            }
            
            let distancePath = GMSMutablePath()
            for angle in minBearing..<maxBearing {
                let distanceCoords = mapTools.coordinates(startingCoordinates: myGeopoint.location, atDistance: Double(clubSelectionToShow.distance), atAngle: Double(angle))
                distancePath.add(distanceCoords)
            }
            let distanceLine = GMSPolyline(path: distancePath)
            distanceLine.strokeColor = lineColor
            distanceLine.strokeWidth = 2
            distanceLine.map = mapView
            
            suggestedDistanceLines.append(distanceLine)
        }
    }
}
