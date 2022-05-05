//
//  PhotosCollectionViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 16/09/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit


class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, CellDelegate {
    
    var signedInUsers: [SignedInUser]!
    var posts: [Post]!
    var newPosts: [Post]?
    var urls: [String]!
    var params: [Dictionary<String, AnyObject>]!
    var loading = true
    let widthHeight = (w - 4) / 3
    
    convenience init(urls: [String], params: [Dictionary<String, AnyObject>], signedInUsers: [SignedInUser], title: String!, posts: [Post]?) {
        self.init()
        self.urls = urls
        self.signedInUsers = signedInUsers
        self.params = params
        self.title = title
        self.posts = [Post]()
        self.initCollectionView()
        if posts == nil {
            self.getUrls()
        } else {
            if !posts!.isEmpty {
                self.posts = posts!
                self.loading = false
                self.collectionView!.reloadData()
            } else {
                self.getUrls()
            }
        }
    }
    
    func initCollectionView() {
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSizeMake(widthHeight, widthHeight)
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        self.collectionView = UICollectionView(frame: UIScreen.mainScreen().bounds, collectionViewLayout: layout)
        self.collectionView!.bounces = true
        self.collectionView!.backgroundColor = UIColor.groupTableViewBackgroundColor()
        self.collectionView!.registerClass(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        self.collectionView!.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "LoadingView")
        self.collectionView!.registerNib(UINib(nibName: "PhotoCollectionViewCell", bundle: NSBundle.mainBundle()), forCellWithReuseIdentifier: "PhotoCell")
        self.collectionView?.registerNib(UINib(nibName: "LoadingCollectionViewCell", bundle: NSBundle.mainBundle()), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "LoadingView")
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if self.loading {
            return CGSizeMake(w, 44)
        } else {
            return CGSizeZero
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.collectionView!.contentInset.bottom = Utility.contentInsetsFromAudioPlayer()
        self.collectionView!.scrollIndicatorInsets.bottom = Utility.contentInsetsFromAudioPlayer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "LoadingView", forIndexPath: indexPath)
        view.backgroundColor = UIColor.whiteColor()
        return view
    }
    
    func getUrls() {
        Utility.getPostsFromUrls(self.urls, params: self.params, signedInUsers: self.signedInUsers, callback: {
            (posts) -> Void in
            if posts != nil {
                self.posts = posts
                self.loading = false
                self.collectionView!.reloadData()
            }
        }, title: (self.title!), subcallback: nil)
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !self.loading {
            return self.posts.count
        } else {
            return 0
        }
    }
    
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }

    func showImage(image: UIImage, view: UIView) {
        Utility.showImage(image, view: view, viewController: self)
    }
    
    func showUser(user: SignedInUser) {
        let profileViewController = ProfileTableViewController(user: user)
        self.pushViewController(profileViewController)
    }
    
    func showVideo(url: NSURL) {
        Utility.showVideo(url, viewController: self)
    }
    
    func pushViewController(viewController: UIViewController) {
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func presentViewController(viewController: UIViewController) {
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        cell.setPost(self.posts[indexPath.row])
        cell.del = self
        return cell
    }

}
