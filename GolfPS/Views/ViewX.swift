//
//  UIViewX.swift
//  Instinct
//
//  Created by Greg DeJong on 12/11/18.
//  Copyright © 2018 Sports Academy. All rights reserved.
//

import UIKit

class ViewX: UIView {
    
    @IBInspectable var isRounded: Bool = false
    @IBInspectable var cornerRadius: CGFloat = -1
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 1
    
    var cornersToRound:UIRectCorner = .allCorners
    
    override var frame: CGRect {
        didSet {
            setupView()
        }
    }
    override var bounds: CGRect {
        didSet {
            setupView()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    internal func setupView() {
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        
        if (isRounded) {
            layer.masksToBounds = true
            
            let cornerRad = (cornerRadius > 0) ? cornerRadius : frame.height / 2
            if !cornersToRound.contains(.allCorners) {
                let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: cornersToRound, cornerRadii: CGSize(width: cornerRad, height: cornerRad))
                let mask = CAShapeLayer()
                mask.path = path.cgPath
                layer.mask = mask
            } else {
                layer.cornerRadius = cornerRad
            }
        }
    }
}
