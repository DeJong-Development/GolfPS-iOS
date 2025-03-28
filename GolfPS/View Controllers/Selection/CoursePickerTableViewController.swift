//
//  CoursePickerTableViewController.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/20/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit

protocol CoursePickerDelegate:AnyObject {
    func refreshCourseList()
    func goToCourse(_ course:Course)
}

class CoursePickerTableViewController: UITableViewController {
    
    private final let cellIdentifier = "GCTableCell"
    weak var delegate:CoursePickerDelegate?
    
    private var isLoadingCourses:Bool = true
    
    internal var courseList:[Course] = [Course]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        let attrs: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor : UIColor.text,
        ]
        refreshControl!.attributedTitle = NSAttributedString(string: "Updating...", attributes: attrs)
        refreshControl!.addTarget(self, action: #selector(refreshCourses), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        
        self.tableView.layer.cornerRadius = 6
        self.tableView.tableFooterView = UIView()
    }
    
    @objc private func refreshCourses() {
        delegate?.refreshCourseList()
    }
    internal func endRefresh() {
        self.isLoadingCourses = false
        self.refreshControl?.endRefreshing()
    }
    internal func deselectRows() {
        for row in 0..<tableView.numberOfRows(inSection: 0) {
            self.tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: false)
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, courseList.count)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (tableView.cellForRow(at: indexPath) as? CourseTableViewCell) != nil else {
            fatalError("selected cell is not a course cell")
        }
        
        guard (courseList.count > 0) else {
            //do nothing - this is a placeholder cell
            return
        }
        
        let course:Course = courseList[indexPath.row]
        
        AnalyticsLogger.selectCourse(course)
        
        delegate?.goToCourse(course)
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CourseTableViewCell else {
            fatalError("The dequeued cell is not an instance of GCTableCell.")
        }
        
        guard (courseList.count > 0) else {
            if self.isLoadingCourses {
                cell.courseNameLabel.text = ""
                cell.courseStateLabel.text = ""
            } else {
                //do nothing - this is a placeholder cell
                cell.courseNameLabel.text = "NO COURSES FOUND!"
                cell.courseStateLabel.text = ""
                cell.stateImage.image = nil
                cell.courseNameLabel.textColor = UIColor.red
            }
            cell.ambassadorImage.isHidden = true
            return cell
        }
        
        let golfCourse = courseList[indexPath.row]
        
        cell.courseNameLabel.textColor = .text
        cell.courseNameLabel.text = golfCourse.name
        
        let stateInitials = golfCourse.state.uppercased()
        cell.courseStateLabel.text = stateInitials
        
        cell.ambassadorImage.isHidden = !AppSingleton.shared.me.ambassadorCourses.contains(golfCourse.id)
        
        switch stateInitials {
        case "AZ": cell.stateImage.image = #imageLiteral(resourceName: "noun-arizona-3402606")
        case "CA": cell.stateImage.image = #imageLiteral(resourceName: "noun_California_3180613")
        case "CO": cell.stateImage.image = #imageLiteral(resourceName: "noun-colorado-3402624")
        case "CT": cell.stateImage.image = #imageLiteral(resourceName: "noun-connecticut-3402617")
        case "FL": cell.stateImage.image = #imageLiteral(resourceName: "noun_Florida_3180625")
        case "HI": cell.stateImage.image = #imageLiteral(resourceName: "noun-hawaii-3402586")
        case "IL": cell.stateImage.image = #imageLiteral(resourceName: "noun_Illinois_3180635")
        case "KY": cell.stateImage.image = #imageLiteral(resourceName: "noun_Kentucky_3180628")
        case "MI": cell.stateImage.image = #imageLiteral(resourceName: "noun_Michigan_3180612")
        case "MD": cell.stateImage.image = #imageLiteral(resourceName: "noun-maryland-3402588")
        case "MN": cell.stateImage.image = #imageLiteral(resourceName: "noun-minnesota-3402595")
        case "NC": cell.stateImage.image = #imageLiteral(resourceName: "noun_North Carolina_3180579")
        case "OH": cell.stateImage.image = #imageLiteral(resourceName: "noun_Ohio_3180618")
        case "OK": cell.stateImage.image = #imageLiteral(resourceName: "noun-oklahoma-3402608")
        case "SC": cell.stateImage.image = #imageLiteral(resourceName: "noun-south-carolina-3402621")
        case "TN": cell.stateImage.image = #imageLiteral(resourceName: "noun_Tennessee_3180631")
        case "TX": cell.stateImage.image = #imageLiteral(resourceName: "noun-texas-3402614")
        case "UT": cell.stateImage.image = #imageLiteral(resourceName: "noun_Utah_3180614")
        case "WI": cell.stateImage.image = #imageLiteral(resourceName: "noun-wisconsin-3402603")
            
        case "UK": cell.stateImage.image = #imageLiteral(resourceName: "noun_United Kingdom_258578")
        case "QC": cell.stateImage.image = #imageLiteral(resourceName: "noun_Quebec_12783")
        case "ON": cell.stateImage.image = #imageLiteral(resourceName: "noun_ontario_12781")
        default: cell.stateImage.image = nil
        }
        
        return cell
    }
}
