//
//  SignInViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 4/22/24.
//  Copyright © 2024 DeJong Development. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Task {
            if let user = Auth.auth().currentUser {
                if !UserDefaults.standard.bool(forKey: "hasRunBefore") {
                    //remove keychain values if we have never run this app
                    //if we do not do this, users will still be signed in even if they uninstalled the app
                    
                    try? Auth.auth().signOut()
                    
                    // Reset user analytics properties
                    AnalyticsLogger.setDisplayMode(isDefault: true)
                    AnalyticsLogger.setUnits(isMetric: false)
                    
                    await signInAnon()
                    
                    // update the flag indicator
                    UserDefaults.standard.set(true, forKey: "hasRunBefore")
                    UserDefaults.standard.synchronize()
                    
                } else {
                    await loadUser(user)
                }
            } else {
                // user has run the app before but we logged out
                // restarting the app with no user logged in
                await signInAnon()
            }
        }
    }

    /// Sign in anonymously and load user data
    private func signInAnon() async {
        do {
            let authResult = try await Auth.auth().signInAnonymously()
            
            await loadUser(authResult.user)
        } catch {
            fatalError("Unable to sign in anonymously")
        }
    }
    
    /// Load user data and segue to main tab bar controller
    private func loadUser(_ user: User) async {
        let me = MePlayer(id: user.uid)
        await me.getUserInfo()
        
        AppSingleton.shared.me = me
        
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "FinishSignIn", sender: nil)
        }
    }
}
