//
//  ViewController.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/19/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import WatchConnectivity

protocol ViewUpdateDelegate: AnyObject {
    func updateDistanceToPin(distance: Int)
    func updateSelectedClub(club: Club)
    func updateCurrentHole(hole: Hole)
    func updateElevationEffect(height: Double, distance: Double)
    func updateWindEffect(speed: Double, distance: Double)
}

class CourseMapViewController: UIViewController, ViewUpdateDelegate, WCSessionDelegate {

    @IBOutlet weak var actionStackView: UIView!
    @IBOutlet weak var backButton: ButtonX!
    @IBOutlet weak var prevHoleButton: UIButton!
    @IBOutlet weak var nextHoleButton: UIButton!
    @IBOutlet weak var courseNameButton: UIButton!
    @IBOutlet weak var distanceToPinLabel: UILabel!
    @IBOutlet weak var selectedClubLabel: UILabel!
    @IBOutlet weak var currentHoleLabel: UIButton!
    
    @IBOutlet weak var elevationLabel: UILabel!
    
    @IBOutlet weak var longDriveButton: ButtonX!
    @IBOutlet weak var longDriveButtonStack: UIStackView!
    @IBOutlet weak var myDriveLabel: UILabel!
    @IBOutlet weak var markButton: ButtonX!
    @IBOutlet weak var clearButton: ButtonX!
    
    @IBOutlet weak var calculateDriveLocationButton: ButtonX!
    @IBOutlet weak var calculateHeatMapButton: ButtonX!
    
    private var wcSession : WCSession? = nil
    private var embeddedMapViewController:GoogleMapViewController!
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let wcs = wcSession, wcs.isReachable {
            wcs.sendMessage(["course": ""], replyHandler: nil) { (error) in
                DebugLogger.report(error: error, message: "Error resetting course on watch.")
            }
        }
        wcSession?.delegate = nil
        wcSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        longDriveButton.isHidden = true
        longDriveButtonStack.isHidden = true
        
        if let course = AppSingleton.shared.course {
            courseNameButton.setTitle(course.name, for: .normal)
            courseNameButton.isHidden = false
            distanceToPinLabel.isHidden = false
            selectedClubLabel.isHidden = false
            
            if course.name.lowercased().contains("hickory") {
                calculateDriveLocationButton.isHidden = false
            }
        } else {
            courseNameButton.isHidden = true
            distanceToPinLabel.isHidden = true
            selectedClubLabel.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        courseNameButton.layer.cornerRadius = 6
        courseNameButton.layer.masksToBounds = true
        
        prevHoleButton.layer.borderColor = UIColor.lightGray.cgColor
        prevHoleButton.layer.borderWidth = 1
        prevHoleButton.layer.cornerRadius = 6
        prevHoleButton.layer.masksToBounds = true
        
        nextHoleButton.layer.borderColor = UIColor.lightGray.cgColor
        nextHoleButton.layer.borderWidth = 1
        nextHoleButton.layer.cornerRadius = 6
        nextHoleButton.layer.masksToBounds = true
        
        calculateDriveLocationButton.isHidden = true
        calculateHeatMapButton.isHidden = true
        
        if (WCSession.isSupported()) {
            wcSession = WCSession.default
            wcSession!.delegate = self
            wcSession!.activate()
        }
    }
    
    internal func updateCurrentHole(hole: Hole) {
        currentHoleLabel.setTitle("#\(hole.number)", for: .normal)
        
        if let wcs = wcSession, wcs.isReachable {
            wcs.sendMessage(["hole": hole.number], replyHandler: nil) { (error) in
                DebugLogger.report(error: error, message: "Error sending hole to watch")
            }
        }
        
        self.calculateDriveLocationButton.isEnabled = hole.distance > 300
        
        if (hole.isLongDrive) {
            hole.getLongestDrives()
            showLongDrive(hideStack: false)
        } else {
            hideLongDrive(hideButton: true)
        }
    }
    internal func updateDistanceToPin(distance: Int) {
        var message:[String:Any] = [
            "distance": distance,
            "hole": self.embeddedMapViewController.currentHole.number
        ]
        
        distanceToPinLabel.text = distance.distance
        message["units"] = AppSingleton.shared.metric ? "m" : "yds"
        
        if let wcs = wcSession, wcs.isReachable {
            wcs.sendMessage(message, replyHandler: nil) { (error) in
                DebugLogger.report(error: error, message: "Error updating distance on watch.")
            }
        }
    }
    internal func updateSelectedClub(club: Club) {
        selectedClubLabel.text = club.name
        
        if let wcs = wcSession, wcs.isReachable {
            wcs.sendMessage(["club": club.name], replyHandler: nil) { (error) in
                DebugLogger.report(error: error, message: "Error updating club on watch.")
            }
        }
    }
    
    internal func updateElevationEffect(height: Double, distance: Double) {
        DebugLogger.log(message: "Height reported \(height)")
        DispatchQueue.main.async {
            if (distance > 0) {
                self.elevationLabel.text = "+\(distance.distance)"
            } else {
                self.elevationLabel.text = distance.distance
            }
        }
    }
    internal func updateWindEffect(speed: Double, distance: Double) {
//        DispatchQueue.main.async {
//            self.windLabel.text = distance.distance
//        }
    }
    
    @IBAction func clickBack(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToSelection", sender: nil)
    }
    @IBAction func nextHoleButton(_ sender: UIButton?) {
        guard (AppSingleton.shared.course != nil) else {
            return
        }
        embeddedMapViewController.goToHole(increment: 1)
    }
    @IBAction func previousHoleButton(_ sender: UIButton?) {
        guard (AppSingleton.shared.course != nil) else {
            return
        }
        embeddedMapViewController.goToHole(increment: -1)
    }
    @IBAction func clickCourseName(_ sender: UIButton) {
        guard AppSingleton.shared.course == nil else {
            return
        }
        self.performSegue(withIdentifier: "unwindToSelection", sender: nil)
    }
    
    @IBAction func clickCalculateDriveLocation(_ sender: Any) {
        embeddedMapViewController.calculateOptimalDriveLocation()
    }
    
    @IBAction func clickCalculateHeatmap(_ sender: Any) {
//        embeddedMapViewController.createHeatmap()
    }
    
    @IBAction func clickLongDrive(_ sender: Any) {
        if longDriveButtonStack.isHidden {
            showLongDrive(hideStack: false)
        } else {
            hideLongDrive(hideButton: false)
        }
    }
    @IBAction func clickMarkButton(_ sender: Any) {
        embeddedMapViewController.addDrivePrompt()
    }
    
    @IBAction func clickClearButton(_ sender: Any) {
        myDriveLabel.isHidden = true
        markButton.isHidden = false
        clearButton.isHidden = true
        
        //remove the drive from the firestore
        if let holeDocRef = embeddedMapViewController.currentHole.docReference {
            let userId = AppSingleton.shared.me.id
            holeDocRef.collection("drives").document(userId).delete()
        }
        
        //remove marker from the map
        embeddedMapViewController.removeMyDriveMarker()
    }
    
    private func showLongDrive(hideStack:Bool) {
        longDriveButton.isHidden = false
        
        var driveDistance:Int? = nil
        if AppSingleton.shared.metric {
            driveDistance = embeddedMapViewController.currentHole.myLongestDriveInMeters
        } else {
            driveDistance = embeddedMapViewController.currentHole.myLongestDriveInYards
        }
            
        if let myDrive = driveDistance {
            myDriveLabel.isHidden = false
            myDriveLabel.text = myDrive.distance
            markButton.isHidden = true
            clearButton.isHidden = false
            
            longDriveButtonStack.isHidden = false
        } else {
            //no value so hide the label
            myDriveLabel.isHidden = true
            clearButton.isHidden = true
            markButton.isHidden = false
            longDriveButtonStack.isHidden = hideStack
        }
        
        self.view.layoutIfNeeded()
    }
    
    private func hideLongDrive(hideButton:Bool) {
        longDriveButton.isHidden = hideButton
        longDriveButtonStack.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: WCSession Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if message["gotonext"] != nil {
                self.nextHoleButton(nil)
            } else if message["gotoprevious"] != nil {
                self.previousHoleButton(nil)
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) { }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as GoogleMapViewController:
            self.embeddedMapViewController = vc
            self.embeddedMapViewController.delegate = self
        default: ()
        }
    }
}

