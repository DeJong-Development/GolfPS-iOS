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
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
           layer.borderColor = borderColor.cgColor
        }
    }
    @IBInspectable var borderWidth: CGFloat = 1
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        redraw()
    }
    
    internal func setupView() {
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        layer.masksToBounds = true
        layer.mask = nil
        
        redraw()
    }
    
    private func redraw() {
        if (isRounded) {
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
