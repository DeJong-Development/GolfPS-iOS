//
//  RequestViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 7/26/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit

class RequestViewController: BaseKeyboardViewController {

    @IBOutlet weak var entireStack: UIStackView!
    
    @IBOutlet weak var nameStack: UIStackView!
    @IBOutlet weak var cityStack: UIStackView!
    @IBOutlet weak var stateStack: UIStackView!
    @IBOutlet weak var countryStack: UIStackView!
    
    @IBOutlet weak var courseNameField: UITextField!
    @IBOutlet weak var courseCityField: UITextField!
    @IBOutlet weak var courseStateField: UITextField!
    @IBOutlet weak var courseCountryField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var progressView: UIActivityIndicatorView!
    @IBOutlet weak var progressBackground: UIView!
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressBackground.layer.cornerRadius = progressView.frame.height / 2
        progressBackground.layer.masksToBounds = true
        progressBackground.isHidden = true
        
        submitButton.layer.cornerRadius = 8
        submitButton.layer.masksToBounds = true
        
        cancelButton.layer.cornerRadius = 8
        cancelButton.layer.masksToBounds = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @IBAction func doneWithName(_ sender: UITextField) {
        sender.resignFirstResponder();
        courseCityField.becomeFirstResponder()
    }
    @IBAction func doneWithCity(_ sender: UITextField) {
        sender.resignFirstResponder();
        courseStateField.becomeFirstResponder()
    }
    @IBAction func doneWithState(_ sender: UITextField) {
        sender.resignFirstResponder();
        courseCountryField.becomeFirstResponder()
    }
    @IBAction func doneWithCountry(_ sender: UITextField) {
        sender.resignFirstResponder();
    }
    
    @IBAction func clickSubmit(_ sender: UIButton) {
        progressBackground.isHidden = false
        
        guard let name = courseNameField.text,
            name.trimmingCharacters(in: .whitespacesAndNewlines) != "",
            let city = courseCityField.text,
            city.trimmingCharacters(in: .whitespacesAndNewlines) != "",
            let state = courseStateField.text,
            state.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
                let alertController = UIAlertController(title: "Error!", message: "Unable to request course. Please fill in all the fields and try again.", preferredStyle: UIAlertController.Style.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                    (result : UIAlertAction) -> Void in
                    self.progressBackground.isHidden = true
                }
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                return
        }
        
        AppSingleton.shared.db.collection("course-requests")
            .addDocument(data: [
            "name": name,
            "city": city,
            "state": state,
            "user": AppSingleton.shared.me.id,
            "requestDate": Date().iso8601
        ]) { err in
            
            self.progressBackground.isHidden = true
            if let err = err {
                DebugLogger.report(error: err, message: "Unable to send course request.")
                
                let alertController = UIAlertController(title: "Error!", message: "Unable to request course. Not quite sure why... Sorry!", preferredStyle: UIAlertController.Style.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                    (result : UIAlertAction) -> Void in
                    self.progressBackground.isHidden = true
                }
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                DebugLogger.log(message: "Sent course request!")
                
                let alertController = UIAlertController(title: "Course Requested!", message: "Successfully requested a new golf course! Check back in later to see it in the course list.", preferredStyle: UIAlertController.Style.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                    (result : UIAlertAction) -> Void in
                    self.performSegue(withIdentifier: "unwindFromRequest", sender: nil)
                }
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    @IBAction func clickCancel(_ sender: UIButton) {
        //tied to unwind segue back to course selection
    }
    
    override func performKeyboardShowActions() {
        guard UIDevice.current.userInterfaceIdiom != .pad else {
            return
        }
        entireStack.spacing = 4
        nameStack.spacing = 0
        cityStack.spacing = 0
        stateStack.spacing = 0
        countryStack.spacing = 0
    }
    override func performKeyboardHideActions() {
        guard UIDevice.current.userInterfaceIdiom != .pad else {
            return
        }
        entireStack.spacing = 6
        nameStack.spacing = 4
        cityStack.spacing = 4
        stateStack.spacing = 4
        countryStack.spacing = 4
    }
}
