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
    private var normalTabColor: UIColor {
        return .text
    }

    private var selectedTabColor: UIColor {
        return .background
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let tabSublayers = tabBar.layer.sublayers else {
            return
        }
        
        gradient.frame = CGRect(x: CGFloat(0),
                                y: CGFloat(0),
                                width: self.tabBar.frame.size.width,
                                height: self.tabBar.frame.size.height)

        if !tabSublayers.contains(gradient) {
            gradient.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor]
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1)
            gradient.zPosition = 0
            self.tabBar.layer.addSublayer(gradient)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        GMSServices.provideAPIKey(AppSingleton.shared.valueForAPIKey(keyname: "GoogleMaps"))
        
        for tbi in self.tabBar.items! {
            tbi.image = tbi.image?.withRenderingMode(.alwaysTemplate)
            tbi.selectedImage = tbi.selectedImage?.withRenderingMode(.alwaysTemplate)
        }

        configureTabBarAppearance()
    }

    private func configureTabBarAppearance() {
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: normalTabColor], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: selectedTabColor], for: .selected)

        if #available(iOS 13.0, *) {
            self.tabBar.unselectedItemTintColor = normalTabColor

            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .grass
            let layoutAppearances = [
                appearance.stackedLayoutAppearance,
                appearance.inlineLayoutAppearance,
                appearance.compactInlineLayoutAppearance
            ]

            for layoutAppearance in layoutAppearances {
                layoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalTabColor]
                layoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedTabColor]
                layoutAppearance.normal.iconColor = normalTabColor
                layoutAppearance.selected.iconColor = selectedTabColor
            }
            self.tabBar.standardAppearance = appearance

            if #available(iOS 15.0, *) {
                self.tabBar.scrollEdgeAppearance = appearance
            }
        }
        self.tabBar.tintColor = selectedTabColor
        self.tabBar.isTranslucent = false
        self.tabBar.itemPositioning = .centered
        self.tabBar.barTintColor = .grass
    }

}
