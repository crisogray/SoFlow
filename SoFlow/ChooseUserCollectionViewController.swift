//
//  ChooseUserCollectionViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 16/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class ChooseUserCollectionViewController: UICollectionViewController {
    
    var users = [SignedInUser]()
    let widthHeight = (w - 2) / 2
    
    convenience init(title: String) {
        self.init()
        Utility.findUsers()
        self.title = title
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSizeMake(widthHeight, widthHeight)
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        self.collectionView = UICollectionView(frame: UIScreen.mainScreen().bounds, collectionViewLayout: layout)
        self.collectionView!.backgroundColor = UIColor.groupTableViewBackgroundColor()
        self.collectionView!.registerClass(UserCollectionViewCell.self, forCellWithReuseIdentifier: "UserCell")
        self.collectionView!.registerNib(UINib(nibName: "UserCollectionViewCell", bundle: NSBundle.mainBundle()), forCellWithReuseIdentifier: "UserCell")
        self.collectionView!.allowsMultipleSelection = true
        for user in currentSignedInUsers {
            if user.clientUser.type != .SoundCloud {
                self.users.append(user)
            }
        }
    }
    
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.users.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UserCell", forIndexPath: indexPath) as! UserCollectionViewCell
        cell.setUser(self.users[indexPath.row])
        return cell
    }
    
    func forward() {
        if self.collectionView!.indexPathsForSelectedItems() != nil {
            var indexPaths = self.collectionView!.indexPathsForSelectedItems()!
            indexPaths.sortInPlace({
                (indexPath1, indexPath2) -> Bool in
                return indexPath1.row < indexPath2.row
            })
            var url: String!
            var futurePosts = [FuturePost]()
            for indexPath in indexPaths {
                let cell = self.collectionView!.cellForItemAtIndexPath(indexPath)! as! UserCollectionViewCell
                switch cell.signedInUser.clientUser.type {
                case .Facebook:
                    url = Facebook["base_url"]! + "me/feed"
                case .Twitter:
                    url = Twitter["base_url"]! + "statuses/update.json"
                case .Tumblr:
                    url = Tumblr["base_url"]! + "blog/\(cell.signedInUser.clientUser.name!).tumblr.com/post"
                default:
                    url = ""
                }
                let futurePost = FuturePost(signedInUser: cell.signedInUser, type: .Post, destinationUrl: url, maxImages: 10, location: true, inReplyToPost: nil)
                futurePosts.append(futurePost)
            }
            let composeViewController = ComposeTableViewController(futurePosts: futurePosts, postCell: nil)
            self.navigationController!.pushViewController(composeViewController, animated: true)
        }

    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let view = UIView(frame: CGRectMake(0, 0, widthHeight, widthHeight))
        view.backgroundColor = tintColour
        view.alpha = 0.8
        let cell = collectionView.cellForItemAtIndexPath(indexPath)! as! UserCollectionViewCell
        cell.addSubview(view)
        cell.sendSubviewToBack(view)
        cell.selectCell()
        if self.navigationItem.rightBarButtonItem == nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Forward 24px"), style: .Plain, target: self, action: "forward")
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)! as! UserCollectionViewCell
        for view in cell.subviews {
            if view.alpha < 1 {
                view.removeFromSuperview()
            }
        }
        cell.deselectCell()
        if self.collectionView!.indexPathsForSelectedItems() == nil {
            self.navigationItem.rightBarButtonItem = nil
        } else if self.collectionView!.indexPathsForSelectedItems()!.isEmpty {
            self.navigationItem.rightBarButtonItem = nil
        }
        
    }
    
}
