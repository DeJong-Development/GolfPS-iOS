//
//  GoogleMapViewController.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/19/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import FirebaseFirestore
import AudioToolbox
import SCSDKLoginKit

extension GoogleMapViewController: MarkerToolsDelegate {
    func replaceMyPlayerMarker(_ marker: GMSMarker?) {
        self.myPlayerMarker = marker
    }
    
    func replaceOtherPlayerMarkers(_ markers: [GMSMarker]) {
        self.otherPlayerMarkers = markers
    }
    
    func replacePinMarker(_ marker: GMSMarker?) {
        self.currentPinMarker = marker
    }
    
    func replaceTeeMarker(_ marker: GMSMarker?) {
        self.currentTeeMarker = marker
    }
    
    func replaceBunkerMarkers(_ markers: [GMSMarker]) {
        self.currentBunkerMarkers = markers
    }
    
    func replaceLongDriveMarkers(_ markers: [GMSMarker]) {
        self.currentLongDriveMarkers = markers
    }
    
    func replaceMyDriveMarker(_ marker: GMSMarker?) {
        self.myDrivingDistanceMarker = marker
    }
    
}

extension GoogleMapViewController: HoleUpdateDelegate {
    func didUpdateLongDrive() {
        self.markerTools.updateLongDriveMarkers(self.currentLongDriveMarkers, myDriveMarker: self.myDrivingDistanceMarker, hole: self.currentHole, mapView: self.mapView)
    }
}

extension GoogleMapViewController: LocationUpdateTimerDelegate, PlayerUpdateTimerDelegate {
    func updatePlayersNow() {
        self.markerTools.updateOtherPlayerMarkers(self.otherPlayerMarkers, otherPlayers: self.otherPlayers, mapView: self.mapView)
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
        if (previousPlayerGeoPoint == nil || distanceBetweenLocations >= 25) {
            
            if let hole = currentHole {
                //update elevation numbers since we changed places!
                if let pinElevation = hole.pinElevation {
                    ShotTools.getElevationChange(start: cpgp, finishElevation: pinElevation) { (start, finish, distanceEffect, elevation, error) in
                        self.delegate?.updateElevationEffect(height: elevation, distance: distanceEffect)
                    }
                } else if let pinPosition = hole.pinGeoPoint {
                    ShotTools.getElevationChange(start: cpgp, finish: pinPosition) { (start, finish, distanceEffect, elevation, error) in
                        self.delegate?.updateElevationEffect(height: elevation, distance: distanceEffect)
                    }
                }
            }
            
            previousPlayerGeoPoint = cpgp
            
            updateFirestorePlayerPosition(with: cpgp)
        }
        
        //update previous location on device regardless of distance
        self.me.geoPoint = cpgp
    }
}

extension GoogleMapViewController: CLLocationManagerDelegate {
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let isAuthorized:Bool = (status == .authorizedWhenInUse || status == .authorizedAlways)
        self.mapView?.isMyLocationEnabled = isAuthorized
        self.mapView?.settings.myLocationButton = isAuthorized
        
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
        
        self.markerTools.updatePlayerMarker(self.myPlayerMarker, playerImage: self.myPlayerImage, mapView: self.mapView)
        
        
        //add course visitation
        if let course = AppSingleton.shared.course,
            !(self.me.coursesVisited?.contains(course.id) ?? false),
            course.bounds.contains(cpl.coordinate) {
            self.me.addCourseVisitation(courseId: course.id)
        }
        
        if currentHole != nil {
            self.delegate?.updateDistanceToPin(distance: self.distanceToPinFromMyLocation ?? self.distanceToPinFromTee)
            
            self.updateSuggestionLines()
            
            //update any distance markers we already have displayed when we update our location
            self.updateDistanceMarker()
        }
        
    }
}

class GoogleMapViewController: UIViewController, GMSMapViewDelegate {
    
    fileprivate var me:MePlayer { return AppSingleton.shared.me }
    private var db:Firestore { return AppSingleton.shared.db }
    
    private let mapTools:MapTools = MapTools()
    private let clubTools:ClubTools = ClubTools()
    private let markerTools:MarkerTools = MarkerTools()
    
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
            self.markerTools.updatePlayerMarker(self.myPlayerMarker, playerImage: self.myPlayerImage, mapView: self.mapView)
        }
    }
    
    private var myDrivingDistanceMarker:GMSMarker?
    private var currentPinMarker:GMSMarker!
    private var currentTeeMarker:GMSMarker!
    private var currentBunkerMarkers:[GMSMarker] = [GMSMarker]()
    private var currentLongDriveMarkers:[GMSMarker] = [GMSMarker]()
    private var currentDistanceMarker:GMSMarker?
    
    private var isDraggingDistanceMarker:Bool = false
    private var isDraggingMarker:Bool = false
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !SCSDKLoginClient.isUserLoggedIn {
            myPlayerImage = nil
        } else if myPlayerImage == nil {
            BitmojiUtility.downloadBitmojiImage { _, bitmojiImage  in
                DispatchQueue.main.async {
                    self.myPlayerImage = bitmojiImage
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let course = AppSingleton.shared.course else {
            return
        }
        
        locationTimer.invalidate()
        locationTimer.delegate = self
        locationTimer.startNewTimer(interval: 5)
        
        listenToPlayerLocationsOnCourse(with: course.id)
        
        self.goToHole(animate: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerListener?.remove()
    }
    
    /// https://developer.apple.com/documentation/uikit/uiviewcontroller/1621454-loadview
    override func loadView() {
        let mapOptions = GMSMapViewOptions()
        mapOptions.frame = .zero
        mapOptions.camera = GMSCameraPosition.camera(withLatitude: 40, longitude: -85, zoom: 3.5)
        mapOptions.backgroundColor = .systemBackground
        
        self.mapView = GMSMapView.init(options: mapOptions)
        self.mapView.mapType = GMSMapViewType.satellite
        self.view = self.mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mv = self.mapView else {
            fatalError("No map after view loaded.")
        }
        mv.delegate = self
        
        markerTools.delegate = self
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        
        locationTimer = LocationUpdateTimer()
        locationTimer.delegate = self
        
        otherPlayerTimer = PlayerUpdateTimer()
        otherPlayerTimer.delegate = self
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
                    "updateTime": Timestamp()
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
                
                guard let documents = querySnapshot?.documents else {
                    DebugLogger.report(error: error, message: "Error fetching other player location information")
                    return
                }
                
                // Wipe all players and replace with snapshot
                playersOnCourse.removeAll()
                
                for document in documents {
                    let otherPlayer = Player(id: document.documentID, data: document.data())
                    
                    if otherPlayer.id == self.me.id {
                        print("We found our own position")
                        continue
                    }
                    
                    if let timeSinceLastLocationUpdate = otherPlayer.lastLocationUpdate?.dateValue().timeIntervalSinceNow,
                        timeSinceLastLocationUpdate > -14400 {
                        //only add player to array if they are within the correct time period
                        
                        if otherPlayer.geoPoint != nil {
                            print("We found a player with a location on course!")
                        } else {
                            print("Player with no location found... Stick at clubhouse...")
                        }
                        
                        playersOnCourse.append(otherPlayer)
                    }
                }
                
                self.otherPlayers = playersOnCourse
                
                self.markerTools.updateOtherPlayerMarkers(self.otherPlayerMarkers, otherPlayers: self.otherPlayers, mapView: self.mapView)
        }
    }
    
    public func goToHole(increment: Int = 0, animate: Bool = true) {
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
        
        markerTools.updateMarkers(pinMarker: self.currentPinMarker, teeMarker: self.currentTeeMarker, bunkerMarkers: self.currentBunkerMarkers, longDriveMarkers: self.currentLongDriveMarkers, myDriveMarker: self.myDrivingDistanceMarker, hole: self.currentHole, mapView: self.mapView)
        
        //check if we have played at this course before
        updateDidPlayHere()
        
        moveCamera(to: currentHole, orientToHole: true, animate: animate)
        
        mapView?.selectedMarker = currentPinMarker
        
        //location manager will update elevation effect
        //trigger once in case we haven't moved yet
        guard let hole = currentHole else {
            return
        }
        
        #if DEBUG
        //show fairway polygon
        let fairway = GMSPolyline(path: hole.fairwayPath)
        fairway.map = mapView
        #endif
        
        if let myGeoPoint = self.me.geoPoint {
            //update elevation numbers since we changed places!
            if let pinElevation = hole.pinElevation {
                ShotTools.getElevationChange(start: myGeoPoint, finishElevation: pinElevation, completion: calculateElevation)
            } else if let pinPosition = hole.pinGeoPoint {
                ShotTools.getElevationChange(start: myGeoPoint, finish: pinPosition, completion: calculateElevation)
            }
        } else if let pinElevation = currentHole.pinElevation {
            ShotTools.getElevationChange(start: hole.teeGeoPoints.first!, finishElevation: pinElevation, completion: calculateElevation)
        } else {
            ShotTools.getElevationChange(start: hole.teeGeoPoints.first!, finish: hole.pinGeoPoint!, completion: calculateElevation)
        }
        
        self.updateSuggestionLines()
        
        self.delegate?.updateDistanceToPin(distance: self.distanceToPinFromMyLocation ?? self.distanceToPinFromTee)
    }
    
    private func calculateElevation(_ start:Double, _ finish: Double, _ distance:Double, _ elevation:Double, _ error:String?) {
        DispatchQueue.main.async {
            self.delegate?.updateElevationEffect(height: elevation, distance: distance)
        }
    }
    
    private func moveCamera(to hole:Hole, orientToHole:Bool, animate:Bool = true) {
        let center:CLLocationCoordinate2D = mapTools.getBoundsCenter(hole.bounds)
        
        var bearing:Double = 0
        var viewingAngle:Double = 0
        if (orientToHole) {
            let teeLocation:GeoPoint = hole.teeGeoPoints[0]
            let pinLocation:GeoPoint = hole.pinGeoPoint
            bearing = mapTools.calcBearing(start: teeLocation, finish: pinLocation) - 20
            viewingAngle = 45
        }
        
        let _:Float = mapTools.getBoundsZoomLevel(bounds: hole.bounds, screenSize: view.bounds)
        let newZoom:Float = mapTools.getCircularFitZoomLevel(holeLength: Double(hole.distance), holeWidth: 100, screenSize: view.bounds)
        
        let cameraView:GMSCameraPosition = GMSCameraPosition(target: center,
                                                             zoom: newZoom,
                                                             bearing: bearing,
                                                             viewingAngle: viewingAngle)
        
        if animate {
            mapView?.animate(to: cameraView)
        } else {
            mapView?.moveCamera(GMSCameraUpdate.setCamera(cameraView))
        }
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
            
            guard let loc = self.me.geoPoint?.location else {
                //do not have current location for player
                return
            }
            
            let distanceToTee:Int = self.mapTools.distanceFrom(first: self.currentHole.teeGeoPoints[0], second: loc.geopoint)
            
            if (distanceToTee > 500) {
                //prompt some sort of alert saying this is just ridiculous
            } else {
                let myDistanceMarker = self.myDrivingDistanceMarker ?? GMSMarker(position: loc)
                myDistanceMarker.title = "My Drive"
                myDistanceMarker.snippet = distanceToTee.distance
                myDistanceMarker.icon = #imageLiteral(resourceName: "marker-distance-longdrive").toNewSize(CGSize(width: 30, height: 30))
                myDistanceMarker.userData = "Drive"
                myDistanceMarker.map = self.mapView
                self.myDrivingDistanceMarker = myDistanceMarker
                
                self.mapView.selectedMarker = myDistanceMarker
                
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
        
        let yards = AppSingleton.shared.metric ? Double(distance).toMeters() : Double(distance)
        
        if let holeDocRef = currentHole.docReference {
            let myLongDriveDoc = holeDocRef.collection("drives").document(userId)
            myLongDriveDoc.setData([
                "location": location,
                "distance": yards.rounded(),
                "date": Date().iso8601
            ])
        }
    }
    
    internal func removeMyDriveMarker() {
        self.myDrivingDistanceMarker?.map = nil
        self.myDrivingDistanceMarker = nil
        
        //remove any data associated with my drive
        self.currentHole.setLongestDrive(distance: nil)
        self.currentHole.longestDrives.removeValue(forKey: self.me.id)
    }
    
    internal func calculateOptimalDriveLocation(showTargets:Bool = false) {
        let numClubs = me.bag.myClubs.count
        guard numClubs >= 3 else {
            DebugLogger.report(error: nil, message: "Not enough clubs to perform optimization")
            return
        }
        
        let teeClubs = Array(me.bag.myClubs[0..<3])
        let secondClubs = Array(me.bag.myClubs[1..<me.bag.myClubs.count - 2])
        
        let teeAngles = stride(from: -30, to: 30, by: 3)
        let ssAngles = stride(from: -10, to: 10, by: 3)
        
        DispatchQueue.global(qos: .userInitiated).async {
            for (teeClubIndex, teeClub) in teeClubs.enumerated() {
                print("Checking routes with \(teeClub.name) off the tee...")
                
                var golfRoutes:[GolfShotRoute] = []
                
                for bearing1Adjustment in teeAngles {
                    
                    let firstRoute = GolfShotRoute(club1: teeClub, club2: Club(id: ""), hole: self.currentHole)
                    firstRoute.applyInitialBearingDeviations(teeShotDeviation: Double(bearing1Adjustment), secondShotDeviation: 0)
                    
                    // if first shot is not targetting fairway then skip this route
                    if !firstRoute.isTeeShotTargettingFairway() {
                        continue
                    }
                    
                    for (_, secondClub) in secondClubs.enumerated() {
                        for (_, bearing2Adjustment) in ssAngles.enumerated() {
                            let golfRoute = GolfShotRoute(club1: teeClub, club2: secondClub, hole: self.currentHole)
                            golfRoute.applyInitialBearingDeviations(teeShotDeviation: Double(bearing1Adjustment), secondShotDeviation: Double(bearing2Adjustment))
                            
                            // if second shot is not targetting fairway then skip this route
                            if !golfRoute.isSecondShotTargettingFairway() {
                                continue
                            }
                            
                            golfRoutes.append(golfRoute)
                        }
                    }
                }
                
                let routes = self.playRoutes(golfRoutes)
                
                self.showBestRoutesTargets(routes, teeClubIndex: teeClubIndex)
            }
        }
    }
    
    private func playRoutes(_ routes:[GolfShotRoute]) -> [GolfShotRoute] {
        var golfRoutes = routes.sorted { r1, r2 in
            return r1.optimalNumberOfShots < r2.optimalNumberOfShots
        }
        
        print("Created \(golfRoutes.count) possible routes with target variation.")
        
        func playAndSort(routes: [GolfShotRoute], numRounds: Int, percentRemaining: Double) -> [GolfShotRoute] {
            // Play top candidates a few times
            for route in routes {
                route.playHole(numInterations: numRounds)
            }
            
            return Array(golfRoutes.sorted { r1, r2 in
                return r1.averageNumberOfShots < r2.averageNumberOfShots
            }[0..<Int(percentRemaining * Double(routes.count))])
        }
        
        golfRoutes = playAndSort(routes: golfRoutes, numRounds: 50, percentRemaining: 0.5)
        golfRoutes = playAndSort(routes: golfRoutes, numRounds: 100, percentRemaining: 0.5)
        golfRoutes = playAndSort(routes: golfRoutes, numRounds: 300, percentRemaining: 1)
        
        #if DEBUG && targetEnvironment(simulator)
        let allSortedRoutes = Array(routes.sorted { r1, r2 in
            return r1.averageNumberOfShots < r2.averageNumberOfShots
        })
        for r in allSortedRoutes {
            print("Iterations: \(r.totalNumberOfIterations), Score: \(r.averageNumberOfShots)")
        }
        #endif
        
        print("Finished analysis.")
        return golfRoutes
    }
    
    private func showBestRoutesTargets(_ routes:[GolfShotRoute], teeClubIndex: Int) {
        DispatchQueue.main.async {
            
            let golfRoutes = Array(routes.prefix(10))
            
            var image = #imageLiteral(resourceName: "marker-distance")
            switch teeClubIndex {
                case 0: image = #imageLiteral(resourceName: "marker-longest")
                case 1: image = #imageLiteral(resourceName: "marker-distance-longdrive")
                case 2: image = #imageLiteral(resourceName: "marker-shortest")
                default: ()
            }
            
            #if DEBUG
            //get average number of shots for each second club then get the approximate position of the second shot target
            var shotsForClub = [String:Double]()
            let secondClubs = routes.compactMap({$0.club2})
            for club in secondClubs {
                let secondClubRoutes = routes.filter({$0.club2.id == club.id})
                let totalNumberOfShots = secondClubRoutes.map({$0.averageNumberOfShots}).reduce(0, +)
                let averageShotsWithSecondClub = Double(totalNumberOfShots) / Double(secondClubRoutes.count)
                shotsForClub[club.name] = averageShotsWithSecondClub
            }
            print(shotsForClub)
            #endif
            
            guard let bestRoute = golfRoutes.first else {
                return
            }
            let description = "Average of \(bestRoute.averageNumberOfShots) shots. \n \(bestRoute.club1.name) -> \(bestRoute.club2.name)"
            
            let target1Marker = GMSMarker(position: bestRoute.teeTarget.location)
            target1Marker.title = "Optimal Target"
            target1Marker.snippet = description
            target1Marker.icon = image.toNewSize(CGSize(width: 35, height: 35))
            target1Marker.map = self.mapView
            
            #if DEBUG
            let target2Marker = GMSMarker(position: bestRoute.secondShotTarget.location)
            target2Marker.title = "2nd Shot Target"
            target2Marker.snippet = description
            target2Marker.icon = image.toNewSize(CGSize(width: 35, height: 35))
            target2Marker.map = self.mapView
            #endif
        }
    }
    
    
    internal func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        guard !isDraggingMarker else {
            return
        }
        
        //Long press interferes with dragging - make new marker if not already dragging it
        if !isDraggingDistanceMarker {
            AudioServicesPlaySystemSound(1519)
            
            let distanceMarker = currentDistanceMarker ?? GMSMarker(position: coordinate)
            distanceMarker.isDraggable = true
            distanceMarker.map = mapView
            distanceMarker.icon = #imageLiteral(resourceName: "golf_ball_blank").toNewSize(CGSize(width: 30, height: 30))
            distanceMarker.userData = "distance_marker"
            self.currentDistanceMarker = distanceMarker
            
            mapView.selectedMarker = currentDistanceMarker;
            
            updateDistanceMarker()
        }
    }
    
    internal func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        AudioServicesPlaySystemSound(1519)
        switch marker {
        case currentTeeMarker:
            mapView.selectedMarker = marker
            self.isDraggingMarker = true
        case currentPinMarker:
            mapView.selectedMarker = marker
            self.isDraggingMarker = true
        default:
            if currentBunkerMarkers.contains(marker) {
                mapView.selectedMarker = marker
                self.isDraggingMarker = true
            } else {
                self.isDraggingDistanceMarker = true
                mapView.selectedMarker = currentDistanceMarker
            }
        }
    }
    internal func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        if marker == self.currentDistanceMarker {
            self.isDraggingDistanceMarker = false
        } else {
            self.isDraggingMarker = false
        }
        
        if (AppSingleton.shared.me.ambassadorCourses.contains(AppSingleton.shared.course!.id)) {
            switch marker {
            case currentTeeMarker:
                // update the tee location for this hole in firebase
                let successfulMove = self.currentHole.saveNewTeeLocation(marker.position)
                if !successfulMove {
                    // move marker back to original location
                    self.currentTeeMarker.position = self.currentHole.teeGeoPoints[0].location
                    
                    // show alert to user
                    let ac = UIAlertController(title: "Move Error", message: "Careful! You attempted to move the location of the teebox for this hole to an unreasonable distance from the pin. \n\nWith great power comes great responsibility... Please do not abuse this power or it may be revoked.", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            case currentPinMarker:
                // update the pin location for this hole in firebase
                let successfulMove = self.currentHole.saveNewPinLocation(marker.position)
                
                if !successfulMove {
                    // move marker back to original location
                    self.currentPinMarker.position = self.currentHole.pinGeoPoint.location
                    
                    // show alert to user
                    let ac = UIAlertController(title: "Move Error", message: "Careful! You attempted to move the location of the pin for this hole to an unreasonable distance from the teebox. \n\nWith great power comes great responsibility... Please do not abuse this power or it may be revoked.", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                } else {
                    //update distance to pin
                    markerTools.updatePinMarker(self.currentPinMarker, hole: self.currentHole, mapView: mapView)
                }
            case currentDistanceMarker: ()
                // do nothing - this will not need to be saved on the server
            default:
                if currentBunkerMarkers.contains(marker) {
                    // Update location of bunker on server
                    let successfulMove = self.currentHole.saveNewBunkerLocations(self.currentBunkerMarkers.compactMap({$0.position}))
                    
                    // move bunker markers location
                    // update the values of the bunker markers - subtitle - distance from pin
                    self.markerTools.updateBunkerMarkers(self.currentBunkerMarkers, hole: self.currentHole, mapView: mapView)
                    
                    if !successfulMove {
                        // show alert to user
                        let ac = UIAlertController(title: "Move Error", message: "Careful! You attempted to move the location of a bunker for this hole to an unreasonable distance from the teebox. \n\nWith great power comes great responsibility... Please do not abuse this power or it may be revoked.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
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
    
    private func updateSuggestionLines() {
        guard let distancePinTee = distanceToPinFromTee else {
            DebugLogger.log(message: "Unable to determine distance from pin to tee. No suggestion to provide.")
            return
        }
        
        guard let suggestedClubFromMyPin = me.bag.getClubSuggestion(distanceTo: distancePinTee) else {
            DebugLogger.log(message: "Unable to best club from bag. No suggestion to provide.")
            return
        }
        
        //if recommending club that is not driver - show recommended club lines
        if let distancePinMe = distanceToPinFromMyLocation,
            let distanceTeeMe = distanceToTeeFromMyLocation {
            let meIsNearPin = distancePinMe < 300
            let meIsNearTeeBox = distanceTeeMe < 100
            let meIsCloseToSelectedHole = distanceTeeMe + distancePinMe < distancePinTee + 100
            
            let suggestedClubFromMyLocation:Club = me.bag.getClubSuggestion(distanceTo: distancePinMe) ?? suggestedClubFromMyPin
            
            if meIsNearTeeBox {
                updateRecommendedClubLines(suggestedClubFromMyLocation, useDogLeg: true, useMyLocation: true)
            } else if meIsNearPin || meIsCloseToSelectedHole {
                updateRecommendedClubLines(suggestedClubFromMyLocation, useDogLeg: false)
            } else {
                //not close to the pin OR not close to the selected hole
                updateRecommendedClubLines(suggestedClubFromMyPin, useDogLeg: true, useMyLocation: false)
            }
        } else {
            updateRecommendedClubLines(suggestedClubFromMyPin, useDogLeg: true, useMyLocation: false)
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
            
            let pinLine = lineToPin ?? GMSPolyline(path: pinPath)
            pinLine.strokeWidth = 2
            pinLine.strokeColor = UIColor.white
            pinLine.geodesic = true
            pinLine.map = mapView
            pinLine.path = pinPath
            self.lineToPin = pinLine
        }
        
        let myLineLocation = lineToMyLocation ?? GMSPolyline(path: playerPath)
        myLineLocation.strokeWidth = 2
        myLineLocation.strokeColor = UIColor.white
        myLineLocation.geodesic = true
        myLineLocation.map = mapView
        myLineLocation.path = playerPath
        self.lineToMyLocation = myLineLocation
    }
    
    private func clearDistanceLines() {
        for line in drivingDistanceLines {
            line.map = nil
        }
        for line in suggestedDistanceLines {
            line.map = nil
        }
        drivingDistanceLines.removeAll()
        suggestedDistanceLines.removeAll()
    }
    
    private func updateRecommendedClubLines(_ suggestedClub:Club, useDogLeg: Bool, useMyLocation: Bool = true) {
        clearDistanceLines()
        
        let startGeopoint: GeoPoint
        if useMyLocation {
            startGeopoint = self.me.geoPoint ?? currentHole.teeGeoPoints[0]
        } else {
            startGeopoint = currentHole.teeGeoPoints[0]
        }
        
        let pinGeopoint:GeoPoint = currentHole.pinGeoPoint!
        
        let distanceToPin = mapTools.distanceFrom(first: startGeopoint, second: pinGeopoint)
        let bearingToPin:Double = mapTools.calcBearing(start: startGeopoint, finish: pinGeopoint)
        
        var bearingToTarget:Double = bearingToPin
        if let dll = currentHole.dogLegGeoPoint, useDogLeg {
            bearingToTarget = mapTools.calcBearing(start: startGeopoint, finish: dll)
        }
        
        let minBearing:Int = Int(bearingToTarget - 12)
        let maxBearing:Int = Int(bearingToTarget + 12)
        
        self.delegate?.updateSelectedClub(club: suggestedClub)
        
        
        //only show suggestion line if the min distance is less than current distance
        guard let shortestWedge:Club = self.me.bag.myClubs.last, shortestWedge.distance < distanceToPin else {
            print("Distance is too short for suggestion lines.")
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
                case -2: lineColor = UIColor.red
                case -1: lineColor = UIColor.orange
                case 0: lineColor = UIColor.green
                case 1: lineColor = UIColor.yellow
                default: lineColor = UIColor(white: 1, alpha: 0.25)
            }
            
            let distancePath = GMSMutablePath()
            for angle in minBearing..<maxBearing {
                let distanceCoords = mapTools.coordinates(startingCoordinates: startGeopoint.location, atDistance: Double(clubSelectionToShow.distance), atAngle: Double(angle))
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
