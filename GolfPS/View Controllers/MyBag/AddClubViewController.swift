//
//  AddClubViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 10/18/20.
//  Copyright © 2020 DeJong Development. All rights reserved.
//

import UIKit

class AddClubViewController: BaseKeyboardViewController {
    
    private let myBag:Bag = AppSingleton.shared.me.bag
    
    private var inputAccessoryLabel:UILabel?
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var distanceField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))

            inputAccessoryLabel = UILabel(frame: CGRect(x: 0, y: 15, width: self.view.frame.size.width, height: 15))
            inputAccessoryLabel!.text = "Club Name"
            inputAccessoryLabel!.textAlignment = .center
            inputAccessoryLabel!.textColor = UIColor.label
            inputAccessoryLabel!.alpha = 0.2
            
            let prvBtn: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.up"), style: .plain, target: self, action: #selector(goToPreviousField))
            let nextBtn: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.down"), style: .plain, target: self, action: #selector(goToNextField))
            let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(finishCurrentField))
            toolbar.setItems([prvBtn, nextBtn, flexSpace, doneBtn], animated: false)
            toolbar.addSubview(inputAccessoryLabel!)
            toolbar.sizeToFit()
            
            //setting toolbar as inputAccessoryView
            self.nameField.inputAccessoryView = toolbar
            self.distanceField.inputAccessoryView = toolbar
        } else {
            let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
            //create left side empty space so that done button set on right side
            let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(finishCurrentField))
            toolbar.setItems([flexSpace, doneBtn], animated: false)
            toolbar.sizeToFit()
            
            //setting toolbar as inputAccessoryView
            self.distanceField.inputAccessoryView = toolbar
        }
    }
    
    private func cleanClubName() {
        let clubName = ClubTools.cleanClubName(self.nameField.text)
        self.nameField.text = clubName
        AppSingleton.shared.me.didCustomizeBag = true
    }
    private func cleanClubDistance() {
        let clubDistance = ClubTools.cleanClubDistance(self.distanceField.text)
        guard Int(clubDistance) != nil else {
            return
        }
        self.distanceField.text = clubDistance
    }
    
    @objc func finishCurrentField() {
        if nameField.isFirstResponder {
            cleanClubName()
        } else if distanceField.isFirstResponder {
            cleanClubDistance()
        }
        dismissKeyboard()
    }
    @objc func goToPreviousField() {
        if nameField.isFirstResponder {
            cleanClubName()
            dismissKeyboard()
        } else {
            cleanClubDistance()
            nameField.becomeFirstResponder()
        }
    }
    @objc func goToNextField() {
        if nameField.isFirstResponder {
            cleanClubName()
            distanceField.becomeFirstResponder()
        } else {
            cleanClubDistance()
            dismissKeyboard()
        }
    }
    
    //MARK: Actions for club name
    @IBAction func startName(_ sender: Any) {
        inputAccessoryLabel?.text = "Club Name"
    }
    @IBAction func endName(_ sender: Any) {
        cleanClubName()
        dismissKeyboard()
    }
    
    //MARK: Actions for club distance
    @IBAction func startDistance(_ sender: Any) {
        if let clubName = nameField.text, clubName != "" {
            inputAccessoryLabel?.text = "\(clubName) Distance"
        } else {
            inputAccessoryLabel?.text = "Avg Distance"
        }
    }
    @IBAction func endDistance(_ sender: Any) {
        cleanClubDistance()
        dismissKeyboard()
    }
    
    @IBAction func clickAdd(_ sender: Any) {
        addNewClub()
    }
    
    @IBAction func clickCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func addNewClub() {
        guard let clubName = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), clubName != "", let distanceString = distanceField.text?.trimmingCharacters(in: .whitespacesAndNewlines), let clubDistance = Int(distanceString) else {
            self.distanceField.text = nil
            self.nameField.text = nil
            return
        }
        
        var newClub = Club(number: self.myBag.myClubs.count + 1)
        newClub.distance = clubDistance
        newClub.name = clubName
        
        AppSingleton.shared.me.didCustomizeBag = true
        
        //perform unwind so we can respond
        self.performSegue(withIdentifier: "unwindToMyBag", sender: newClub)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MyBagViewController, let club = sender as? Club {
            vc.additionalClub = club
        }
    }
    
}
