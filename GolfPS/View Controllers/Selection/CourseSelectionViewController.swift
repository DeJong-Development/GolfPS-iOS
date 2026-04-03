//
//  CourseSelectionViewController.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/20/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseFirestore

extension CourseSelectionViewController: CoursePickerDelegate {
    internal func refreshCourseList() {
        courseNameSearch.text = ""
        getCourses(isTableRefresh: true)
    }
    internal func goToCourse(_ course: Course) {
        AppSingleton.shared.course = course
        
        self.loadingView.startAnimating()
        self.loadingBackground.isHidden = false
        
        DispatchQueue.global(qos: .userInteractive).async {
            CourseTools.updateHoleInfo(for: course) {[weak self] (success, err) in
                guard let self = self else {
                    AppSingleton.shared.course = nil
                    return
                }
                
                DispatchQueue.main.async {
                    if (success) {
                        
                        //update selected course
                        AppSingleton.shared.db.collection("players")
                            .document(AppSingleton.shared.me.id)
                            .setData([
                                "course": course.id,
                                "updateTime": Timestamp()
                                ], merge: true)
                        
                        if AppSingleton.shared.cupholderMode {
                            self.performSegue(withIdentifier: "GoToCourseCupholder", sender: nil)
                        } else {
                            self.performSegue(withIdentifier: "GoToCourse", sender: nil)
                        }
                    } else {
                        AppSingleton.shared.course = nil
                        self.loadingView.stopAnimating()
                        self.loadingBackground.isHidden = true
                        
                        let ac = UIAlertController(title: "Error!", message: "Unable to load hole information for selected course.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
    }
}

class CourseSelectionViewController: BaseKeyboardViewController, UITextFieldDelegate {
    
    @IBOutlet weak var loadingBackground: UIView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var stateButton: UIButton!
    @IBOutlet weak var courseNameSearch: UITextField!
    @IBOutlet weak var courseTableContainer: UIView!
    @IBOutlet weak var requestCourseButton: UIButton!
    
    var embeddedCourseTableViewController:CoursePickerTableViewController?
    
    private var allGolfCourses:[Course] = [Course]()
    private var availableStates:[String] = []
    private var selectedState:String?
    private let geocoder = CLGeocoder()
    private let locationService = PlayerLocationService.shared
    private let statePickerView = UIPickerView()
    private let statePickerHostField = UITextField(frame: .zero)
    private var isFinalizingStateSelection = false
    
    private var db:Firestore {
        return AppSingleton.shared.db
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingBackground.layer.cornerRadius = loadingView.frame.height / 2
        loadingBackground.layer.masksToBounds = true
        
        requestCourseButton.layer.cornerRadius = 8
        requestCourseButton.layer.masksToBounds = true
        stateButton.layer.cornerRadius = 8
        stateButton.layer.masksToBounds = true
        
        statePickerView.dataSource = self
        statePickerView.delegate = self
        statePickerHostField.delegate = self
        statePickerHostField.inputView = statePickerView
        statePickerHostField.inputAccessoryView = makeStatePickerAccessoryView()
        statePickerHostField.isHidden = true
        view.addSubview(statePickerHostField)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        loadAvailableStates()
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
    
    @IBAction func stateFilterTapped(_ sender: UIButton) {
        if availableStates.isEmpty {
            return
        }
        
        if let selectedState = selectedState,
           let selectedIndex = availableStates.firstIndex(of: selectedState) {
            statePickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        } else {
            statePickerView.selectRow(0, inComponent: 0, animated: false)
        }
        
        statePickerHostField.becomeFirstResponder()
    }
    
    private func getCourses(isTableRefresh:Bool = false) {
        if (!isTableRefresh) {
            loadingView.startAnimating()
            loadingBackground.isHidden = false
        }
        
        guard let selectedState = selectedState, !selectedState.isEmpty else {
            self.allGolfCourses = []
            self.embeddedCourseTableViewController?.endRefresh()
            self.embeddedCourseTableViewController?.courseList = []
            self.loadingView.stopAnimating()
            self.loadingBackground.isHidden = true
            return
        }
        
        CourseTools.getCourses(inState: selectedState) { [weak self] nearbyCourses, stateError in
            guard let self = self else {
                DebugLogger.report(error: nil, message: "Unable to get courses. No self.")
                return
            }
            if let stateError = stateError {
                DebugLogger.report(error: stateError, message: "Error retrieving selected state courses.")
            }
            
            let courseIDsToLoad = (AppSingleton.shared.me.ambassadorCourses + (AppSingleton.shared.me.coursesVisited ?? []))
            CourseTools.getCourses(withIDs: courseIDsToLoad) { savedCourses, error in
                if let error = error {
                    DebugLogger.report(error: error, message: "Error retrieving saved courses.")
                }
                
                var coursesByID = [String: Course]()
                for course in nearbyCourses + savedCourses {
                    coursesByID[course.id] = course
                }
                
                self.allGolfCourses = Array(coursesByID.values).sorted(by: self.defaultSort(lhs:rhs:))
                self.embeddedCourseTableViewController?.endRefresh()
                self.queryCourses()
                self.loadingView.stopAnimating()
                self.loadingBackground.isHidden = true
            }
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
    
    private func loadAvailableStates() {
        loadingView.startAnimating()
        loadingBackground.isHidden = false
        
        CourseTools.getAvailableStates { [weak self] states, error in
            guard let self = self else {
                return
            }
            if let error = error {
                DebugLogger.report(error: error, message: "Error retrieving available course states.")
            }
            
            self.availableStates = states
            self.statePickerView.reloadAllComponents()
            self.loadNearbyStateSelection()
        }
    }
    
    private func loadNearbyStateSelection() {
        locationService.requestLocation { [weak self] geoPoint in
            guard let self = self else {
                return
            }
            
            guard let geoPoint = geoPoint else {
                self.applySelectedState(self.availableStates.first)
                return
            }
            
            let location = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
            self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    DebugLogger.report(error: error, message: "Error reverse geocoding player location for nearby courses.")
                    self.applySelectedState(self.availableStates.first)
                    return
                }
                
                guard let stateCode = placemarks?.first?.administrativeArea?.uppercased() else {
                    self.applySelectedState(self.availableStates.first)
                    return
                }
                
                self.applySelectedState(self.availableStates.contains(stateCode) ? stateCode : self.availableStates.first)
            }
        }
    }
    
    private func applySelectedState(_ state: String?) {
        selectedState = state
        stateButton.setTitle(state, for: .normal)
        
        if let state = state, let selectedIndex = availableStates.firstIndex(of: state) {
            statePickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        }
        
        getCourses()
    }
    
    private func makeStatePickerAccessoryView() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(commitSelectedState))
        ]
        return toolbar
    }
    
    @objc private func commitSelectedState() {
        finalizeStateSelection()
        statePickerHostField.resignFirstResponder()
    }
    
    private func finalizeStateSelection() {
        guard !isFinalizingStateSelection else {
            return
        }
        
        isFinalizingStateSelection = true
        defer { isFinalizingStateSelection = false }
        
        let selectedIndex = statePickerView.selectedRow(inComponent: 0)
        guard availableStates.indices.contains(selectedIndex) else {
            return
        }
        
        applySelectedState(availableStates[selectedIndex])
    }
    
    private func defaultSort(lhs: Course, rhs: Course) -> Bool {
        guard let me = AppSingleton.shared.me else {
            return lhs.name < rhs.name
        }
        
        let lhsIsAmbassador = me.ambassadorCourses.contains(lhs.id)
        let rhsIsAmbassador = me.ambassadorCourses.contains(rhs.id)
        if lhsIsAmbassador != rhsIsAmbassador {
            return lhsIsAmbassador
        }
        
        let lhsWasVisited = me.coursesVisited?.contains(lhs.id) ?? false
        let rhsWasVisited = me.coursesVisited?.contains(rhs.id) ?? false
        if lhsWasVisited != rhsWasVisited {
            return lhsWasVisited
        }
        
        if let myLocation = me.geoPoint {
            let lhsDistance = distanceToCourse(lhs, from: myLocation)
            let rhsDistance = distanceToCourse(rhs, from: myLocation)
            if lhsDistance != rhsDistance {
                return lhsDistance < rhsDistance
            }
        }
        
        return lhs.name < rhs.name
    }
    
    private func distanceToCourse(_ course: Course, from geoPoint: GeoPoint) -> Int {
        guard let spectation = course.spectation else {
            return Int.max
        }
        return MapTools().distanceFrom(first: geoPoint, second: spectation)
    }
    
    //use this to pop out of a course request
    @IBAction func unwindToSelection(unwindSegue: UIStoryboardSegue) {
        AppSingleton.shared.course?.holeInfo.removeAll()
        
        DispatchQueue.main.async {
            self.embeddedCourseTableViewController?.deselectRows()
            self.loadingView.stopAnimating()
            self.loadingBackground.isHidden = true
        }
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
}

extension CourseSelectionViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableStates.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard availableStates.indices.contains(row) else {
            return nil
        }
        return displayName(for: availableStates[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    }
    
    private func displayName(for stateCode: String?) -> String {
        guard let stateCode = stateCode, !stateCode.isEmpty else {
            return ""
        }
        
        if let fullName = Course.fullStateName(for: stateCode) {
            return "\(stateCode) - \(fullName)"
        }
        
        return stateCode
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField == statePickerHostField else {
            return
        }
        finalizeStateSelection()
    }
}
