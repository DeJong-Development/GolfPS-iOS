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

class CourseSelectionViewController: BaseKeyboardViewController {
    
    @IBOutlet weak var loadingBackground: UIView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var courseNameSearch: UITextField!
    @IBOutlet weak var courseTableContainer: UIView!
    @IBOutlet weak var requestCourseButton: UIButton!
    
    var embeddedCourseTableViewController:CoursePickerTableViewController?
    
    private var allGolfCourses:[Course] = [Course]()
    private var primaryNearbyCourses:[Course] = [Course]()
    private var primaryAmbassadorCourses:[Course] = [Course]()
    private var primaryVisitedCourses:[Course] = [Course]()
    private let geocoder = CLGeocoder()
    private let locationService = PlayerLocationService.shared
    private let mapTools = MapTools()
    
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
        
        getCourses()
    }
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    @IBAction func courseNameFilterChanged(_ sender: UITextField) {
        guard let queryText = sender.text, queryText.count > 1 else {
            self.embeddedCourseTableViewController?.isShowingSearchResults = false
            self.embeddedCourseTableViewController?.searchResults = []
            return
        }
        queryCourses(with: queryText)
    }
    
    private func getCourses(isTableRefresh:Bool = false) {
        if (!isTableRefresh) {
            loadingView.startAnimating()
            loadingBackground.isHidden = false
        }
        
        loadNearbyCourses { [weak self] nearbyCourses in
            guard let self = self else {
                DebugLogger.report(error: nil, message: "Unable to get courses. No self.")
                return
            }
            
            let courseIDsToLoad = (AppSingleton.shared.me.ambassadorCourses + (AppSingleton.shared.me.coursesVisited ?? []))
            CourseTools.getCourses(withIDs: courseIDsToLoad) { savedCourses, error in
                if let error = error {
                    DebugLogger.report(error: error, message: "Error retrieving saved courses.")
                }
                
                let ambassadorIDs = Set(AppSingleton.shared.me.ambassadorCourses)
                let visitedIDs = Set(AppSingleton.shared.me.coursesVisited ?? [])
                var coursesByID = [String: Course]()
                for course in nearbyCourses + savedCourses {
                    coursesByID[course.id] = course
                }
                
                self.allGolfCourses = Array(coursesByID.values).sorted(by: self.defaultSort(lhs:rhs:))
                self.primaryAmbassadorCourses = savedCourses
                    .filter { ambassadorIDs.contains($0.id) }
                    .sorted(by: self.defaultSort(lhs:rhs:))
                self.primaryVisitedCourses = savedCourses
                    .filter { visitedIDs.contains($0.id) && !ambassadorIDs.contains($0.id) }
                    .sorted(by: self.defaultSort(lhs:rhs:))
                self.primaryNearbyCourses = nearbyCourses
                    .filter { !ambassadorIDs.contains($0.id) && !visitedIDs.contains($0.id) }
                    .sorted(by: self.defaultSort(lhs:rhs:))
                
                self.embeddedCourseTableViewController?.ambassadorCourses = self.primaryAmbassadorCourses
                self.embeddedCourseTableViewController?.nearbyCourses = self.primaryNearbyCourses
                self.embeddedCourseTableViewController?.visitedCourses = self.primaryVisitedCourses
                self.embeddedCourseTableViewController?.courseDistances = self.courseDistanceLabels(for: self.allGolfCourses)
                self.embeddedCourseTableViewController?.isShowingSearchResults = false
                self.embeddedCourseTableViewController?.searchResults = []
                self.embeddedCourseTableViewController?.endRefresh()
                
                if let searchQuery = self.courseNameSearch.text,
                   searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 {
                    self.queryCourses(with: searchQuery)
                }
                self.loadingView.stopAnimating()
                self.loadingBackground.isHidden = true
            }
        }
    }
    
    private func queryCourses(with query: String = "") {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            embeddedCourseTableViewController?.isShowingSearchResults = false
            embeddedCourseTableViewController?.searchResults = []
            return
        }
        
        loadingView.startAnimating()
        loadingBackground.isHidden = false
        
        db.collection("courses").order(by: "name").getDocuments { [weak self] snapshot, error in
            guard let self = self else {
                return
            }
            
            if let error = error {
                DebugLogger.report(error: error, message: "Error retrieving courses for search.")
                self.embeddedCourseTableViewController?.searchResults = []
                self.embeddedCourseTableViewController?.isShowingSearchResults = true
                self.loadingView.stopAnimating()
                self.loadingBackground.isHidden = true
                return
            }
            
            let allCourses = snapshot?.documents.compactMap { document in
                Course(id: document.documentID, data: document.data())
            } ?? []
            let coursesThatMatch = allCourses.filter { course in
                self.courseMatchesSearch(course, query: q)
            }.sorted(by: self.defaultSort(lhs:rhs:))
            
            self.embeddedCourseTableViewController?.courseDistances = self.courseDistanceLabels(for: coursesThatMatch)
            self.embeddedCourseTableViewController?.searchResults = coursesThatMatch
            self.embeddedCourseTableViewController?.isShowingSearchResults = true
            self.loadingView.stopAnimating()
            self.loadingBackground.isHidden = true
        }
    }
    
    private func loadNearbyCourses(completion: @escaping ([Course]) -> Void) {
        locationService.requestLocation { [weak self] geoPoint in
            guard let self = self else {
                return
            }
            
            guard let geoPoint = geoPoint else {
                completion([])
                return
            }
            
            let location = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
            self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    DebugLogger.report(error: error, message: "Error reverse geocoding player location for nearby courses.")
                    completion([])
                    return
                }
                
                guard let stateCode = placemarks?.first?.administrativeArea?.uppercased() else {
                    completion([])
                    return
                }
                
                CourseTools.getCourses(inState: stateCode) { courses, error in
                    if let error = error {
                        DebugLogger.report(error: error, message: "Error retrieving nearby state courses.")
                    }
                    completion(courses)
                }
            }
        }
    }
    
    private func courseMatchesSearch(_ course: Course, query: String) -> Bool {
        let name = course.name.lowercased()
        let city = course.city.lowercased()
        let stateCode = course.state.lowercased()
        let stateName = course.fullStateName?.lowercased()
        
        if name == "test course" {
            return false
        }
        
        if name.contains(query) || city.contains(query) || stateCode.contains(query) {
            return true
        }
        
        if let stateName = stateName,
           stateName.contains(query) || query.fuzzyMatch(stateName) {
            return true
        }
        
        return query.fuzzyMatch(name) || query.fuzzyMatch(city) || query.fuzzyMatch(stateCode)
    }
    
    private func courseDistanceLabels(for courses: [Course]) -> [String:String] {
        guard let myLocation = AppSingleton.shared.me?.geoPoint else {
            return [:]
        }
        
        var labels:[String:String] = [:]
        for course in courses {
            guard let courseLocation = course.spectation else {
                continue
            }
            
            let rawDistance = mapTools.distanceFrom(first: myLocation, second: courseLocation)
            if AppSingleton.shared.metric {
                let kilometers = Double(rawDistance) / 1000
                labels[course.id] = String(format: "%.1f km", kilometers)
            } else {
                let miles = Double(rawDistance) / 1760
                labels[course.id] = String(format: "%.1f mi", miles)
            }
        }
        return labels
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
