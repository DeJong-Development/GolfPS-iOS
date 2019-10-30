//
//  BadgeBlockCollectionViewCell.swift
//  RISE
//
//  Created by Greg DeJong on 10/18/19.
//  Copyright © 2019 Sports Academy. All rights reserved.
//

import UIKit

class BadgeBlockCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var badgeBackground: UIImageView!
    @IBOutlet weak var badgeImage: UIImageView!
    @IBOutlet weak var badgeTitle: UILabel!
    
    var badge:Badge! {
        didSet {
            update()
        }
    }
    
    func update() {
        badgeTitle?.text = badge.title
        
        if badge.isUnlocked {
            badgeBackground?.image = badge.background
            badgeImage?.image = badge.icon
            badgeBackground?.alpha = 1
        } else {
            badgeImage?.image = nil
            badgeBackground?.image = #imageLiteral(resourceName: "golf_ball_blank")
            badgeBackground?.alpha = 0.5
        }
    }
}
