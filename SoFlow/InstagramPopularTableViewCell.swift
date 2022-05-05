//
//  InstagramPopularTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 29/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class InstagramPopularTableViewCell: UITableViewCell, UICollectionViewDataSource {

    @IBOutlet var mainView: UIView!
    var collectionView: UICollectionView!
    let widthHeight = (w - 2) / 2
    var posts = [Post]()
    var del: CellDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.userInteractionEnabled = false
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSizeMake(self.widthHeight, self.widthHeight)
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        self.collectionView = UICollectionView(frame: CGRectMake(0, 0, w, (w / 2) * 2), collectionViewLayout: layout)
        self.collectionView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        self.collectionView.scrollEnabled = false
        self.collectionView.registerClass(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        self.collectionView.registerNib(UINib(nibName: "PhotoCollectionViewCell", bundle: NSBundle.mainBundle()), forCellWithReuseIdentifier: "PhotoCell")
        self.collectionView.dataSource = self
        self.mainView.addSubview(self.collectionView)
    }
    
    func setPosts(posts: [Post]) {
        self.posts = posts
        self.collectionView.reloadData()
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.posts.count >= 4 {
            return 4
        } else {
            return self.posts.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        cell.setPost(self.posts[indexPath.row])
        cell.del = self.del
        return cell
    }

}
