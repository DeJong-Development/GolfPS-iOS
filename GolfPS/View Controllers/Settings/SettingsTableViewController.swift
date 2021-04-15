//
//  SettingsTableViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/18/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import UIKit
import SCSDKLoginKit

protocol SettingsActionDelegate: class {
    func removeAvatar()
    func updateAvatar()
}

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var locationShareSwitch: UISwitch!
    @IBOutlet weak var bitmojiShareSwitch: UISwitch!

    @IBOutlet weak var bitmojiShareTitle: UILabel!
    
    @IBOutlet weak var locationShareInfoButton: UIButton!
    @IBOutlet weak var bitmojiShareInfoButton: UIButton!
    
    @IBOutlet weak var metricControl: UISegmentedControl!
    
    weak var actionDelegate: SettingsActionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        
        metricControl.selectedSegmentIndex = AppSingleton.shared.metric ? 1 : 0

        locationShareSwitch.setOn(AppSingleton.shared.me.shareLocation, animated: false)
        if (!AppSingleton.shared.me.shareLocation) {
            AppSingleton.shared.db.collection("players").document(AppSingleton.shared.me.id).delete()
            AppSingleton.shared.me.geoPoint = nil
            bitmojiShareSwitch.setOn(false, animated: false)

            AppSingleton.shared.me.shareBitmoji = false
            actionDelegate?.removeAvatar()
        } else {
            bitmojiShareSwitch.setOn(AppSingleton.shared.me.shareBitmoji, animated: false)
        }
        
        updateBitSwitch()
        
        self.tableView.tableFooterView = UIView()
    }
    
    @IBAction func switchUnits(_ sender: UISegmentedControl) {
        AppSingleton.shared.metric = (sender.selectedSegmentIndex == 1)
    }
    
    @IBAction func switchMapShare(_ sender: UISwitch) {
        //update in app preferences
        AppSingleton.shared.me.shareLocation = sender.isOn
        updateBitSwitch()

        if (!AppSingleton.shared.me.shareLocation) {
            //if user elects to stop sharing location
            //remove all data on server
            AppSingleton.shared.db.collection("players").document(AppSingleton.shared.me.id).delete()
            AppSingleton.shared.me.geoPoint = nil

            //remove bitmoji and turn off sharing option
            self.bitmojiShareSwitch.setOn(false, animated: true)
            AppSingleton.shared.me.shareBitmoji = false
            
            actionDelegate?.removeAvatar()
        }
    }
    @IBAction func switchBitmojiShare(_ sender: UISwitch) {
        //update in app preferences
        AppSingleton.shared.me.shareBitmoji = sender.isOn

        if (sender.isOn) {
            //get up to date bitmoji avatar url
            actionDelegate?.updateAvatar()
        } else {
            actionDelegate?.removeAvatar()
        }
    }
    
    internal func updateBitSwitch() {
        if (AppSingleton.shared.me.shareLocation && SCSDKLoginClient.isUserLoggedIn) {
            bitmojiShareSwitch.isEnabled = true
            bitmojiShareTitle.alpha = 1
        } else {
            bitmojiShareSwitch.isEnabled = false
            bitmojiShareTitle.alpha = 0.5
            bitmojiShareSwitch.isOn = false
        }
    }

    @IBAction func clickLocationShareInfo(_ sender: UIButton) {
        let ac = UIAlertController(title: "Location Share Info", message: "By enabling this option, your location on the course will be shared with other golfers on the same golf course. If you are not near the course when using the app, your location in app will be at the clubhouse.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
    }
    @IBAction func clickBitmojiShareInfo(_ sender: UIButton) {
        let ac = UIAlertController(title: "Bitmoji Share Info", message: "By enabling this option, your Bitmoji will be used in to display your location to other golfers on the same course.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
    }
}
