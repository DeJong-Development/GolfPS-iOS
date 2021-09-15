//
//  ButtonX.swift
//
//  Created by Greg DeJong on 10/15/18.
//  Copyright © 2018 Axon Sports. All rights reserved.
//

import UIKit

@IBDesignable class ButtonX: UIButton {
    
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    @IBInspectable var borderWidth: CGFloat = 1 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var isRounded: Bool = false {
        didSet {
            resizeView()
        }
    }
    @IBInspectable var cornerRadius: CGFloat = -1 {
        didSet {
            resizeView()
        }
    }
    
    @IBInspectable var roundTL: Bool = false {
        didSet {
            resizeView()
        }
    }
    @IBInspectable var roundTR: Bool = false {
        didSet {
            resizeView()
        }
    }
    @IBInspectable var roundBL: Bool = false {
        didSet {
            resizeView()
        }
    }
    @IBInspectable var roundBR: Bool = false {
        didSet {
            resizeView()
        }
    }
    private var cornersToRound:UIRectCorner = .allCorners
    
    @IBInspectable var glowColor: UIColor? = nil {
        didSet {
            if let gc = self.glowColor {
                self.layer.masksToBounds = false
                self.layer.shadowColor = gc.cgColor
                self.layer.shadowRadius = 5
                self.layer.shadowOpacity = 1
                self.layer.shadowOffset = .zero
            } else {
                self.layer.shadowColor = nil
                self.layer.shadowRadius = 0
                self.layer.shadowOpacity = 0
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeView()
    }
    
    private func resizeView() {
        if (isRounded) {
            if (roundTR || roundTL || roundBL || roundBR) {
                cornersToRound = UIRectCorner()
                if roundTL {
                    cornersToRound.formUnion(.topLeft)
                }
                if roundTR {
                    cornersToRound.formUnion(.topRight)
                }
                if roundBL {
                    cornersToRound.formUnion(.bottomLeft)
                }
                if roundBR {
                    cornersToRound.formUnion(.bottomRight)
                }
            }
            
            let cornerRad = (cornerRadius > 0) ? cornerRadius : frame.height / 2
            if !cornersToRound.contains(.allCorners) {
                let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: cornersToRound, cornerRadii: CGSize(width: cornerRad, height: cornerRad))
                let mask = CAShapeLayer()
                mask.path = path.cgPath
                layer.mask = mask
                layer.cornerRadius = 0
            } else {
                layer.mask = nil
                layer.cornerRadius = cornerRad
            }
        } else {
            layer.mask = nil
            layer.cornerRadius = 0
        }
    }
}
