//
//  GolfCourseTableViewCell.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/20/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit

class ClubTableViewCell: UITableViewCell {

    @IBOutlet weak var clubName: UITextField!
    @IBOutlet weak var clubDistance: UITextField!
    
    private var inputAccessoryLabel:UILabel?
    
    internal var club:Club! {
        didSet {
            clubName.text = club.name
            clubDistance.text = String(club.distance)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        clubName.returnKeyType = .done
        clubDistance.returnKeyType = .done
        
        if #available(iOS 13.0, *) {
            let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 30))

            inputAccessoryLabel = UILabel(frame: CGRect(x: 0, y: 15, width: UIScreen.main.bounds.width, height: 15))
            inputAccessoryLabel!.text = "Club Name"
            inputAccessoryLabel!.textAlignment = .center
            inputAccessoryLabel!.textColor = UIColor.label
            inputAccessoryLabel!.alpha = 0.2
            
            let prvBtn: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goToPreviousField))
            let nextBtn: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(goToNextField))
            let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(finishCurrentField))
            toolbar.setItems([prvBtn, nextBtn, flexSpace, doneBtn], animated: false)
            toolbar.addSubview(inputAccessoryLabel!)
            toolbar.sizeToFit()
            
            self.clubName.inputAccessoryView = toolbar
            self.clubDistance.inputAccessoryView = toolbar
        } else {
            let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: UIScreen.main.bounds.width, height: 30))
            //create left side empty space so that done button set on right side
            let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(finishCurrentField))
            toolbar.setItems([flexSpace, doneBtn], animated: false)
            toolbar.sizeToFit()
            
            //setting toolbar as inputAccessoryView
            self.clubName.inputAccessoryView = toolbar
            self.clubDistance.inputAccessoryView = toolbar
        }
    }
    
    private func cleanClubName() {
        let clubName = ClubTools.cleanClubName(self.clubName.text)
        self.club.name = clubName
        self.clubName.text = clubName
        AppSingleton.shared.me.didCustomizeBag = true
    }
    private func cleanClubDistance() {
        let clubDistance = ClubTools.cleanClubDistance(self.clubDistance.text)
        guard let clubDistanceNum = Int(clubDistance) else {
            return
        }
        self.club.distance = clubDistanceNum
        self.clubDistance.text = clubDistance
        AppSingleton.shared.me.didCustomizeBag = true
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
        if let clubName = clubName.text, clubName != "" {
            inputAccessoryLabel?.text = "\(clubName) Distance"
        } else {
            inputAccessoryLabel?.text = "Avg Distance"
        }
    }
    @IBAction func endDistance(_ sender: Any) {
        cleanClubDistance()
        dismissKeyboard()
    }
    
    //MARK: Toolbar selectors
    @objc func finishCurrentField() {
        if clubName.isFirstResponder {
            cleanClubName()
        } else if clubDistance.isFirstResponder {
            cleanClubDistance()
        }
        dismissKeyboard()
    }
    @objc func goToPreviousField() {
        if clubName.isFirstResponder {
            cleanClubName()
            dismissKeyboard()
        } else {
            cleanClubDistance()
            clubName.becomeFirstResponder()
        }
    }
    @objc func goToNextField() {
        if clubName.isFirstResponder {
            cleanClubName()
            clubDistance.becomeFirstResponder()
        } else {
            cleanClubDistance()
            dismissKeyboard()
        }
    }
    
    private func dismissKeyboard() {
        self.endEditing(true)
    }
}
