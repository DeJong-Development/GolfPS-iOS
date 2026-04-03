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
    private enum CourseSectionKind {
        case ambassador
        case nearby
        case visited
        case searchResults
    }
    
    private struct CourseSection {
        let kind: CourseSectionKind
        let title: String
        let courses: [Course]
        let emptyMessage: String
    }
    
    private final class CourseSectionHeaderView: UITableViewHeaderFooterView {
        static let reuseIdentifier = "CourseSectionHeaderView"
        
        private let titleLabel = UILabel()
        
        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            
            contentView.backgroundColor = .secondarySystemBackground
            
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.font = UIFont(name: "MarkerFelt-Thin", size: 17) ?? UIFont.preferredFont(forTextStyle: .headline)
            titleLabel.textColor = .text
            titleLabel.numberOfLines = 1
            
            contentView.addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func configure(title: String) {
            titleLabel.text = title.uppercased()
        }
    }
    
    private final let cellIdentifier = "GCTableCell"
    weak var delegate:CoursePickerDelegate?
    
    private var isLoadingCourses:Bool = true
    
    internal var ambassadorCourses:[Course] = [Course]() {
        didSet {
            reloadTable()
        }
    }
    internal var visitedCourses:[Course] = [Course]() {
        didSet {
            reloadTable()
        }
    }
    internal var nearbyCourses:[Course] = [Course]() {
        didSet {
            reloadTable()
        }
    }
    internal var courseDistances:[String:String] = [:] {
        didSet {
            reloadTable()
        }
    }
    internal var searchResults:[Course] = [Course]() {
        didSet {
            reloadTable()
        }
    }
    internal var isShowingSearchResults:Bool = false {
        didSet {
            reloadTable()
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
        self.tableView.sectionHeaderTopPadding = 0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 58
        self.tableView.register(CourseSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: CourseSectionHeaderView.reuseIdentifier)
    }
    
    private var sections:[CourseSection] {
        if isShowingSearchResults {
            return [
                CourseSection(kind: .searchResults, title: "Search Results", courses: searchResults, emptyMessage: "No matching courses found.")
            ]
        }

        var availableSections:[CourseSection] = []
        if !AppSingleton.shared.me.ambassadorCourses.isEmpty {
            availableSections.append(
                CourseSection(kind: .ambassador, title: "Ambassador", courses: ambassadorCourses, emptyMessage: "No ambassador courses available.")
            )
        }
        availableSections.append(
            CourseSection(kind: .nearby, title: "Nearby", courses: nearbyCourses, emptyMessage: "No nearby courses found.")
        )
        availableSections.append(
            CourseSection(kind: .visited, title: "Visited", courses: visitedCourses, emptyMessage: "No visited courses available.")
        )
        return availableSections
    }
    
    private func reloadTable() {
        guard isViewLoaded else {
            return
        }
        tableView.reloadData()
    }
    
    @objc private func refreshCourses() {
        delegate?.refreshCourseList()
    }
    internal func endRefresh() {
        self.isLoadingCourses = false
        self.refreshControl?.endRefreshing()
    }
    internal func deselectRows() {
        for section in 0..<tableView.numberOfSections {
            for row in 0..<tableView.numberOfRows(inSection: section) {
                self.tableView.deselectRow(at: IndexPath(row: row, section: section), animated: false)
            }
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, sections[section].courses.count)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 38
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 38
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: CourseSectionHeaderView.reuseIdentifier) as? CourseSectionHeaderView else {
            return nil
        }
        
        headerView.configure(title: sections[section].title)
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (tableView.cellForRow(at: indexPath) as? CourseTableViewCell) != nil else {
            fatalError("selected cell is not a course cell")
        }
        
        let section = sections[indexPath.section]
        guard section.courses.count > 0 else {
            //do nothing - this is a placeholder cell
            return
        }
        
        let course:Course = section.courses[indexPath.row]
        
        AnalyticsLogger.selectCourse(course)
        
        delegate?.goToCourse(course)
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CourseTableViewCell else {
            fatalError("The dequeued cell is not an instance of GCTableCell.")
        }
        
        let section = sections[indexPath.section]
        guard section.courses.count > 0 else {
            if self.isLoadingCourses {
                cell.courseNameLabel.text = ""
                cell.courseDistanceLabel.text = ""
                cell.courseStateLabel.text = ""
            } else {
                cell.courseNameLabel.text = section.emptyMessage.uppercased()
                cell.courseDistanceLabel.text = ""
                cell.courseStateLabel.text = ""
                cell.stateImage.image = nil
                cell.courseNameLabel.textColor = UIColor.red
            }
            cell.courseDistanceLabel.isHidden = true
            cell.ambassadorImage.isHidden = true
            return cell
        }
        
        let golfCourse = section.courses[indexPath.row]
        
        cell.courseNameLabel.textColor = .text
        cell.courseNameLabel.text = golfCourse.name
        cell.courseDistanceLabel.textColor = .secondaryLabel
        
        let stateInitials = golfCourse.state.uppercased()
        cell.courseStateLabel.text = stateInitials
        if section.kind != .ambassador {
            cell.courseDistanceLabel.text = courseDistances[golfCourse.id] ?? fallbackDistanceText
            cell.courseDistanceLabel.isHidden = false
        } else {
            cell.courseDistanceLabel.text = nil
            cell.courseDistanceLabel.isHidden = true
        }
        
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
    
    private var fallbackDistanceText: String {
        return AppSingleton.shared.metric ? "- km" : "- mi"
    }
}
