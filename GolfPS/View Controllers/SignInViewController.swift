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
        
        func signInAnon() {
            Auth.auth().signInAnonymously() { (authResult, error) in
                guard let user = authResult?.user else {
                    fatalError("Unable to sign in anonymously")
                }
                loadUser(user)
            }
        }
        
        func loadUser(_ user: User) {
            let me = MePlayer(id: user.uid)
            me.getUserInfo()
            AppSingleton.shared.me = me
            
            self.performSegue(withIdentifier: "FinishSignIn", sender: nil)
        }

        //remove keychain values if we have never run this app
        //if we do not do this, users will still be signed in even if they uninstalled the app
        if let user = Auth.auth().currentUser {
            if !UserDefaults.standard.bool(forKey: "hasRunBefore") {
                try? Auth.auth().signOut()
                
                signInAnon()

                // update the flag indicator
                UserDefaults.standard.set(true, forKey: "hasRunBefore")
                UserDefaults.standard.synchronize()
                
            } else {
                DispatchQueue.main.async {
                    loadUser(user)
                }
            }
        } else {
            //we have run the app before but we logged out and are restarting the app with no user logged in
            signInAnon()
        }
    }

}
