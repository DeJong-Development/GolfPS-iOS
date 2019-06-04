//
//  MyBagViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 5/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit

class MyBagViewController: UIViewController {

    @IBOutlet weak var tableViewContainer: UIView!
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
