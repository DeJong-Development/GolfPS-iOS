//
//  TodayViewController.swift
//  GolfPS Widget
//
//  Created by Greg DeJong on 7/20/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var courseNameLabel: UILabel!
    @IBOutlet weak var holeNumberLabel: UILabel!
    @IBOutlet weak var currentYardsLabel: UILabel!
    
    let todayExtensionValues = UserDefaults.init(suiteName: "group.dejongdevelopment.golfps")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        refreshButton.layer.borderColor = UIColor.lightGray.cgColor
        refreshButton.layer.borderWidth = 1
        refreshButton.layer.cornerRadius = refreshButton.frame.height / 2
        refreshButton.layer.masksToBounds = true
        
        if let yardsToPin = todayExtensionValues?.value(forKey: "test_yards") {
            currentYardsLabel.text = yardsToPin as? String
        } else {
            currentYardsLabel.text = "- yds"
        }
        if let holeNumber = todayExtensionValues?.value(forKey: "test_holeNum") {
            holeNumberLabel.text = holeNumber as? String
        } else {
            holeNumberLabel.text = "Hole #"
        }
        if let courseName = todayExtensionValues?.value(forKey: "test_courseName") {
            courseNameLabel.text = courseName as? String
        } else {
            courseNameLabel.text = "Time to go golfing!"
        }
    }
        
    @IBAction func clickRefresh(_ sender: UIButton) {
        if let yardsToPin = todayExtensionValues?.value(forKey: "test_yards"),
            let holeNumber = todayExtensionValues?.value(forKey: "test_holeNum"),
            let courseName = todayExtensionValues?.value(forKey: "test_courseName") {
            if yardsToPin as? String != currentYardsLabel.text {
                currentYardsLabel.text = yardsToPin as? String
            }
            if holeNumber as? String != holeNumberLabel.text {
                holeNumberLabel.text = holeNumber as? String
            }
            if courseName as? String != courseNameLabel.text {
                courseNameLabel.text = courseName as? String
            }
        }
    }
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        var didChange:Bool = false
        
        if let yardsToPin = todayExtensionValues?.value(forKey: "test_yards"),
            let holeNumber = todayExtensionValues?.value(forKey: "test_holeNum"),
            let courseName = todayExtensionValues?.value(forKey: "test_courseName") {
            if yardsToPin as? String != currentYardsLabel.text {
                currentYardsLabel.text = yardsToPin as? String
                didChange = true
            }
            if holeNumber as? String != holeNumberLabel.text {
                holeNumberLabel.text = holeNumber as? String
                didChange = true
            }
            if courseName as? String != courseNameLabel.text {
                courseNameLabel.text = courseName as? String
                didChange = true
            }
        } else {
            courseNameLabel.text = "Time to go golfing!"
            currentYardsLabel.text = "- yds"
            holeNumberLabel.text = "Hole #"
        }
        completionHandler((didChange) ? NCUpdateResult.newData : NCUpdateResult.noData)
    }
}
