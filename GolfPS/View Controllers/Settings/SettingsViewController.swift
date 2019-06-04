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
        updateButtonLabel()
    }
    
    @IBAction func clickSnapLink(_ sender: Any) {
        if (SCSDKLoginClient.isUserLoggedIn) {
            
            //change to "Unlink" after we are all logged in
            SCSDKLoginClient.unlinkCurrentSession { (success: Bool) in
                self.updateButtonLabel()
                if success {
                    let ac = UIAlertController(title: "Unlinked!", message: "Your Snapchat account has been logged out!", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
                
            }
        } else {
            //once this is linked - it will always be linked
            //set up with a "Link Snapchat Bitmoji" button or something like that
            SCSDKLoginClient.login(from: self, completion: { success, error in
                self.updateButtonLabel()
            })
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
                
                SCSDKBitmojiClient.fetchAvatarURL { (avatarURL: String?, error: Error?) in
                    if let error = error {
                        print(error.localizedDescription)
                    } else if let urlString = avatarURL, let url = URL(string: urlString) {
                        self.getData(from: url) { data, response, error in
                            guard let data = data, error == nil else { return }
                            print(response?.suggestedFilename ?? url.lastPathComponent)
                            print("Download Finished")
                            DispatchQueue.main.async() {
                                self.bitmojiImage.image = UIImage(data: data)
                            }
                        }
                    }
                }
                
            } else {
                Analytics.setUserProperty("false", forName: "snapchat")
                self.snapLink.setTitle("Link Snapchat", for: .normal)
                self.snapLink.backgroundColor = UIColor(red: 1, green: 0.753, blue: 0, alpha: 1)
                
                self.bitmojiImage.image = nil
            }
        }
//        if let forcedStatus = loggedIn {
//            if (forcedStatus) {
//                snapLink.setTitle("Disconnect Snapchat", for: .normal)
//                snapLink.backgroundColor = UIColor(red: 0.235, green: 0.698, blue: 0.886, alpha: 1)
//            } else {
//                snapLink.setTitle("Link Snapchat", for: .normal)
//                snapLink.backgroundColor = UIColor(red: 1, green: 0.753, blue: 0, alpha: 1)
//            }
//        } else
    }
    //    private func fetchSnapUserInfo(){
//        let graphQLQuery = "{me{displayName, bitmoji{avatar}}}"
//        SCSDKLoginClient
//            .fetchUserData(
//                withQuery: graphQLQuery,
//                variables: nil,
//                success: { userInfo in
//                    if let userInfo = userInfo,
//                        let data = try? JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted),
//                        let userEntity = try? JSONDecoder().decode(UserEntity.self, from: data) {
//                        DispatchQueue.main.async {
////                            self.goToLoginConfirm(userEntity)
//                        }
//                    }
//            }) { (error, isUserLoggedOut) in
//                print(error?.localizedDescription ?? "")
//        }
//    }
}
