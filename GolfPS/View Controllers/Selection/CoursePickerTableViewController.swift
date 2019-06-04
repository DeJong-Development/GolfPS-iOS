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
        
        //cell style
        cell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        cell.contentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        cell.courseNameLabel.textColor = UIColor.black
        
        if (courseList.count == 0) {
            //do nothing - this is a placeholder cell
            cell.courseNameLabel.text = "NO COURSES FOUND!"
            cell.courseStateLabel.text = ""
            cell.courseNameLabel.textColor = UIColor.red
        } else {
            cell.courseNameLabel.text = courseList[indexPath.row].name;
            cell.courseStateLabel.text = courseList[indexPath.row].state.uppercased()
        }
        
        if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            cell.separatorInset = .zero
        }
        
        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins))  {
            cell.preservesSuperviewLayoutMargins = false
        }
        
        if cell.responds(to: #selector(setter: UIView.layoutMargins))  {
            cell.layoutMargins = .zero
        }
        
        return cell
    }
}
