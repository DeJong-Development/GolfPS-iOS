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
    @IBInspectable var cornerRadius: CGFloat = -1
    @IBInspectable var hasShadow: Bool = false
    @IBInspectable var isFaded: Bool = false
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 1
    
    var maskLayer = CAGradientLayer()
    
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
        self.imageView?.contentMode = .scaleAspectFit
        
        if (isFaded) {
            maskLayer.shadowRadius = 3
            maskLayer.shadowOpacity = 1
            maskLayer.shadowOffset = CGSize.zero
            maskLayer.shadowColor = self.backgroundColor?.cgColor ?? UIColor.white.cgColor
            self.layer.mask = maskLayer
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        if (isRounded) {
            layer.cornerRadius = (cornerRadius > 0) ? cornerRadius : frame.height / 2
            layer.masksToBounds = true
        }
        if (isFaded) {
            maskLayer.frame = self.bounds
            if ((isRounded && cornerRadius > 0) || !isRounded) {
                maskLayer.shadowPath = CGPath(roundedRect: self.bounds.insetBy(dx: 5, dy: 5), cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            } else {
                maskLayer.shadowPath = CGPath(ellipseIn: self.bounds, transform: nil)
            }
        }
    }
}
