//
//  MyBagViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 5/23/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit

class MyBagViewController: UIViewController {
    
    fileprivate var me:MePlayer {
        return AppSingleton.shared.me
    }

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
    
    @IBAction func clickEdit(_ sender: Any?) {
        if (myBagTVC.tableView.isEditing) {
            saveBag()
        } else {
            showEditBag()
        }
    }
    
    private func saveBag() {
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
        if self.me.bag.myClubs.isEmpty {
            let ac = UIAlertController(title: "Build a Bag", message: "Select an option to prepopulate your golf bag with a standard clubs and distances. You can customize it later.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Pro Golfer", style: .default, handler: { action in
                self.me.bag.populateBagLong()
                self.saveBag()
            }))
            ac.addAction(UIAlertAction(title: "Long Hitter", style: .default, handler: { action in
                self.me.bag.populateBagAverage()
                self.saveBag()
            }))
            ac.addAction(UIAlertAction(title: "Average Hitter", style: .default, handler: { action in
                self.me.bag.populateBagShort()
                self.saveBag()
            }))
            ac.addAction(UIAlertAction(title: "Custom", style: .cancel, handler: { action in
                self.performSegue(withIdentifier: "ShowAddClub", sender: nil)
            }))
            self.present(ac, animated: true)
        } else {
            self.performSegue(withIdentifier: "ShowAddClub", sender: nil)
        }
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
