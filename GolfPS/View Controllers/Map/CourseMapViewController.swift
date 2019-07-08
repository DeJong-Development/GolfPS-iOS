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
    func updateCurrentHole(num: Int)
}

class CourseMapViewController: UIViewController, ViewUpdateDelegate {
    
    @IBOutlet weak var prevHoleButton: UIButton!
    @IBOutlet weak var nextHoleButton: UIButton!
    @IBOutlet weak var courseNameButton: UIButton!
    @IBOutlet weak var distanceToPinLabel: UILabel!
    @IBOutlet weak var selectedClubLabel: UILabel!
    @IBOutlet weak var currentHoleLabel: UIButton!
    
    var embeddedMapViewController:GoogleMapViewController!
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        courseNameButton.setTitle(AppSingleton.shared.course?.name ?? "SELECT COURSE", for: .normal)
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
    
    internal func updateCurrentHole(num: Int) {
        currentHoleLabel.setTitle("#\(num)", for: .normal)
    }
    internal func updateDistanceToPin(distance: Int) {
        distanceToPinLabel.text = "\(distance) yds"
    }
    internal func updateSelectedClub(club: Club) {
        selectedClubLabel.text = club.name
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
}

