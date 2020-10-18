//
//  ButtonX.swift
//  Instinct
//
//  Created by Greg DeJong on 10/15/18.
//  Copyright © 2018 Axon Sports. All rights reserved.
//

import UIKit

@IBDesignable
class ButtonX: UIButton {
    
    @IBInspectable var isRounded: Bool = false
    @IBInspectable var isMasked: Bool = false
    @IBInspectable var cornerRadius: CGFloat = -1
    @IBInspectable var hasShadow: Bool = false
    @IBInspectable var isFaded: Bool = false
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
           layer.borderColor = borderColor.cgColor
        }
    }
    @IBInspectable var borderWidth: CGFloat = 1
    @IBInspectable var glowColor: UIColor? = nil
    @IBInspectable var hasGlow: Bool = false
    @IBInspectable var layerBackgroundColor: UIColor? {
        didSet {
           layer.backgroundColor = layerBackgroundColor?.cgColor
        }
    }
    
    //needs to be var so it can be deallocated
    var maskLayer = CAGradientLayer()
    var cornersToRound:UIRectCorner = .allCorners
    
    override var frame: CGRect {
        didSet {
            self.setNeedsDisplay()
        }
    }
    override var bounds: CGRect {
        didSet {
            self.setNeedsDisplay()
        }
    }
    override var buttonType: UIButton.ButtonType {
        return .custom
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
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        setupView()
//    }
    
    internal func setupView() {
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        layer.backgroundColor = layerBackgroundColor?.cgColor
        
        if (isFaded) {
            maskLayer.shadowRadius = 3
            maskLayer.shadowOpacity = 1
            maskLayer.shadowOffset = CGSize.zero
            maskLayer.shadowColor = self.backgroundColor?.cgColor ?? UIColor.white.cgColor
            self.layer.mask = maskLayer
        }
        
        if (hasGlow && self.glowColor != nil) {
            self.layer.masksToBounds = false
            self.layer.shadowColor = self.glowColor!.cgColor
            self.layer.shadowRadius = 5
            self.layer.shadowOpacity = 1
            self.layer.shadowOffset = .zero
        }
        
        if (isRounded) {
            let cornerRad = (cornerRadius > 0) ? cornerRadius : frame.height / 2
            if !cornersToRound.contains(.allCorners) {
                let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: cornersToRound, cornerRadii: CGSize(width: cornerRad, height: cornerRad))
                let mask = CAShapeLayer()
                mask.path = path.cgPath
                layer.mask = mask
            } else {
                if isMasked {
                    layer.masksToBounds = true
                }
                layer.cornerRadius = cornerRad
            }
        }
    }
    
}
