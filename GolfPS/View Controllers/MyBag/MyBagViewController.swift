//
//  MyBagViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 5/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit

class MyBagViewController: UIViewController {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tableViewContainer: UIView!
    @IBOutlet weak var editButton: ButtonX!
    @IBOutlet weak var addClubButton: ButtonX!
    
    @IBOutlet weak var editImage: UIImageView!
    
    private var myBagTVC:MyBagTableViewController!
    
    internal var additionalClub:Club!
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AppSingleton.shared.me.bag.myClubs.isEmpty {
            messageLabel.text = "Add clubs to your bag for on-course recommendations."
            showEditBag()
        } else {
            messageLabel.text = "Update your clubs for more accurate recommendations!"
        }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
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
            editImage.image = #imageLiteral(resourceName: "customize")
            addClubButton.isHidden = true
            
            //bag info autosaved within club model
            //sort bag with provided average distances
            AppSingleton.shared.me.bag.sortClubs()
            
            //show in proper order
            self.myBagTVC.tableView.reloadData()
        } else {
            showEditBag()
        }
    }
    
    private func showEditBag() {
        myBagTVC.tableView.setEditing(true, animated: true)
        editButton.setTitle("SAVE", for: .normal)
        editButton.backgroundColor = .gold
        editButton.setTitleColor(.black, for: .normal)
        editImage.image = #imageLiteral(resourceName: "noun_Save_1409370")
        addClubButton.isHidden = false
    }
    
    @IBAction func clickAddClub(_ sender: Any) {
        //show the add club dialog
    }
    
    @IBAction func unwindToMyBag(unwindSegue: UIStoryboardSegue) {
        guard let addedNewClub = additionalClub else {
            return
        }
        
        self.myBagTVC.addClub(addedNewClub)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MyBagTableViewController {
            self.myBagTVC = vc
        }
    }
}
