//
//  InterfaceController.swift
//  GolfPS Companion Extension
//
//  Created by Greg DeJong on 4/30/20.
//  Copyright © 2020 DeJong Development. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet weak var yardageLabel: WKInterfaceLabel!
    @IBOutlet weak var lengthUnitLabel: WKInterfaceLabel!
    @IBOutlet weak var clubRecommendationLabel: WKInterfaceLabel!
    
    @IBOutlet weak var holeNumberLabel: WKInterfaceLabel!
    @IBOutlet weak var previousHoleButton: WKInterfaceButton!
    @IBOutlet weak var nextHoleButton: WKInterfaceButton!
    
    var wcSession : WCSession!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func clickPreviousHole() {
        wcSession.sendMessage(["gotoprevious": true], replyHandler: nil) { (error) in
            print(error.localizedDescription)
        }
    }
    @IBAction func clickNextHole() {
        wcSession.sendMessage(["gotonext": true], replyHandler: nil) { (error) in
            print(error.localizedDescription)
        }
    }
    
    // MARK: WCSession Methods
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        if let distance = message["distance"] as? Int {
            yardageLabel.setText(String(distance))
        }
        if let hole = message["hole"] as? Int {
            holeNumberLabel.setText("#\(hole)")
        }
        if let units = message["units"] as? String {
            lengthUnitLabel.setText(units)
        }
        if let club = message["club"] as? String {
            clubRecommendationLabel.setText(club)
        }
        if let courseId = message["course"] as? String {
            if courseId == "" {
                //there is no course, remove everything
                yardageLabel.setText(nil)
                holeNumberLabel.setText("#")
                lengthUnitLabel.setText(nil)
                clubRecommendationLabel.setText(nil)
            }
        }
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        // Code.
        
    }

}
