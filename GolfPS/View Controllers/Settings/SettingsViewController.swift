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
        //Do not need to force update the avatar image
        getAvatar(replaceImage: false)
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
            getAvatar()
        }
        
        updateButtonLabel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bitmojiImage.contentMode = .scaleAspectFit
        snapLink.layer.cornerRadius = 8
        
        if (!AppSingleton.shared.me.shareLocation) {
            self.avatarURLToShare = nil
        }
    }
    
    @IBAction func clickSnapLink(_ sender: Any) {
        AnalyticsLogger.log(name: "click_snap_link")
        
        if (SCSDKLoginClient.isUserLoggedIn) {
            self.embeddedTableViewController.bitmojiShareSwitch.setOn(false, animated: true)
            AppSingleton.shared.me.shareBitmoji = false
            self.avatarURLToShare = nil
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
                
                self.getAvatar()
            })
        }
    }
    
    @IBAction func clickBuyMeADrink(_ sender: Any) {
    }
    
    @IBAction func clickPrivacy(_ sender: UIButton) {
        AnalyticsLogger.log(name: "click_privacy_settings")
        
        if let privacyURL:URL = URL(string: "https://golfps-dejongdevelopment.firebaseapp.com/privacy_policy.html") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(privacyURL, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(privacyURL)
            }
        }
    }
    @IBAction func clickTerms(_ sender: UIButton) {
        AnalyticsLogger.log(name: "click_terms_settings")
        
        if let termsURL:URL = URL(string: "https://golfps-dejongdevelopment.firebaseapp.com/terms_and_conditions.html") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(termsURL, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(termsURL)
            }
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
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
    
    /**
     Gets bitmoji avatar url from Snapchat and updates value stored in firestore.
     This ensures we always have the most up to date bitmoji from the user.
     - Parameter replaceImage: If true, the image will be replaced with the most up to date image from the Snapchat bitmoji url
     */
    private func getAvatar(replaceImage:Bool = true) {
        let builder = SCSDKUserDataQueryBuilder().withBitmojiTwoDAvatarUrl()
        let userDataQuery = builder.build()
        
        SCSDKLoginClient.fetchUserData(with: userDataQuery) { userData, error in
            let displayName = userData?.displayName ?? "Unknown User"
            
            if let partialError = error {
                DebugLogger.report(error: partialError, message: "Unable to retrieve Bitmoji")
            }
            
            if let urlString = userData?.bitmojiTwoDAvatarUrl, let url = URL(string: urlString) {
                self.avatarURLToShare = url;
                if (AppSingleton.shared.me.shareBitmoji) {
                    //if user has elected to share bitmoji on the map - put url in firestore
                    AppSingleton.shared.db.collection("players")
                        .document(AppSingleton.shared.me.id)
                        .setData(["image": url.absoluteString], merge: true)
                }
                if (replaceImage) {
                    //get the image data and display in the UIImage
                    self.getData(from: url) { data, response, error in
                        guard let data = data, error == nil else { return }
                        DispatchQueue.main.async {
                            self.bitmojiImage.image = UIImage(data: data)
                        }
                    }
                }
            }
        } failure: { error, isUserLoggedOut in
            DebugLogger.report(error: error, message: "Unable to retrieve Bitmoji")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SettingsTableViewController {
            self.embeddedTableViewController = vc
            self.embeddedTableViewController.actionDelegate = self
        }
    }
}
