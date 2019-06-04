//
//  TextFieldX.swift
//  Cognition
//
//  Created by Greg DeJong on 10/15/18.
//  Copyright © 2018 Axon Sports. All rights reserved.
//

import UIKit

enum TextFieldInputType: String {
    case email = "email"
    case name = "name"
    case password = "password"
}

@IBDesignable
class TextFieldX: UITextField {
    
    
    @IBInspectable var hasBottomBorder: Bool = true
    @IBInspectable var hasBorder: Bool = false
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var borderWidth: CGFloat = 1
    
    @IBInspectable var placeholderText: String? = "TEST"
    @IBInspectable var placeholderColor: UIColor = UIColor.white
    @IBInspectable var placeholderSize: CGFloat = 14
    
    var attributedHint: NSAttributedString {
        let font:UIFont = UIFont.systemFont(ofSize: placeholderSize)
        let placeholderAttrs:[NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor : placeholderColor, NSAttributedString.Key.font : font]
        return NSAttributedString(string: placeholderText ?? "", attributes: placeholderAttrs)
    }
    
    let acceptImage:UIImage = #imageLiteral(resourceName: "check-gold")
    let invalidImage:UIImage = #imageLiteral(resourceName: "x-red-2")
    var acceptStateImageView: UIImageView?
    
    var customPlaceholderView: UILabel?
    var phCenterYConstraint:NSLayoutConstraint!
    var phBottomConstraint:NSLayoutConstraint!
    
    var inputType: TextFieldInputType = .email
    
    public func toggleVisibility(isVisible:Bool, forceCorrectState:Bool? = nil, correctOnly:Bool = false) {
        var displayImage:UIImage? = nil
        if (isVisible) {
            if let fcs:Bool = forceCorrectState {
                acceptStateImageView?.image = (fcs) ? acceptImage : invalidImage
            } else {
                let inputValue:String = self.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                var pattern:String = "^[a-zA-Z0-9]{3,}$"
                switch inputType {
                case .email:
                    pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                case .password:
                    pattern = "^(?=.*[0-9a-zA-Z]).{6,64}$"
//                    pattern = "^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{5,}$"
                case .name:
                    pattern = "^[a-zA-Z' -]{3,}$"
                }
                
                let regex = try! NSRegularExpression(pattern: pattern, options: [])
                let errorMatchNum = regex.numberOfMatches(in: inputValue, options: [], range: NSMakeRange(0, inputValue.count))
                displayImage = (errorMatchNum <= 0) ? ((correctOnly) ? nil : invalidImage) : acceptImage
            }
        } else {
            displayImage = nil
        }
        
        self.acceptStateImageView?.image = displayImage
    }
    
    public func moveHint(direction:Int) {
        if (direction < 0) { //moving hint down
            phCenterYConstraint.isActive = true
            phBottomConstraint.isActive = false
            UIView.animate(withDuration: 0.1) {
                self.customPlaceholderView?.heightAnchor.constraint(equalToConstant: 20)
                self.customPlaceholderView?.transform = .identity
                self.layoutIfNeeded()
            }
        } else { //moving hint up
            phCenterYConstraint.isActive = false
            phBottomConstraint.isActive = true
            UIView.animate(withDuration: 0.1) {
                self.customPlaceholderView?.heightAnchor.constraint(equalToConstant: 15)
                self.customPlaceholderView?.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                self.layoutIfNeeded()
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        if (hasBottomBorder) {
            layer.addBorder(edge: .bottom, color: borderColor, thickness: borderWidth)
        } else if (hasBorder) {
            layer.borderWidth = borderWidth
            layer.borderColor = borderColor.cgColor
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
    
    private func setupView() {
        
        customPlaceholderView?.removeFromSuperview()
        customPlaceholderView = UILabel(frame: CGRect())
        customPlaceholderView!.attributedText = attributedHint
        customPlaceholderView!.alpha = 0.25
        customPlaceholderView!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(customPlaceholderView!)
        customPlaceholderView!.heightAnchor.constraint(equalToConstant: 20)
        customPlaceholderView!.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        phCenterYConstraint = customPlaceholderView!.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        phBottomConstraint = customPlaceholderView?.bottomAnchor.constraint(equalTo: self.topAnchor)
        phCenterYConstraint.isActive = true
        
        acceptStateImageView?.removeFromSuperview()
        acceptStateImageView = UIImageView(image: invalidImage)
        acceptStateImageView!.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(acceptStateImageView!)
        acceptStateImageView!.contentMode = .scaleAspectFit
        acceptStateImageView!.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        acceptStateImageView!.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        acceptStateImageView!.heightAnchor.constraint(equalTo: acceptStateImageView!.widthAnchor).isActive = true
        acceptStateImageView!.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.5).isActive = true
        
        self.setNeedsDisplay()
    }
}
