//
//  GradientButton.swift
//  Instinct
//
//  Created by Greg DeJong on 3/10/18.
//  Copyright © 2018 AxonSports. All rights reserved.
//

import UIKit

@IBDesignable
class GradientButton: UIButton {

    override public class var layerClass: Swift.AnyClass {
        return CAGradientLayer.self
    }
    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    @IBInspectable var startColor: UIColor = UIColor(white: 1, alpha: 0.2)
    @IBInspectable var endColor: UIColor = UIColor(white: 0, alpha: 0.2)
    
    @IBInspectable var isWavy: Bool = false
    @IBInspectable var isRounded: Bool = false
    @IBInspectable var cornerRadius: CGFloat = -1
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 1
    
    override var backgroundColor: UIColor? {
        didSet {
            setupView()
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
        
        if let bc = backgroundColor {
            if (bc != UIColor.clear) {
                if (isWavy) {
                    gradientLayer.locations = [0.1, 0.2, 0.4, 0.6, 0.8, 1]
                    gradientLayer.colors = [bc.lighter()!.cgColor, bc.darker()!.cgColor, bc.lighter()!.cgColor, bc.darker()!.cgColor, bc.lighter()!.cgColor, bc.darker()!.cgColor]
                    gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                    gradientLayer.endPoint = CGPoint(x: 1, y: 1)
                } else {
                    gradientLayer.colors = [bc.lighter()!.cgColor, bc.darker()!.cgColor]
                }
                backgroundColor = UIColor.clear
            }
        } else {
            if (isWavy) {
                gradientLayer.locations = [0.1, 0.2, 0.4, 0.6, 0.8, 1]
                gradientLayer.colors = [startColor.cgColor, endColor.cgColor, startColor.cgColor, endColor.cgColor, startColor.cgColor, endColor.cgColor]
                gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            } else {
                gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            }
        }
        
        self.setNeedsDisplay()
    }
}
