//
//  ViewX.swift
//
//  Created by Greg DeJong on 12/11/18.
//

import UIKit

public enum ViewXGradientStyle:Int {
    case none = -1
    case horizontal = 1
    case vertical = 2
    case radial = 3
}

@IBDesignable class ViewX: UIControl {
    
    override public class var layerClass: Swift.AnyClass {
        return CAGradientLayer.self
    }
    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
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
    
    @IBInspectable var hasBorder: Bool = true {
        didSet {
            verifyBorderExistence()
        }
    }
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
    @IBInspectable var glowColor: UIColor? = nil {
        didSet {
            if (hasGlow && self.glowColor != nil) {
                self.layer.shadowColor = self.glowColor!.cgColor
            } else {
                self.layer.shadowColor = nil
            }
        }
    }
    @IBInspectable var hasGlow: Bool = false {
        didSet {
            if (hasGlow && self.glowColor != nil) {
                self.layer.masksToBounds = false
                self.layer.shadowColor = self.glowColor!.cgColor
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
    
    @IBInspectable var gradientStartColor: UIColor? {
        didSet {
            self.drawBackground()
        }
    }
    @IBInspectable var gradientEndColor: UIColor? {
        didSet {
            self.drawBackground()
        }
    }
    /**
     - none = -1
     - horizontal = 1
     - vertical = 2
     - radial = 3
     */
    @IBInspectable var gradientValue: Int = -1 {
        didSet {
            gradientStyle = ViewXGradientStyle(rawValue: gradientValue) ?? .none
            self.drawBackground()
        }
    }
    
    private var gradientStyle:ViewXGradientStyle = .none
    private var cornerLayer:CAShapeLayer = CAShapeLayer()
    private var customViewBorder = CAShapeLayer()
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if hasBorder {
            customViewBorder.strokeColor = borderColor.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeView()
    }
    
    private func verifyBorderExistence() {
        if hasBorder {
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
            let cornerRad = (cornerRadius > 0) ? min(fullCapsuleSize, cornerRadius) : fullCapsuleSize
            
            //MASK
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
            
            //BORDER
            if (borderWidth > 0) {
                //Rounded with border
                let modifiedCornerRad = max(0, cornerRad - borderInset)
                var borderPath = UIBezierPath(rect: self.bounds.insetBy(dx: borderInset, dy: borderInset))
                if modifiedCornerRad > 0 {
                    borderPath = UIBezierPath(roundedRect: self.bounds.insetBy(dx: borderInset, dy: borderInset), byRoundingCorners: cornersToRound, cornerRadii: CGSize(width: modifiedCornerRad, height: modifiedCornerRad))
                }
                borderPath.close()
                borderPath.lineCapStyle = .square
                borderPath.lineJoinStyle = .round
                customViewBorder.path = borderPath.cgPath
            } else {
                //Rounded no border
                customViewBorder.path = nil
            }
        } else { //Not rounded
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
        
        if hasBorder {
            customViewBorder.strokeColor = borderColor.cgColor
        }
        
        drawBackground()
    }
    
    private func drawBackground() {
        if let bc = backgroundColor, bc != UIColor.clear {
            let defaultGradientColors = [bc.lighter(by: 15)!.cgColor, bc.darker(by: 15)!.cgColor]
            switch gradientStyle {
                case .horizontal:
                    gradientLayer.type = .axial
                    gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
                    gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
                    gradientLayer.colors = defaultGradientColors
                case .vertical:
                    gradientLayer.type = .axial
                    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
                    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
                    gradientLayer.colors = defaultGradientColors
                case .radial:
                    gradientLayer.type = .radial
                    gradientLayer.locations = [0, 1]
                    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
                    gradientLayer.endPoint = CGPoint(x: 1.5, y: 1.5)
                    gradientLayer.colors = defaultGradientColors
                case .none:
                    gradientLayer.colors = nil
                    backgroundColor = bc
            }
        } else if let sc = gradientStartColor, let ec = gradientEndColor {
            let defaultGradientColors = [sc.cgColor, ec.cgColor]
            switch gradientStyle {
                case .horizontal:
                    gradientLayer.type = .axial
                    gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
                    gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
                    gradientLayer.colors = defaultGradientColors
                case .vertical:
                    gradientLayer.type = .axial
                    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
                    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
                    gradientLayer.colors = defaultGradientColors
                case .radial:
                    gradientLayer.type = .radial
                    gradientLayer.locations = [0, 1]
                    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
                    gradientLayer.endPoint = CGPoint(x: 1, y: 1)
                    gradientLayer.colors = defaultGradientColors
                case .none:
                    gradientLayer.colors = nil
            }
        } else {
            gradientLayer.colors = nil
            layer.backgroundColor = nil
        }
    }
}
