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
    @IBOutlet weak var editButton: ButtonX!
    @IBOutlet weak var addClubButton: ButtonX!
    
    private var myBagTVC:MyBagTableViewController!
    
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
    
    @IBAction func clickEdit(_ sender: Any) {
        if (myBagTVC.tableView.isEditing) {
            myBagTVC.tableView.setEditing(false, animated: true)
            editButton.setTitle("EDIT", for: .normal)
            editButton.backgroundColor = .grass
            editButton.setTitleColor(.white, for: .normal)
            editButton.borderWidth = 1
            addClubButton.isHidden = true
        } else {
            myBagTVC.tableView.setEditing(true, animated: true)
            editButton.setTitle("SAVE", for: .normal)
            editButton.backgroundColor = .gold
            editButton.setTitleColor(.black, for: .normal)
            editButton.borderWidth = 0
            addClubButton.isHidden = false
        }
    }
    @IBAction func clickAddClub(_ sender: Any) {
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MyBagTableViewController {
            self.myBagTVC = vc
        }
    }
}
