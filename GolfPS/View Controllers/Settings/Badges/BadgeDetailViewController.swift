//
//  BadgeDetailViewController.swift
//  RISE
//
//  Created by Greg DeJong on 10/22/19.
//  Copyright © 2019 Sports Academy. All rights reserved.
//

import UIKit

class BadgeDetailViewController: UIViewController {

    @IBOutlet weak var badgeTitle: UILabel!
    @IBOutlet weak var badgeDescription: UILabel!
    
    @IBOutlet weak var badgeIcon: UIImageView!
    @IBOutlet weak var badgeBackground: UIImageView!
    
    @IBOutlet weak var badgePercentageButton: ButtonX!
    
    var badge:Badge!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        badgeTitle.text = badge.title.uppercased()
        badgeDescription.text = badge.description
        badgePercentageButton.setTitle("\(badge.progress.rounded())%", for: .normal)
        
        if badge.isUnlocked {
            badgeBackground?.image = badge.background
            badgeIcon?.image = badge.icon
            badgeBackground?.alpha = 1
        } else {
            badgeIcon?.image = nil
            badgeBackground?.image = #imageLiteral(resourceName: "golf_ball_blank")
            badgeBackground?.alpha = 0.5
        }
    }
    
    @IBAction func clickClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
