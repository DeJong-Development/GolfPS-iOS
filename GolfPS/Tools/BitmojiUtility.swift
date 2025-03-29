//
//  BitmojiUtility.swift
//  GolfPS
//
//  Created by Greg DeJong on 3/29/25.
//  Copyright © 2025 DeJong Development. All rights reserved.
//

import UIKit
import SCSDKLoginKit

struct BitmojiUtility {
    
    /**
     Gets bitmoji avatar url from Snapchat and updates value stored in firestore.
     This ensures we always have the most up to date bitmoji from the user.
     */
    static func downloadBitmojiImage(completion: @escaping (_ bitmojiUrl: URL?, _ bitmojiImage: UIImage?) -> ()) {
        self.getBitmojiURL { url in
            guard let bitmojiURL = url else {
                completion(nil, nil)
                return
            }
            self.getData(from: bitmojiURL) { data, response, error in
                guard let imageData = data, error == nil else {
                    completion(bitmojiURL, nil)
                    return
                }
                
                let bitmojiImage = UIImage(data: imageData)
                
                // Send bitmoji back to function caller
                completion(url, bitmojiImage)
            }
        }
    }
    
    /**
     Gets bitmoji avatar url from Snapchat and updates value stored in firestore.
     This ensures we always have the most up to date bitmoji from the user.
     */
    static func getBitmojiURL(completion: @escaping (URL?) -> ()) {
        self.getUserDataFromSnapchat { userData in
            guard let urlString = userData.bitmojiTwoDAvatarUrl, let url = URL(string: urlString) else {
                DebugLogger.report(error: nil, message: "Unable to process Bitmoji avatar URL")
                completion(nil)
                return
            }
            
            if (AppSingleton.shared.me.shareBitmoji) {
                //if user has elected to share bitmoji on the map - put url in firestore
                AppSingleton.shared.db.collection("players")
                    .document(AppSingleton.shared.me.id)
                    .setData(["image": url.absoluteString], merge: true)
            }
            
            completion(url)
        }
    }
    
    private static func getUserDataFromSnapchat(completion: @escaping (SCSDKUserData) -> ()) {
        let builder = SCSDKUserDataQueryBuilder().withBitmojiTwoDAvatarUrl()
        let userDataQuery = builder.build()
        
        SCSDKLoginClient.fetchUserData(with: userDataQuery) { data, error in
            guard let userData = data else {
                DebugLogger.report(error: error, message: "Unable to retrieve snapchat user data")
                return
            }
            
            completion(userData)
        } failure: { error, isUserLoggedOut in
            DebugLogger.report(error: error, message: "Failed to retrieve snapchat user data")
        }
    }
    
    private static func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
}
