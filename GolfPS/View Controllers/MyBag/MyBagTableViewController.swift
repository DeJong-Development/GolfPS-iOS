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
    private var myBag:Bag = AppSingleton.shared.me.bag
    
    override func viewWillLayoutSubviews() {
        self.tableView.layer.cornerRadius = 6
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
    }
    
    internal func addClub(_ club:Club) {
        myBag.addClub(club)
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of clubs in the bag except the putter
        return myBag.myClubs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ClubTableViewCell else {
            fatalError("The dequeued cell is not an instance of \(cellIdentifier).")
        }
        
        cell.club = myBag.myClubs[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if self.tableView.isEditing {
            return .delete
        }
        return .none
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.myBag.removeClubFromBag(withIndexNumber: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let clubToMove = self.myBag.myClubs[sourceIndexPath.row]
        self.myBag.moveClub(clubToMove, from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
