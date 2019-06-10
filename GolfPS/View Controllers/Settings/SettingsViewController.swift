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

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var snapLink: UIButton!
    @IBOutlet weak var bitmojiImage: UIImageView!
    
    @IBOutlet weak var locationShareSwitch: UISwitch!
    @IBOutlet weak var bitmojiShareSwitch: UISwitch!
    
    @IBOutlet weak var bitmojiShareTitle: UILabel!
    @IBOutlet weak var bitmojiShareDescription: UILabel!
    
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
        
        locationShareSwitch.setOn(AppSingleton.shared.me.shareLocation, animated: false)
        if (!AppSingleton.shared.me.shareLocation) {
            AppSingleton.shared.db.collection("players").document(AppSingleton.shared.me.id).delete()
            AppSingleton.shared.me.location = nil
            bitmojiShareSwitch.setOn(false, animated: false)
            
            AppSingleton.shared.me.shareBitmoji = false
            self.avatarURLToShare = nil
        } else {
            bitmojiShareSwitch.setOn(AppSingleton.shared.me.shareBitmoji, animated: false)
        }
        
        if (SCSDKLoginClient.isUserLoggedIn) {
            //get bitmoji avatar
            getAvatar()
        }
        
        updateButtonLabel()
        updateBitSwitch()
    }
    
    @IBAction func clickSnapLink(_ sender: Any) {
        if (SCSDKLoginClient.isUserLoggedIn) {
            self.bitmojiShareSwitch.setOn(false, animated: true)
            AppSingleton.shared.me.shareBitmoji = false
            self.avatarURLToShare = nil
            
            //change to "Unlink" after we are all logged in
            SCSDKLoginClient.unlinkAllSessions { (success: Bool) in
                DispatchQueue.main.async() {
                    self.updateButtonLabel()
                    self.updateBitSwitch()
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
                    self.updateBitSwitch()
                }
                
                self.getAvatar()
            })
        }
    }
    
    @IBAction func switchMapShare(_ sender: UISwitch) {
        //update in app preferences
        AppSingleton.shared.me.shareLocation = sender.isOn
        updateBitSwitch()
        
        if (!AppSingleton.shared.me.shareLocation) {
            AppSingleton.shared.db.collection("players").document(AppSingleton.shared.me.id).delete()
            AppSingleton.shared.me.location = nil
            
            self.bitmojiShareSwitch.setOn(false, animated: true)
            AppSingleton.shared.me.shareBitmoji = false
            self.avatarURLToShare = nil
        }
    }
    @IBAction func switchBitmojiShare(_ sender: UISwitch) {
        //update in app preferences
        AppSingleton.shared.me.shareBitmoji = sender.isOn
        
        if (sender.isOn) {
            //get up to date bitmoji avatar url
            getAvatar(replaceImage: false)
        } else {
            self.avatarURLToShare = nil
            AppSingleton.shared.db.collection("players")
                .document(AppSingleton.shared.me.id)
                .setData(["image": ""], merge: true)
        }
    }
    
    private func updateBitSwitch() {
        if (AppSingleton.shared.me.shareLocation && SCSDKLoginClient.isUserLoggedIn) {
            bitmojiShareSwitch.isEnabled = true
            bitmojiShareTitle.alpha = 1
            bitmojiShareDescription.alpha = 1
        } else {
            bitmojiShareSwitch.isEnabled = false
            bitmojiShareTitle.alpha = 0.5
            bitmojiShareDescription.alpha = 0.5
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
    
    private func getAvatar(replaceImage:Bool = true) {
        //get bitmoji avatar
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
}
