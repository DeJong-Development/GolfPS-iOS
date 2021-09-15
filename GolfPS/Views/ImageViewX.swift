//
//  ImageViewX.swift
//
//  Created by Greg DeJong on 12/11/18.
//  Copyright © 2018 Sports Academy. All rights reserved.
//

import UIKit

@IBDesignable class ImageViewX: UIImageView {
    
    @IBInspectable var flagColor: UIColor = UIColor.gold {
        didSet {
            self.cornerLayer.fillColor = flagColor.cgColor.copy(alpha: 0.75)
        }
    }
    @IBInspectable var hasCornerFlag: Bool = false {
        didSet {
            if hasCornerFlag {
                self.cornerLayer.path = getCornerPath().cgPath
                self.layer.insertSublayer(cornerLayer, at: 0)
            } else {
                self.cornerLayer.removeFromSuperlayer()
            }
        }
    }
    @IBInspectable var borderWidth: CGFloat = 1 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            layer.borderColor = borderColor.cgColor
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
    
    private var cornerLayer:CAShapeLayer = CAShapeLayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeView()
    }
    
    private func resizeView() {
        self.layer.masksToBounds = true
        
        if (hasCornerFlag) {
            self.cornerLayer.path = getCornerPath().cgPath
        }
        
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
    
    private func getCornerPath() -> UIBezierPath {
        let cornerSize:CGFloat = 75
        let cornerPath:UIBezierPath = UIBezierPath()
        cornerPath.move(to: CGPoint(x: self.bounds.width - cornerSize, y: self.bounds.height))
        cornerPath.addLine(to: CGPoint(x: self.bounds.width, y: self.bounds.height))
        cornerPath.addLine(to: CGPoint(x: self.bounds.width, y: self.bounds.height - cornerSize))
        cornerPath.close()
        
        return cornerPath
    }
}
