//
//  BaseKeyboardViewController.swift
//  Football Game Plan
//
//  Created by Greg DeJong on 4/17/20.
//  Copyright © 2020 DeJong Development. All rights reserved.
//

import UIKit

class BaseKeyboardViewController: UIViewController {

    var isTransitioningKeyboard:Bool = false
    var keyboardIsVisible:Bool = false
    var keyboardFrame:CGRect = CGRect.zero
    var statusBarHeight:CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipe.cancelsTouchesInView = false
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
        
        let center = NotificationCenter.default;
        center.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(changeStatusBarSize), name: UIApplication.willChangeStatusBarFrameNotification, object: nil)
    }

    @objc internal func dismissKeyboard() {
        self.isTransitioningKeyboard = false
        self.keyboardIsVisible = false
        view.endEditing(true)
    }
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = ((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) {
            self.keyboardFrame = keyboardFrame
            if (!self.keyboardIsVisible) {
                self.keyboardIsVisible = true
                moveViewUpFromKeyboard(force:true)
            }
        }
    }
    @objc private func keyboardWillHide(notification: NSNotification) {
        if let _ = ((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) {
            self.keyboardFrame = CGRect.zero
            self.keyboardIsVisible = false
            if !isTransitioningKeyboard {
                UIView.animate(withDuration: 0.1, animations: {
                    self.performKeyboardHideActions()
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    @objc func changeStatusBarSize(notification: NSNotification) {
        moveViewUpFromKeyboard(force: true)
    }
    private func moveViewUpFromKeyboard(force:Bool) {
        if (self.keyboardIsVisible) {
            UIView.animate(withDuration: 0.1, animations: {
                self.performKeyboardShowActions()
                self.view.layoutIfNeeded()
            })
        }
    }
    
    internal func performKeyboardHideActions() {}
    internal func performKeyboardShowActions() {}

}
