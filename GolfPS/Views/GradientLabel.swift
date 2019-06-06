//
//  GradientLabel.swift
//  Cognition
//
//  Created by Greg DeJong on 12/6/18.
//  Copyright © 2018 Axon Sports. All rights reserved.
//

import UIKit

@IBDesignable
class GradientLabel: UIView {
    
    @IBInspectable var size:CGFloat = 100 {
        didSet {
            setupView()
        }
    }
    @IBInspectable var title:String? = "SIMPLE-TEST" {
        didSet {
            setupView()
        }
    }
    private var attributedTitle: NSAttributedString {
        let font:UIFont = UIFont(name: "NTF-Grand-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
        let placeholderAttrs:[NSAttributedString.Key : Any] = [NSAttributedString.Key.font : font]
        return NSAttributedString(string: title ?? "", attributes: placeholderAttrs)
    }
    
    private var label:UILabel = UILabel(frame: .zero)
    private var gradient: CAGradientLayer = CAGradientLayer()
    
    @IBInspectable var startColor: UIColor = UIColor.clear
    @IBInspectable var endColor: UIColor = UIColor.clear
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = self.bounds
        label.frame = self.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    private func setupView() {
        gradient.frame = self.bounds
        gradient.removeFromSuperlayer()
        layer.addSublayer(gradient)
        
        self.mask = nil
        label.removeFromSuperview()
        label.frame = self.bounds
        label.attributedText = attributedTitle
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        
        self.mask = label
        
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        gradient.frame = self.bounds
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
    }
}
