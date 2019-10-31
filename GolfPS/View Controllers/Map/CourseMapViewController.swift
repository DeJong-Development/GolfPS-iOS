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

protocol ViewUpdateDelegate: class {
    func updateDistanceToPin(distance: Int);
    func updateSelectedClub(club: Club);
    func updateCurrentHole(hole: Hole);
}

class CourseMapViewController: UIViewController, ViewUpdateDelegate {
    
    @IBOutlet weak var prevHoleButton: UIButton!
    @IBOutlet weak var nextHoleButton: UIButton!
    @IBOutlet weak var courseNameButton: UIButton!
    @IBOutlet weak var distanceToPinLabel: UILabel!
    @IBOutlet weak var selectedClubLabel: UILabel!
    @IBOutlet weak var currentHoleLabel: UIButton!
    
    @IBOutlet weak var longDriveButton: ButtonX!
    @IBOutlet weak var longDriveButtonStack: UIStackView!
    @IBOutlet weak var myDriveLabel: UILabel!
    @IBOutlet weak var markButton: ButtonX!
    @IBOutlet weak var clearButton: ButtonX!
    
    //use these constraints to add space under long drive options
    @IBOutlet weak var showDriveStackConstraint: NSLayoutConstraint!
    @IBOutlet weak var hideDriveStackConstraint: NSLayoutConstraint!
    
    var embeddedMapViewController:GoogleMapViewController!
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
        
        longDriveButton.cornersToRound = [.topLeft, .topRight]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "GoogleMapEmbed") {
            if let vc = segue.destination as? GoogleMapViewController {
                self.embeddedMapViewController = vc
                self.embeddedMapViewController.delegate = self;
            }
        }
    }
    
    internal func updateCurrentHole(hole: Hole) {
        currentHoleLabel.setTitle("#\(hole.number)", for: .normal)
        
        if (hole.isLongDrive) {
            showLongDrive(hideStack: true)
        } else {
            hideLongDrive(hideButton: true)
        }
    }
    internal func updateDistanceToPin(distance: Int) {
        if AppSingleton.shared.metric {
            distanceToPinLabel.text = "\(distance) m"
        } else {
            distanceToPinLabel.text = "\(distance) yds"
        }
    }
    internal func updateSelectedClub(club: Club) {
        selectedClubLabel.text = club.name
    }
    
    internal func goToHole1() {
        if let course = AppSingleton.shared.course, let firstHole = course.holeInfo.first {
            embeddedMapViewController.currentHole = firstHole
            embeddedMapViewController.goToHole()
        }
    }
    
    @IBAction func nextHoleButton(_ sender: UIButton) {
        if (AppSingleton.shared.course != nil) {
            embeddedMapViewController.goToHole(increment: 1)
        }
    }
    @IBAction func previousHoleButton(_ sender: UIButton) {
        if (AppSingleton.shared.course != nil) {
            embeddedMapViewController.goToHole(increment: -1)
        }
    }
    @IBAction func clickCourseName(_ sender: UIButton) {
        if (AppSingleton.shared.course == nil) {
           (self.tabBarController as! TabParentViewController).selectedIndex = 0
        }
    }
    
    @IBAction func clickLongDrive(_ sender: Any) {
        if longDriveButtonStack.isHidden { //show
            showLongDrive(hideStack: false)
        } else { //hide
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
            if AppSingleton.shared.metric {
                myDriveLabel.text = "\(myDrive) m"
            } else {
                myDriveLabel.text = "\(myDrive) yds"
            }
            markButton.isHidden = true
            clearButton.isHidden = false
            
            longDriveButtonStack.isHidden = false
            
            //if value exists then always show the stack
            hideDriveStackConstraint.isActive = false
            showDriveStackConstraint.isActive = true
        } else {
            //no value so hide the label
            myDriveLabel.isHidden = true
            clearButton.isHidden = true
            markButton.isHidden = false
            longDriveButtonStack.isHidden = hideStack
            
            if (hideStack) { //also set constraints based on stack visibility
                showDriveStackConstraint.isActive = false
                hideDriveStackConstraint.isActive = true
            } else {
                hideDriveStackConstraint.isActive = false
                showDriveStackConstraint.isActive = true
            }
        }
        
        self.view.layoutIfNeeded()
    }
    
    private func hideLongDrive(hideButton:Bool) {
        longDriveButton.isHidden = hideButton
        longDriveButtonStack.isHidden = true
        showDriveStackConstraint.isActive = false
        hideDriveStackConstraint.isActive = true
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}

