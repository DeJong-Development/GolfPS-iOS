//
//  ImageViewX.swift
//
//  Created by Greg DeJong on 12/11/18.
//

import UIKit

@IBDesignable class ImageViewX: UIImageView {
    
    @IBInspectable var borderType: Int = 0 {
        didSet {
            verifyBorderExistence()
            if borderType > 0 {
                customViewBorder.lineDashPattern = [4, 4]
                customViewBorder.lineDashPhase = 0
            } else {
                customViewBorder.lineDashPattern = []
            }
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            verifyBorderExistence()
            customViewBorder.strokeColor = borderColor.cgColor
        }
    }
    @IBInspectable var borderWidth: CGFloat = 1 {
        didSet {
            verifyBorderExistence()
            customViewBorder.lineWidth = borderWidth
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
    private var customViewBorder = CAShapeLayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeView()
    }
    
    private func verifyBorderExistence() {
        if borderWidth > 0 {
            customViewBorder.lineWidth = borderWidth
            customViewBorder.strokeColor = borderColor.cgColor
            customViewBorder.fillColor = nil
            if let sublayers = self.layer.sublayers, sublayers.contains(customViewBorder) {
                //already has custom view border
            } else {
                self.layer.addSublayer(customViewBorder)
            }
        } else {
            self.customViewBorder.removeFromSuperlayer()
        }
    }
    
    private func resizeView() {
        self.layer.masksToBounds = true
        
        customViewBorder.frame = self.bounds
        
        let borderInset = borderWidth / 2
        
        let hasSpecifiedCorners = roundTR || roundTL || roundBL || roundBR
        if (isRounded || hasSpecifiedCorners) {
            if hasSpecifiedCorners {
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
            
            let fullCapsuleSize = min(frame.width, frame.height) / 2
            let outerCornerRad = (cornerRadius > 0) ? min(fullCapsuleSize, cornerRadius) : fullCapsuleSize
            
            //MASK
            if !cornersToRound.contains(.allCorners) { //round specified corners
                let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: cornersToRound, cornerRadii: CGSize(width: outerCornerRad, height: outerCornerRad))
                let mask = CAShapeLayer()
                mask.path = path.cgPath
                layer.mask = mask
                layer.cornerRadius = 0
            } else { //round all corners
                layer.mask = nil
                layer.cornerRadius = outerCornerRad
            }
            
            //BORDER
            if (borderWidth > 0) { // rounded with border
                let modifiedCornerRad = max(0, outerCornerRad - borderInset)
                var borderPath = UIBezierPath(rect: self.bounds.insetBy(dx: borderInset, dy: borderInset))
                if (modifiedCornerRad > 0) {
                    borderPath = UIBezierPath(roundedRect: self.bounds.insetBy(dx: borderInset, dy: borderInset), byRoundingCorners: cornersToRound, cornerRadii: CGSize(width: modifiedCornerRad, height: modifiedCornerRad))
                }
                borderPath.close()
                borderPath.lineCapStyle = .square
                borderPath.lineJoinStyle = .round
                customViewBorder.path = borderPath.cgPath
            } else { //rounded with no border
                customViewBorder.path = nil
            }
        } else { // Not rounded
            //MASK
            layer.mask = nil
            layer.cornerRadius = 0
            
            //BORDER
            if (borderWidth > 0) {
                customViewBorder.path = UIBezierPath(rect: self.bounds.insetBy(dx: borderInset, dy: borderInset)).cgPath
            } else {
                customViewBorder.path = nil
            }
        }
    }
}
