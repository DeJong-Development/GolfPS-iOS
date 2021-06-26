//
//  CoursePickerTableViewController.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/20/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit
import FirebaseAnalytics

protocol CoursePickerDelegate {
    func refreshCourseList()
    func goToCourse(_ course:Course)
}

class CoursePickerTableViewController: UITableViewController {
    
    var delegate:CoursePickerDelegate?
    
    final let cellIdentifier = "GCTableCell"
    var courseList:[Course] = [Course]()
    
    override func viewWillLayoutSubviews() {
        self.tableView.layer.cornerRadius = 6
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl();
        let attrs: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor : UIColor.white,
            ]
        refreshControl!.attributedTitle = NSAttributedString(string: "Updating...", attributes: attrs)
        refreshControl!.addTarget(self, action: #selector(refreshCourses), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        
        self.tableView.tableFooterView = UIView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func refreshCourses() {
        delegate?.refreshCourseList()
    }
    internal func endRefresh() {
        refreshControl?.endRefreshing()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return max(1, courseList.count)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (tableView.cellForRow(at: indexPath) as? CourseTableViewCell) != nil else {
            fatalError("selected cell is not a course cell")
        }
        
        if (courseList.count == 0) {
            //do nothing - this is a placeholder cell
        } else {
            let course:Course = courseList[indexPath.row]
            
            Analytics.logEvent("select_course", parameters:  [
                "name": course.name.lowercased()
                ])
            
            delegate?.goToCourse(course)
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CourseTableViewCell else {
            fatalError("The dequeued cell is not an instance of GCTableCell.")
        }
        
        if (courseList.count == 0) {
            //do nothing - this is a placeholder cell
            cell.courseNameLabel.text = "NO COURSES FOUND!"
            cell.courseStateLabel.text = ""
            cell.courseNameLabel.textColor = UIColor.red
        } else {
            if #available(iOS 13.0, *) {
                cell.courseNameLabel.textColor = UIColor.label
            } else {
                // Fallback on earlier versions
                cell.courseNameLabel.textColor = UIColor.black
            }
            cell.courseNameLabel.text = courseList[indexPath.row].name;
            
            let stateInitials = courseList[indexPath.row].state.uppercased()
            cell.courseStateLabel.text = stateInitials
            
            switch stateInitials {
            case "MI": cell.stateImage.image = #imageLiteral(resourceName: "noun_Michigan_3180612")
            case "NC": cell.stateImage.image = #imageLiteral(resourceName: "noun_North Carolina_3180579")
            case "OH": cell.stateImage.image = #imageLiteral(resourceName: "noun_Ohio_3180618")
            case "IL": cell.stateImage.image = #imageLiteral(resourceName: "noun_Illinois_3180635")
            case "TN": cell.stateImage.image = #imageLiteral(resourceName: "noun_Tennessee_3180631")
            case "CA": cell.stateImage.image = #imageLiteral(resourceName: "noun_California_3180613")
            case "FL": cell.stateImage.image = #imageLiteral(resourceName: "noun_Florida_3180625")
            case "KY": cell.stateImage.image = #imageLiteral(resourceName: "noun_Kentucky_3180628")
            case "UT": cell.stateImage.image = #imageLiteral(resourceName: "noun_Utah_3180614")
            case "UK": cell.stateImage.image = #imageLiteral(resourceName: "noun_United Kingdom_258578")
            case "QC": cell.stateImage.image = #imageLiteral(resourceName: "noun_Quebec_12783")
            case "ON": cell.stateImage.image = #imageLiteral(resourceName: "noun_ontario_12781")
            default: cell.stateImage.image = nil
            }
        }
        
        return cell
    }
}
