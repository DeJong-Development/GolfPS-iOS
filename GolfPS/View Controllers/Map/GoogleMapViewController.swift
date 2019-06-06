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

extension GoogleMapViewController: CLLocationManagerDelegate {
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.mapView.isMyLocationEnabled = (status == .authorizedWhenInUse || status == .authorizedAlways)
        mapView.settings.myLocationButton = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentPlayerLocation = locations.last
        
        if (currentPinMarker != nil) {
            let yardsToPin:Int = mapTools.distanceFrom(first: currentPlayerLocation!.coordinate, second: currentPinMarker.position)
            delegate.updateDistanceToPin(distance: yardsToPin)
            
            let suggestedClub:String = clubTools.getClubSuggestion(ydsTo: yardsToPin);
            delegate.updateSelectedClub(club: suggestedClub)
        }
        
        updateDistanceMarker()
    }
}

class GoogleMapViewController: UIViewController, GMSMapViewDelegate {
    
    let mapTools:MapTools = MapTools();
    let clubTools:ClubTools = ClubTools();
    
    var db:Firestore {
        return AppSingleton.shared.db
    }
    var mapView:GMSMapView!
    var delegate:ViewUpdateDelegate!
    
    let locationManager = CLLocationManager()
    var currentPlayerLocation:CLLocation? {
        didSet {
            //push location information to realtime database
            //separate out information about location to course information
            //only update position of people on the same course as you
            
            //only push info to server every 30 seconds? less?
            if let myMarker = myPlayerMarker, let location = currentPlayerLocation?.coordinate {
                myMarker.position = location
            } else if (currentPlayerLocation?.coordinate) != nil {
                createPlayerMarker()
            }
        }
    }
    
    private var currentHoleNumber:Int = 1;
    
    var course:Course!
    var currentHole:Hole!
    
    var myPlayerImage:UIImage? {
        didSet {
            self.createPlayerMarker()
        }
    }
    
    var myPlayerMarker:GMSMarker?
    
    var currentPinMarker:GMSMarker!
    var currentTeeMarker:GMSMarker!
    var currentBunkerMarkers:[GMSMarker] = [GMSMarker]();
    var currentDistanceMarker:GMSMarker?
    
    var isDraggingDistanceMarker:Bool = false
    
    var distanceLines:[GMSPolyline] = [GMSPolyline]();
    let distanceLineColors:[UIColor] = [UIColor.red, UIColor.magenta, UIColor.yellow];
    
    var lineToMyLocation:GMSPolyline?
    var lineToPin:GMSPolyline?
    
    var yardsToPressFromLocation:Int {
        if let playerLocation = currentPlayerLocation, let pressLocation = currentDistanceMarker?.position {
            return mapTools.distanceFrom(first: playerLocation.coordinate, second: pressLocation)
        } else {
            return -1;
        }
    }
    var yardsToPressFromTee:Int {
        if let pressLocation = currentDistanceMarker?.position {
            return mapTools.distanceFrom(first: currentTeeMarker.position, second: pressLocation)
        } else {
            return -1;
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    // Wrapper for obtaining keys from keys.plist
    func valueForAPIKey(keyname:String) -> String {
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
    }
    
    //first
    override func loadView() {
        super.loadView()
        GMSServices.provideAPIKey(valueForAPIKey(keyname: "GoogleMaps"))
        
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
        
        locationManager.startUpdatingLocation()
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
    
    internal func setCourse(_ course : Course) {
        self.course = course;
        
        //grab course hole information
        db.collection("courses").document(course.id)
            .collection("holes").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                course.holeInfo.removeAll();
                
                for document in querySnapshot!.documents {
                    //get all the courses and add to a course list
                    let data = document.data();
                    
                    if let holeNumber:Int = Int(document.documentID) {
                        let hole:Hole = Hole(number: holeNumber)
                        
                        guard let pinObj = data["pin"] as? GeoPoint else {
                            print("Invalid hole structure!")
                            return;
                        }
                        
                        hole.pinLocation = pinObj;
                        if let bunkerObj = data["bunkers"] as? [GeoPoint] {
                            hole.bunkerLocations = bunkerObj;
                        } else if let bunkerObj = data["bunkers"] as? GeoPoint {
                            hole.bunkerLocations = [bunkerObj];
                        }
                        if let teeObj = data["tee"] as? [GeoPoint] {
                            hole.teeLocations = teeObj;
                        } else if let teeObj = data["tee"] as? GeoPoint {
                            hole.teeLocations = [teeObj]
                        }
                        if let dlObj = data["dogLeg"] as? GeoPoint {
                            hole.dogLegLocation = dlObj
                        }
                        
                        course.holeInfo.append(hole);
                    }
                }
                self.goToHole();
            }
        }
    }
    
    public func goToHole(increment: Int = 0) {
        currentDistanceMarker?.map = nil;
        currentDistanceMarker = nil;
        lineToPin?.map = nil;
        lineToMyLocation?.map = nil;
        
        currentHoleNumber += increment;
        
        if (currentHoleNumber > course.holeInfo.count) {
            currentHoleNumber = 1;
        } else if currentHoleNumber <= 0 {
            currentHoleNumber = course.holeInfo.count
        }
        
        for hole in course.holeInfo {
            if (hole.holeNumber == currentHoleNumber) {
                currentHole = hole
                break;
            }
        }
        
        //tell main to update layout
        delegate.updateCurrentHole(num: currentHoleNumber);
        
        if (currentHole != nil) {
            updatePinMarker();
            updateTeeMarker();
            updateBunkerMarkers();
            updateDrivingDistanceLines();
            
            let bounds:GMSCoordinateBounds = updateMapBoundsForHole();
            moveCameraToHole(with:bounds);
            
            mapView.selectedMarker = currentPinMarker
            
            var yardsToPin = 1000;
            if let playerLocation = currentPlayerLocation {
                yardsToPin = mapTools.distanceFrom(first: playerLocation.coordinate, second: currentPinMarker.position)
            } else {
                yardsToPin = mapTools.distanceFrom(first: currentTeeMarker.position, second: currentPinMarker.position)
            }
            delegate.updateDistanceToPin(distance: yardsToPin)
            
            let suggestedClub:String = clubTools.getClubSuggestion(ydsTo: yardsToPin);
            delegate.updateSelectedClub(club: suggestedClub)
        }
    }
    
    private func moveCameraToHole(with bounds:GMSCoordinateBounds) {
        let zoom:Float = mapTools.getBoundsZoomLevel(bounds: bounds, screenSize: view.frame)
        let center:CLLocationCoordinate2D = mapTools.getBoundsCenter(bounds);
        
        let teeLocation:GeoPoint = currentHole.teeLocations[0]
        let pinLocation:GeoPoint = currentHole.pinLocation!
        var bearing:Double = mapTools.calcBearing(start: teeLocation, finish: pinLocation)
//        if let dlLocation = currentHole.dogLegLocation {
//            bearing = mapTools.calcBearing(start: teeLocation, finish: dlLocation)
//        }
        let newCameraView:GMSCameraPosition = GMSCameraPosition(target: center,
                                                                zoom: zoom,
                                                                bearing: bearing - 20,
                                                                viewingAngle: 45)
        mapView.animate(to: newCameraView)
    }

    private func updateMapBoundsForHole() -> GMSCoordinateBounds {
        var bounds:GMSCoordinateBounds = GMSCoordinateBounds();
        for tPoint in currentHole.teeLocations {
            let coordinate = CLLocationCoordinate2D(latitude: tPoint.latitude, longitude: tPoint.longitude)
            bounds = bounds.includingCoordinate(coordinate);
        }
        for blPoint in currentHole.bunkerLocations {
            let coordinate = CLLocationCoordinate2D(latitude: blPoint.latitude, longitude: blPoint.longitude)
            bounds = bounds.includingCoordinate(coordinate);
        }
        if let dlPoint = currentHole.dogLegLocation {
            let coordinate = CLLocationCoordinate2D(latitude: dlPoint.latitude, longitude: dlPoint.longitude)
            bounds = bounds.includingCoordinate(coordinate);
        }
        let pinLocation:GeoPoint = currentHole.pinLocation!
        let pinCoordinate = CLLocationCoordinate2D(latitude: pinLocation.latitude, longitude: pinLocation.longitude)
        bounds = bounds.includingCoordinate(pinCoordinate);
        return bounds;
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
        let teeLocation:GeoPoint = currentHole.teeLocations[0];
        let loc:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: teeLocation.latitude, longitude: teeLocation.longitude)
        
        currentTeeMarker = GMSMarker(position: loc)
        currentTeeMarker.title = "Tee #\(currentHoleNumber)"
        currentTeeMarker.icon = #imageLiteral(resourceName: "tee_marker").toNewSize(CGSize(width: 55, height: 55))
        currentTeeMarker.userData = "\(currentHoleNumber):T";
        currentTeeMarker.map = mapView;
    }
    private func updatePinMarker() {
        let pinLocation:GeoPoint = currentHole.pinLocation!
        let pinLoc:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: pinLocation.latitude, longitude: pinLocation.longitude)
        
        let teeLocation:GeoPoint = currentHole.teeLocations[0]
        let teeLoc:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: teeLocation.latitude, longitude: teeLocation.longitude)
        let yardsToPin:Int = mapTools.distanceFrom(first: pinLoc, second: teeLoc)
        
        if (currentPinMarker != nil) {
            currentPinMarker.map = nil
        }
        currentPinMarker = GMSMarker(position: pinLoc)
        currentPinMarker.title = "Pin #\(currentHoleNumber)"
        currentPinMarker.snippet = "\(yardsToPin) yds"
        currentPinMarker.icon = #imageLiteral(resourceName: "flag_marker").toNewSize(CGSize(width: 55, height: 55))
        currentPinMarker.userData = "\(currentHoleNumber):P";
        currentPinMarker.map = mapView;
    }
    private func updateBunkerMarkers() {
        for bunkerMarker in currentBunkerMarkers {
            bunkerMarker.map = nil
        }
        currentBunkerMarkers.removeAll()
        
        let bunkerLocationsForHole:[GeoPoint] = currentHole.bunkerLocations
        for (bunkerIndex,bunkerLocation) in bunkerLocationsForHole.enumerated() {
            let bunkerLoc = CLLocationCoordinate2D(latitude: bunkerLocation.latitude,
                                                   longitude: bunkerLocation.longitude)
            let teeLoc = CLLocationCoordinate2D(latitude: currentTeeMarker.position.latitude,
                                                longitude: currentTeeMarker.position.longitude)
            let yardsToBunker:Int = mapTools.distanceFrom(first: bunkerLoc, second: teeLoc)
            
            let bunkerMarker = GMSMarker(position: bunkerLoc)
            bunkerMarker.title = "Bunker"
            bunkerMarker.snippet = "\(yardsToBunker) yds"
            bunkerMarker.icon = #imageLiteral(resourceName: "hazard_marker").toNewSize(CGSize(width: 35, height: 35))
            bunkerMarker.userData = "\(currentHoleNumber):B\(bunkerIndex)";
            bunkerMarker.map = mapView;
            
            currentBunkerMarkers.append(bunkerMarker);
        }
    }
    private func updateDrivingDistanceLines() {
        for line in distanceLines {
            line.map = nil;
        }
        distanceLines.removeAll()
        
        let teeLocation:GeoPoint = currentHole.teeLocations[0];
        let pinLocation:GeoPoint = currentHole.pinLocation!;
        let bearingToPin:Double = mapTools.calcBearing(start: teeLocation, finish: currentHole.pinLocation!)
        var bearingToDogLeg:Double = bearingToPin
        if let dll = currentHole.dogLegLocation {
            bearingToDogLeg = mapTools.calcBearing(start: teeLocation, finish: dll)
        }
        
        let minBearing:Int = Int(bearingToDogLeg - 12)
        let maxBearing:Int = Int(bearingToDogLeg + 12)
//        let minBearing:Int = Int(min(bearingToPin, bearingToDogLeg) - 12)
//        let maxBearing:Int = Int(max(bearingToPin, bearingToDogLeg) + 12)
        
        let teeLoc:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: teeLocation.latitude, longitude: teeLocation.longitude)
        let pinLoc:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: pinLocation.latitude, longitude: pinLocation.longitude)
        let teeYardsToPin:Int = mapTools.distanceFrom(first: teeLoc, second: pinLoc)
        
        if (clubTools.getClubDistance(num: 1) < teeYardsToPin) {
            for i in 0..<3 {
                let distance = clubTools.getClubDistance(num: i + 1)
                let lineColor:UIColor = distanceLineColors[i]
                
                let distancePath = GMSMutablePath()
                for angle in minBearing..<maxBearing {
                    let distanceCoords = mapTools.coordinates(startingCoordinates: teeLoc, atDistance: Double(distance), atAngle: Double(angle))
                    distancePath.add(distanceCoords)
                }
                let distanceLine = GMSPolyline(path: distancePath)
                distanceLine.strokeColor = lineColor;
                distanceLine.strokeWidth = 2
                distanceLine.map = mapView
                
                distanceLines.append(distanceLine)
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        //Long press interferes with dragging - make new marker if not already dragging it
        if !isDraggingDistanceMarker {
            AudioServicesPlaySystemSound(1519)
            currentDistanceMarker?.map = nil
            currentDistanceMarker = GMSMarker(position: coordinate)
            currentDistanceMarker!.isDraggable = true
            currentDistanceMarker!.map = mapView;
            let markerImage = #imageLiteral(resourceName: "golf_ball_blank")
            currentDistanceMarker!.icon = markerImage.toNewSize(CGSize(width: 30, height: 30))
            currentDistanceMarker!.userData = "distance_marker";
            
            mapView.selectedMarker = currentDistanceMarker;
            
            updateDistanceMarker()
        }
    }
    
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        AudioServicesPlaySystemSound(1519)
        self.isDraggingDistanceMarker = true
        mapView.selectedMarker = currentDistanceMarker;
    }
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        self.isDraggingDistanceMarker = false
    }
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        if (marker == currentDistanceMarker) {
            updateDistanceMarker()
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        mapView.selectedMarker = marker;
        return true;
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        currentDistanceMarker?.map = nil
        mapView.selectedMarker = nil
        
        lineToPin?.map = nil;
        lineToMyLocation?.map = nil;
        currentDistanceMarker = nil
    }
    
    private func updateDistanceMarker() {
        if (currentDistanceMarker != nil && yardsToPressFromTee > 0) {
            let usingLocation:Bool = (yardsToPressFromLocation < 1000 && yardsToPressFromLocation > 0)
            let suggestedClub:String = clubTools.getClubSuggestion(ydsTo: (usingLocation) ? yardsToPressFromLocation : yardsToPressFromTee);
            
            currentDistanceMarker!.title = usingLocation ? "\(yardsToPressFromLocation) yds" : "\(yardsToPressFromTee) yds"
            currentDistanceMarker!.snippet = suggestedClub
            
            let pinPath = GMSMutablePath()
            pinPath.add(currentDistanceMarker!.position)
            pinPath.add(currentPinMarker.position)
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
            
            let playerPath = GMSMutablePath()
            if (yardsToPressFromLocation < 1000 && yardsToPressFromLocation > 0) {
                if let playerLocation = currentPlayerLocation {
                    playerPath.add(playerLocation.coordinate)
                    playerPath.add(currentDistanceMarker!.position)
                }
            } else if (yardsToPressFromTee > 0) {
                playerPath.add(currentTeeMarker.position)
                playerPath.add(currentDistanceMarker!.position)
            } else {
                print("invalid positions!!!")
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
    }
}
