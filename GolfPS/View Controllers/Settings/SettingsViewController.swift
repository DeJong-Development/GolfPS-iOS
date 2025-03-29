//
//  SettingsViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 7/26/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import SCSDKLoginKit

extension SettingsViewController: SettingsActionDelegate {
    
    ///Changed permissions - so lets remove the bitmoji avatar
    func removeAvatar() {
        self.avatarURLToShare = nil
    }
    
    ///Changed permissions - so lets make sure we are properly displaying the bitmoji avatar.
    func updateAvatar() {
        //Do not need to update the displayed avatar image
        BitmojiUtility.getBitmojiURL { bitmojiUrl in
            self.avatarURLToShare = bitmojiUrl
        }
    }
}

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var snapLink: UIButton!
    @IBOutlet weak var bitmojiImage: UIImageView!
    @IBOutlet weak var buyMeADrinkButton: ButtonX!
    
    var embeddedTableViewController: SettingsTableViewController!
    
    ///If nil, removes shared url from firestore, else updates value on server.
    var avatarURLToShare:URL? = nil {
        didSet {
            if (AppSingleton.shared.me.shareBitmoji && avatarURLToShare != nil) {
                AppSingleton.shared.db.collection("players")
                    .document(AppSingleton.shared.me.id)
                    .setData(["image": avatarURLToShare!.absoluteString], merge: true)
            } else {
                AppSingleton.shared.db.collection("players")
                    .document(AppSingleton.shared.me.id)
                    .setData(["image": ""], merge: true)
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (SCSDKLoginClient.isUserLoggedIn) {
            //get bitmoji avatar
            BitmojiUtility.downloadBitmojiImage { bitmojiUrl, bitmojiImage in
                self.avatarURLToShare = bitmojiUrl
                DispatchQueue.main.async {
                    self.bitmojiImage.image = bitmojiImage
                }
            }
        }
        
        updateButtonLabel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bitmojiImage.contentMode = .scaleAspectFit
        snapLink.layer.cornerRadius = 8
        
        if !AppSingleton.shared.me.shareLocation {
            self.avatarURLToShare = nil
        }
    }
    
    @IBAction func clickSnapLink(_ sender: Any) {
        AnalyticsLogger.log(name: "click_snap_link")
        
        if (SCSDKLoginClient.isUserLoggedIn) {
            self.embeddedTableViewController.bitmojiShareSwitch.setOn(false, animated: true)
            AppSingleton.shared.me.shareBitmoji = false
            
            //change to "Unlink" after we are all logged in
            SCSDKLoginClient.clearToken()
            
            self.updateButtonLabel()
            self.embeddedTableViewController.updateBitSwitch()
            
            let ac = UIAlertController(title: "Unlinked!", message: "Your Snapchat account has been logged out!", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        } else {
            //once this is linked - it will always be linked
            //set up with a "Link Snapchat Bitmoji" button or something like that
            SCSDKLoginClient.login(from: self, completion: { success, error in
                DispatchQueue.main.async {
                    self.updateButtonLabel()
                    self.embeddedTableViewController.updateBitSwitch()
                }
                
                BitmojiUtility.downloadBitmojiImage { bitmojiUrl, bitmojiImage in
                    self.avatarURLToShare = bitmojiUrl
                    DispatchQueue.main.async {
                        self.bitmojiImage.image = bitmojiImage
                    }
                }
            })
        }
    }
    
    @IBAction func clickBuyMeADrink(_ sender: Any) {
    }
    
    @IBAction func clickPrivacy(_ sender: UIButton) {
        AnalyticsLogger.log(name: "click_privacy_settings")
        
        guard let privacyURL:URL = URL(string: "https://golfps-dejongdevelopment.firebaseapp.com/privacy_policy.html") else {
            return
        }
        UIApplication.shared.open(privacyURL, options: [:], completionHandler: nil)
    }
    @IBAction func clickTerms(_ sender: UIButton) {
        AnalyticsLogger.log(name: "click_terms_settings")
        
        guard let termsURL:URL = URL(string: "https://golfps-dejongdevelopment.firebaseapp.com/terms_and_conditions.html") else {
            return
        }
        UIApplication.shared.open(termsURL, options: [:], completionHandler: nil)
    }
    
    private func updateButtonLabel() {
        DispatchQueue.main.async {
            if (SCSDKLoginClient.isUserLoggedIn) {
                AnalyticsLogger.setSnapchat(usingSnapchat: true)
                
                self.snapLink.setTitle("Disconnect Snapchat", for: .normal)
                self.snapLink.backgroundColor = UIColor(red: 0.235, green: 0.698, blue: 0.886, alpha: 1)
                
            } else {
                AnalyticsLogger.setSnapchat(usingSnapchat: false)
                
                self.snapLink.setTitle("Link Snapchat", for: .normal)
                self.snapLink.backgroundColor = UIColor(red: 1, green: 0.753, blue: 0, alpha: 1)
                
                //remove image
                self.bitmojiImage.image = #imageLiteral(resourceName: "golf_ball_blank")
                self.avatarURLToShare = nil
                
                //remove shared image from firestore
                AppSingleton.shared.db.collection("players")
                    .document(AppSingleton.shared.me.id)
                    .setData(["image": ""], merge: true)
                
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SettingsTableViewController {
            self.embeddedTableViewController = vc
            self.embeddedTableViewController.actionDelegate = self
        }
    }
}
