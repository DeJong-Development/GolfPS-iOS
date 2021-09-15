//
//  UIViewX.swift
//  Instinct
//
//  Created by Greg DeJong on 12/11/18.
//  Copyright © 2018 Sports Academy. All rights reserved.
//

import UIKit

public enum ViewXGradientStyle:Int {
    case none = -1
    case horizontal = 1
    case vertical = 2
    case radial = 3
}

@IBDesignable class ViewX: UIView {
    
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
    
    @IBInspectable var hasDashedBorder: Bool = false {
        didSet {
            if hasDashedBorder {
                dashedViewBorder.lineWidth = borderWidth
                dashedViewBorder.strokeColor = borderColor.cgColor
                dashedViewBorder.lineDashPattern = [4, 4]
                dashedViewBorder.fillColor = nil
                self.layer.addSublayer(dashedViewBorder)
            } else {
                self.dashedViewBorder.removeFromSuperlayer()
            }
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            if hasDashedBorder {
                dashedViewBorder.strokeColor = borderColor.cgColor
            } else {
                layer.borderColor = borderColor.cgColor
            }
        }
    }
    @IBInspectable var borderWidth: CGFloat = 1 {
        didSet {
            if hasDashedBorder {
                dashedViewBorder.lineWidth = borderWidth
            } else {
                layer.borderWidth = borderWidth
            }
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
    
    @IBInspectable var gradientValue: Int = -1 {
        didSet {
            gradientStyle = ViewXGradientStyle(rawValue: gradientValue) ?? .none
            self.drawBackground()
        }
    }
    
    private var gradientStyle:ViewXGradientStyle = .none
    private var cornerLayer:CAShapeLayer = CAShapeLayer()
    private var dashedViewBorder = CAShapeLayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeView()
    }
    
    private func resizeView() {
        dashedViewBorder.frame = self.bounds
        
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
            dashedViewBorder.path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: cornersToRound, cornerRadii: CGSize(width: cornerRad, height: cornerRad)).cgPath
        } else {
            layer.mask = nil
            layer.cornerRadius = 0
            dashedViewBorder.path = UIBezierPath(rect: self.bounds).cgPath
        }
        
        drawBackground()
    }
    
    private func drawBackground() {
        if let bc = backgroundColor, bc != UIColor.clear {
            var defaultGradientColors = [CGColor]()
            if let sc = gradientStartColor, let ec = gradientEndColor {
                defaultGradientColors = [sc.cgColor, ec.cgColor]
            } else {
                defaultGradientColors = [bc.lighter(by: 15)!.cgColor, bc.darker(by: 15)!.cgColor]
            }
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
        } else {
            gradientLayer.colors = nil
            layer.backgroundColor = nil
            backgroundColor = nil
        }
    }
}
