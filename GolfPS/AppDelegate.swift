//
//  AppDelegate.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/19/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import Firebase
import SCSDKLoginKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIApplication.shared.windows.first
        
        FirebaseApp.configure()
        
        #if DEBUG
        guard !CommandLine.arguments.contains("testing") && !AppSingleton.shared.testing else {
            AppSingleton.shared.testing = true
            
            Firestore.firestore().useEmulator(withHost: "localhost", port: 8080)
            
            let settings = Firestore.firestore().settings
            settings.host = "localhost:8080"
            // Use memory-only cache
            settings.cacheSettings = MemoryCacheSettings(garbageCollectorSettings: MemoryLRUGCSettings())
            settings.isSSLEnabled = false
            Firestore.firestore().settings = settings
            
            Auth.auth().useEmulator(withHost:"localhost", port: 9099)
            Auth.auth().settings!.isAppVerificationDisabledForTesting = CommandLine.arguments.contains("mfa")
            
            try? Auth.auth().signOut()
            AppSingleton.shared.me = MePlayer(id: "offline")
            AppSingleton.shared.db = Firestore.firestore()
            
            return true
        }
        #endif
        
        AppSingleton.shared.me = MePlayer(id: "offline")
        AppSingleton.shared.db = Firestore.firestore()
        
        #if targetEnvironment(simulator) || DEBUG
            for family in UIFont.familyNames {
                //print all fonts
                print("\(family)")

                for name in UIFont.fontNames(forFamilyName: family) {
                    print("   \(name)")
                }
            }

            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #else
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
        
        if CommandLine.arguments.contains("NoAnimations") {
            UIView.setAnimationsEnabled(false)
        }
        
        return true
    }
    
    func isRunningLive() -> Bool {
        #if targetEnvironment(simulator)
            return false
        #else
            let isRunningTestFlightBeta  = (Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt")
            let hasEmbeddedMobileProvision = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil
            if (isRunningTestFlightBeta || hasEmbeddedMobileProvision) {
                return false
            } else {
                return true
            }
        #endif
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        WCSession.default.sendMessage(["course": ""], replyHandler: nil) { (error) in
            DebugLogger.report(error: error, message: "Unable to reset course on watch when app terminates.")
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return SCSDKLoginClient.application(app, open: url, options: options)
    }

}

