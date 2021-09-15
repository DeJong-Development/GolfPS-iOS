//
//  CourseSelectionViewController.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/20/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import FirebaseFirestore

extension CourseSelectionViewController: CoursePickerDelegate {
    internal func refreshCourseList() {
        courseNameSearch.text = ""
        getCourses(isTableRefresh: true)
    }
    internal func goToCourse(_ course: Course) {
        AppSingleton.shared.course = course;
        
        loadingView.startAnimating()
        loadingBackground.isHidden = false
        
        CourseTools.updateHoleInfo(for: course) { (success, err) in
            self.loadingView.stopAnimating()
            self.loadingBackground.isHidden = true
            
            if (success) {
                
                //update selected course
                AppSingleton.shared.db.collection("players")
                    .document(AppSingleton.shared.me.id)
                    .setData([
                        "course": course.id,
                        "updateTime": Date().iso8601
                        ], merge: true)
                
                self.performSegue(withIdentifier: "GoToCourse", sender: nil)
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
    
    var embeddedCourseTableViewController:CoursePickerTableViewController?
    
    private var allGolfCourses:[Course] = [Course]()
    
    private var db:Firestore {
        return AppSingleton.shared.db
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingBackground.layer.cornerRadius = loadingView.frame.height / 2
        loadingBackground.layer.masksToBounds = true
        
        requestCourseButton.layer.cornerRadius = 8
        requestCourseButton.layer.masksToBounds = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        //get all courses at load
        getCourses()
    }
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    @IBAction func courseNameFilterChanged(_ sender: UITextField) {
        guard let queryText = sender.text, queryText.count > 1 else {
            self.embeddedCourseTableViewController?.courseList = Array(allGolfCourses)
            self.embeddedCourseTableViewController?.tableView.reloadData()
            return
        }
        queryCourses(with: queryText)
    }
    
    private func getCourses(isTableRefresh:Bool = false) {
        if (!isTableRefresh) {
            loadingView.startAnimating()
            loadingBackground.isHidden = false
        }
        
        var golfCourses:[Course] = [Course]()
        
        db.collection("courses")
            .order(by: "name")
            .getDocuments() { [weak self] (querySnapshot, err) in
                guard let self = self else { return }
                if let err = err {
                    print("Error getting documents: \(err)")
                } else if let snapshot = querySnapshot {
                    //get all the courses and add to a course list
                    for document in snapshot.documents {
                        guard let course = Course(id: document.documentID, data: document.data()) else {
                            continue
                        }
                        golfCourses.append(course)
                    }
                }
                
                self.allGolfCourses = golfCourses.sorted { $0.name < $1.name }
                self.queryCourses()
                self.loadingView.stopAnimating()
                self.loadingBackground.isHidden = true
                self.embeddedCourseTableViewController?.endRefresh()
        }
    }
    
    private func queryCourses(with query: String = "") {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var coursesThatMatch = Set<Course>()
        for course in allGolfCourses {
            let name = course.name.lowercased()
            let abbrev = course.state.lowercased()
            let state = course.fullStateName?.lowercased()
            
            if (name == "test course") {
                continue
            } else if (query == "") {
                coursesThatMatch.insert(course)
                continue
            }
            
            if (name.contains(q) || abbrev.contains(q) || q.starts(with: name) || q.starts(with: abbrev)) {
                coursesThatMatch.insert(course)
            } else if let stateName = state, stateName.contains(q) || q.starts(with: stateName.lowercased()) || query.fuzzyMatch(stateName) {
                coursesThatMatch.insert(course)
            } else if query.fuzzyMatch(name) || query.fuzzyMatch(abbrev) {
                coursesThatMatch.insert(course)
            }
        }
        let courseArray = Array(coursesThatMatch).sorted { $0.name < $1.name }
        self.embeddedCourseTableViewController?.courseList = courseArray
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as CoursePickerTableViewController:
            self.embeddedCourseTableViewController = vc
            self.embeddedCourseTableViewController?.delegate = self
        default: ()
        }
    }
    
    //use this to pop out of a course request
    @IBAction func unwindToSelection(unwindSegue: UIStoryboardSegue) {
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
