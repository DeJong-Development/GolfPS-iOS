//
//  BadgesViewController.swift
//  GolfPS
//
//  Created by Greg DeJong on 10/30/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import UIKit

class BadgesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var badgeCollectionView: UICollectionView!
    
    var badges:[Badge] = [Badge]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.badgeCollectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        badges = AppSingleton.shared.me.badges

        //see badge collection controller extension
        self.badgeCollectionView.delegate = self
        self.badgeCollectionView.dataSource = self
    }
    
    @IBAction func clickBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionView == self.badgeCollectionView) {
            return self.badges.count
        }
        return 0
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 150)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (collectionView == self.badgeCollectionView) {
            return getBadgeCell(at: indexPath)
        }
        fatalError("unknown cell type")
    }
    
    private func getBadgeCell(at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = self.badgeCollectionView.dequeueReusableCell(withReuseIdentifier: "BBV", for: indexPath) as? BadgeBlockCollectionViewCell else {
            fatalError("The dequeued cell is not an instance of BadgeBlockCollectionViewCell")
        }
        
        cell.badge = badges[indexPath.row]
        
        cell.backgroundColor = nil
        cell.layer.backgroundColor = nil
        
        return cell
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? BadgeDetailViewController {
            if let badgeCell = sender as? BadgeBlockCollectionViewCell {
                vc.badge = badgeCell.badge
            }
        }
    }
}
