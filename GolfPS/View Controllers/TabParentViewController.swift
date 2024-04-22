//
//  TabParentViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 5/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleMaps

class TabParentViewController: UITabBarController {
    
    private let gradient: CAGradientLayer = CAGradientLayer()

    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let tabSublayers = tabBar.layer.sublayers {
            gradient.frame = CGRect(x: CGFloat(0),
                                    y: CGFloat(0),
                                    width: self.tabBar.frame.size.width,
                                    height: self.tabBar.frame.size.height)

            if (!tabSublayers.contains(gradient)) {
                gradient.colors = [UIColor.init(white: 1, alpha: 0.2).cgColor, UIColor.init(white: 0, alpha: 0.2).cgColor]
                gradient.startPoint = CGPoint(x: 0.5, y: 0)
                gradient.endPoint = CGPoint(x: 0.5, y: 1)
                gradient.zPosition = 0
                self.tabBar.layer.addSublayer(gradient)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GMSServices.provideAPIKey(AppSingleton.shared.valueForAPIKey(keyname: "GoogleMaps"))
        
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
        
        for tbi in self.tabBar.items! {
            tbi.image = tbi.image?.withRenderingMode(.alwaysOriginal)
            tbi.selectedImage = tbi.selectedImage?.withRenderingMode(.alwaysOriginal)
        }
        
        if #available(iOS 13.0, *) {
            self.tabBar.unselectedItemTintColor = UIColor.black
        }
        self.tabBar.tintColor = .grass
        self.tabBar.isTranslucent = false
        self.tabBar.itemPositioning = .centered
        self.tabBar.barTintColor = .grass
    }

}
