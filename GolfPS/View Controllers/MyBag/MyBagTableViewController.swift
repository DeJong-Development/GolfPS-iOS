//
//  CoursePickerTableViewController.swift
//  Golf Ace
//
//  Created by Greg DeJong on 4/20/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import UIKit


class MyBagTableViewController: UITableViewController {
    
    final let cellIdentifier = "ClubTableCell"
    let clubTools:ClubTools = ClubTools();
    
    override func viewWillLayoutSubviews() {
        self.tableView.layer.cornerRadius = 6
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of clubs in the bag except the putter
        return 13
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ClubTableViewCell else {
            fatalError("The dequeued cell is not an instance of \(cellIdentifier).")
        }
        
        let clubNumber:Int = indexPath.row + 1;
        let club:Club = Club(number: clubNumber)
        cell.clubName.text = club.name
        cell.clubDistance.text = String(club.distance)
        
        cell.clubName.tag = clubNumber;
        cell.clubDistance.tag = clubNumber;
        
        cell.clubName.addTarget(self, action: #selector(nameChanged(textField:)), for: .editingChanged)
        cell.clubDistance.addTarget(self, action: #selector(distanceChanged(textField:)), for: .editingChanged)
        
        cell.clubName.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)
        cell.clubDistance.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)

        //cell style
//        cell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
//        cell.contentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
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
    
    //connected via cell delegate
    @objc func nameChanged(textField: UITextField) {
        let clubNum = textField.tag;
        if let clubName = textField.text {
            let cleanClubName = clubName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if (cleanClubName != "") {
                var club = Club(number: clubNum)
                club.name = cleanClubName
            }
        }
    }
    @objc func distanceChanged(textField: UITextField) {
        let clubNum = textField.tag;
        if let clubDistance = textField.text {
            if let clubDistanceNum = Int(clubDistance) {
                var club = Club(number: clubNum)
                club.distance = clubDistanceNum
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
