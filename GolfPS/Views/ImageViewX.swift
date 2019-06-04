//
//  ImageViewX.swift
//  Instinct
//
//  Created by Greg DeJong on 12/11/18.
//  Copyright © 2018 Sports Academy. All rights reserved.
//

import UIKit

@IBDesignable
class ImageViewX: UIImageView {
    
    @IBInspectable var isRounded: Bool = false {
        didSet {
            setupView()
        }
    }
    @IBInspectable var cornerRadius: CGFloat = -1
    
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
    override init(image: UIImage?) {
        super.init(image: image)
        setupView()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    internal func setupView() {
        if (isRounded) {
            layer.cornerRadius = (cornerRadius > 0) ? cornerRadius : frame.height / 2
        }
        layer.masksToBounds = isRounded
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if (isRounded) {
            layer.cornerRadius = (cornerRadius > 0) ? cornerRadius : frame.height / 2
        }
        layer.masksToBounds = isRounded
    }
}
