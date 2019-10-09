//
//  CourseSelectionViewController.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/20/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import Firebase

extension CourseSelectionViewController: CoursePickerDelegate {
    internal func refreshCourseList() {
        courseNameSearch.text = ""
        queryCourses(isTableRefresh: true)
    }
    internal func goToCourse(_ course: Course) {
        AppSingleton.shared.course = course;
        
        loadingView.startAnimating()
        loadingBackground.isHidden = false
        
        CourseTools.updateHoleInfo(for: course) { (success, err) in
            self.loadingView.stopAnimating()
            self.loadingBackground.isHidden = true
            
            if (success) {
                //tell tab parent controller to change tabs...
                //go to first hole if we are at new course??
                self.tabBarController?.selectedIndex = 1;
            } else {
                AppSingleton.shared.course = nil;
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Error!", message: "Unable to load hole information for selected course.", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
        }
    }
}

class CourseSelectionViewController: UIViewController {
    
    @IBOutlet weak var loadingBackground: UIView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var courseNameSearch: UITextField!
    @IBOutlet weak var courseTableContainer: UIView!
    @IBOutlet weak var requestCourseButton: UIButton!
    
    @IBOutlet weak var statePicker: UIPickerView!
    
    var embeddedCourseTableViewController:CoursePickerTableViewController?
    
    private var db:Firestore {
        return AppSingleton.shared.db;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingBackground.layer.cornerRadius = loadingView.frame.height / 2
        loadingBackground.layer.masksToBounds = true
        
        requestCourseButton.layer.cornerRadius = 8
        requestCourseButton.layer.masksToBounds = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        queryCourses()
    }
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func courseNameFilterChanged(_ sender: UITextField) {
        if let courseName = sender.text {
            queryCourses(with: courseName)
        }
    }
    
    private func queryCourses(with name: String = "", isTableRefresh:Bool = false) {
        if (!isTableRefresh) {
            loadingView.startAnimating()
            loadingBackground.isHidden = false
        }
        
        db.collection("courses")
            .whereField("name", isGreaterThanOrEqualTo: name)
            .whereField("name", isLessThan: "\(name)z")
            .order(by: "name")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    self.embeddedCourseTableViewController?.courseList.removeAll()
                    
                    //get all the courses and add to a course list
                    for document in querySnapshot!.documents {
                        let course:Course = Course(id: document.documentID)
                        
                        let data = document.data();
                        if let realCourseName:String = data["name"] as? String {
                            course.name = realCourseName;
                        }
                        if let city:String = data["city"] as? String {
                            course.city = city;
                        }
                        if let state:String = data["state"] as? String {
                            course.state = state;
                        }
                        if let spectationSpot:GeoPoint = data["spectation"] as? GeoPoint {
                            course.spectation = spectationSpot;
                        }
                        self.embeddedCourseTableViewController?.courseList.append(course);
                    }
                }
                
                self.loadingView.stopAnimating()
                self.loadingBackground.isHidden = true
                self.embeddedCourseTableViewController?.endRefresh()
                self.embeddedCourseTableViewController?.tableView.reloadData()
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "EmbedCourseTable") {
            if let vc = segue.destination as? CoursePickerTableViewController {
                self.embeddedCourseTableViewController = vc
                self.embeddedCourseTableViewController?.delegate = self;
            }
        }
    }
    
    //use this to pop out of a course request
    @IBAction func unwindToSelection(unwindSegue: UIStoryboardSegue) {
    }
    
    @IBAction func requestCourse(_ sender: UIButton) {
        
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
