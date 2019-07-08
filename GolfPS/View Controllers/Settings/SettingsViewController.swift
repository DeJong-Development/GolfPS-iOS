//
//  SettingsViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 7/26/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import SCSDKLoginKit
import SCSDKBitmojiKit

extension SettingsViewController: SettingsActionDelegate {
    func removeAvatar() {
        self.avatarURLToShare = nil
    }
    func updateAvatar() {
        getAvatar(replaceImage: false)
    }
}

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var snapLink: UIButton!
    @IBOutlet weak var bitmojiImage: UIImageView!
    
    var embeddedTableViewController: SettingsTableViewController!
    
    var avatarURLToShare:URL? = nil {
        didSet {
            if (AppSingleton.shared.me.shareBitmoji && avatarURLToShare != nil) {
                AppSingleton.shared.db.collection("players")
                    .document(AppSingleton.shared.me.id)
                    .setData(["image": avatarURLToShare!.absoluteString], merge: true)
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bitmojiImage.contentMode = .scaleAspectFit
        snapLink.layer.cornerRadius = 8
        
        if (!AppSingleton.shared.me.shareLocation) {
            self.avatarURLToShare = nil
        }
        
        if (SCSDKLoginClient.isUserLoggedIn) {
            //get bitmoji avatar
            getAvatar()
        }
        
        updateButtonLabel()
    }
    
    @IBAction func clickSnapLink(_ sender: Any) {
        if (SCSDKLoginClient.isUserLoggedIn) {
            self.embeddedTableViewController.bitmojiShareSwitch.setOn(false, animated: true)
            AppSingleton.shared.me.shareBitmoji = false
            self.avatarURLToShare = nil
            
            //change to "Unlink" after we are all logged in
            SCSDKLoginClient.unlinkAllSessions { (success: Bool) in
                DispatchQueue.main.async() {
                    self.updateButtonLabel()
                    self.embeddedTableViewController.updateBitSwitch()
                }
                if success {
                    DispatchQueue.main.async {
                        let ac = UIAlertController(title: "Unlinked!", message: "Your Snapchat account has been logged out!", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        } else {
            //once this is linked - it will always be linked
            //set up with a "Link Snapchat Bitmoji" button or something like that
            SCSDKLoginClient.login(from: self, completion: { success, error in
                DispatchQueue.main.async() {
                    self.updateButtonLabel()
                    self.embeddedTableViewController.updateBitSwitch()
                }
                
                self.getAvatar()
            })
        }
    }
    
    @IBAction func clickPrivacy(_ sender: UIButton) {
        Analytics.logEvent("click_privacy_settings", parameters: nil)
        
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
        Analytics.logEvent("click_terms_settings", parameters: nil)
        
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
    
    private func updateButtonLabel(loggedIn:Bool? = nil) {
        DispatchQueue.main.async {
            if (SCSDKLoginClient.isUserLoggedIn) {
                Analytics.setUserProperty("true", forName: "snapchat")
                
                self.snapLink.setTitle("Disconnect Snapchat", for: .normal)
                self.snapLink.backgroundColor = UIColor(red: 0.235, green: 0.698, blue: 0.886, alpha: 1)
                
            } else {
                Analytics.setUserProperty("false", forName: "snapchat")
                self.snapLink.setTitle("Link Snapchat", for: .normal)
                self.snapLink.backgroundColor = UIColor(red: 1, green: 0.753, blue: 0, alpha: 1)
                
                self.bitmojiImage.image = nil
                self.avatarURLToShare = nil
                AppSingleton.shared.db.collection("players")
                    .document(AppSingleton.shared.me.id)
                    .setData(["image": ""], merge: true)
                
            }
        }
    }
    
    //get bitmoji avatar
    private func getAvatar(replaceImage:Bool = true) {
        SCSDKBitmojiClient.fetchAvatarURL { (avatarURL: String?, error: Error?) in
            if let error = error {
                print(error.localizedDescription)
            } else if let urlString = avatarURL, let url = URL(string: urlString) {
                self.avatarURLToShare = url;
                if (AppSingleton.shared.me.shareBitmoji) {
                    AppSingleton.shared.db.collection("players")
                        .document(AppSingleton.shared.me.id)
                        .setData(["image": url.absoluteString], merge: true)
                }
                if (replaceImage) {
                    self.getData(from: url) { data, response, error in
                        guard let data = data, error == nil else { return }
                        DispatchQueue.main.async() {
                            self.bitmojiImage.image = UIImage(data: data)
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SettingsTableViewController {
            self.embeddedTableViewController = vc
            self.embeddedTableViewController.actionDelegate = self;
        }
    }
}
