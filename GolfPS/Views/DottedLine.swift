//
//  DottedLine.swift
//  Instinct
//
//  Created by Greg DeJong on 12/10/18.
//  Copyright © 2018 Sports Academy. All rights reserved.
//

import UIKit

@IBDesignable
class DottedLine:UIView {
    
    fileprivate var dotLineLayer:CAShapeLayer = CAShapeLayer()
    
    @IBInspectable var dotColor:UIColor = UIColor.red {
        didSet {
            setupView()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setupView()
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
        //add dotted lines to lock button
        self.dotLineLayer.removeFromSuperlayer()
        
        let shapeRect = self.bounds
        dotLineLayer.bounds = shapeRect
        dotLineLayer.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        dotLineLayer.strokeColor = dotColor.cgColor
        dotLineLayer.lineJoin = .round
        dotLineLayer.lineCap = .round
        dotLineLayer.lineDashPattern = [0.0001, 10]
        dotLineLayer.lineWidth = 3
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: self.bounds.midY))
        path.addLine(to: CGPoint(x: self.bounds.maxX, y: self.bounds.midY))
        dotLineLayer.path = path.cgPath
        self.layer.addSublayer(dotLineLayer)
    }
}
