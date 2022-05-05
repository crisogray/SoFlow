//
//  PostsTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 13/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import Foundation

class PostsTableViewController: UITableViewController, CellDelegate {
    
    var signedInUsers: [SignedInUser]!
    var posts = [Post]()
    var newPosts: [Post]?
    var urls: [String]!
    var params: [Dictionary<String, AnyObject>]!
    var refreshDate = NSDate(timeIntervalSinceNow: -80)
    var loading = true
    var firstLoad = false
    var subcallback: ((posts: [Post], index: Int) -> Void)?
    var pageScrollView: UIScrollView?
    
    convenience init(urls: [String], params: [Dictionary<String, AnyObject>], signedInUsers: [SignedInUser], title: String!) {
        self.init(urls: urls, params: params, signedInUsers: signedInUsers, title: title, style: .Plain, subcallback: nil)
    }
    
    convenience init(urls: [String], params: [Dictionary<String, AnyObject>], signedInUsers: [SignedInUser], title: String!, style: UITableViewStyle, subcallback: ((posts: [Post], index: Int) -> Void)?) {
        self.init(style: style)
        self.urls = urls
        self.signedInUsers = signedInUsers
        self.params = params
        self.subcallback = subcallback
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        Utility.registerCells(self.tableView)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.title = title
        self.navigationItem.hidesBackButton = true
        if !tabs.contains(title) && !services.contains(title) {
            self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        }
        self.tableView.allowsMultipleSelection = false
        self.posts = [Post]()
    }
    
    func getUrls() {
        let timeInterval = NSDate().timeIntervalSinceDate(refreshDate)
        if timeInterval > 80 {
            self.refreshDate = NSDate()
            Utility.getPostsFromUrls(self.urls, params: self.params, signedInUsers: self.signedInUsers, callback: {
                (posts) -> Void in
                if posts != nil {
                    if !posts!.isEmpty {
                        self.posts = posts!
                        self.sortAndAddPosts()
                    } else {
                        self.loading = false
                    }
                    if self.refreshControl != nil {
                        self.refreshControl!.endRefreshing()
                    }
                }
            }, title: self.title!, subcallback: self.subcallback)
        } else {
            self.refreshControl?.endRefreshing()
        }
    }
    
    func sortAndAddPosts() {
        if self.refreshControl == nil {
            let rControl = UIRefreshControl()
            rControl.addTarget(self, action: "getUrls", forControlEvents: .ValueChanged)
            self.refreshControl = rControl
        } else {
            self.refreshControl!.endRefreshing()
        }
        self.loading = false
        self.posts.sortInPlace {
            p1, p2 in
            let d1 = p1.date
            let d2 = p2.date
            return d1.compare(d2) == NSComparisonResult.OrderedDescending
        }
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.scrollsToTop = true
        if !self.firstLoad {
            if self.urls.isEmpty {
                self.sortAndAddPosts()
            } else {
                self.getUrls()
            }
            self.firstLoad = true
        }
        self.tableView.contentInset.bottom = Utility.contentInsetsFromAudioPlayer()
        self.tableView.scrollIndicatorInsets.bottom = Utility.contentInsetsFromAudioPlayer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.scrollsToTop = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.tableView.scrollsToTop = false
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.loading {
            return 1
        } else {
            return self.posts.count
        }
    }
    
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if !self.loading {
            let post = self.posts[indexPath.row]
            let cell = Utility.tableViewCellFromPost(posts[indexPath.row], tableView: tableView, indexPath: indexPath, signedInUser: post.signedInUser)!
            cell.del = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath) as! LoadingTableViewCell
            cell.selectionStyle = .None
            cell.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            return cell
        }
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
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !self.loading {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PostTableViewCell {
                if let post = cell.post as? FacebookNotification {
                    if post.objectId != nil {
                        let url = Facebook["base_url"]! + post.objectId!
                        let postViewController = PostTableViewController(url: url, params: FacebookPostParams, signedInUser: cell.signedInUser)
                        self.pushViewController(postViewController)
                    }
                } else {
                    self.tableView.beginUpdates()
                    cell.showDraw()
                    self.tableView.endUpdates()
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if !self.loading {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PostTableViewCell {
                if let _ = cell.post as? FacebookNotification {} else {
                    self.tableView.beginUpdates()
                    cell.retractDraw()
                    self.tableView.endUpdates()
                }
            }
        }
    }
    
    func presentViewController(viewController: UIViewController) {
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if !self.loading {
            //if self.posts != nil {
                if self.posts.count > indexPath.row {
                    if self.posts[indexPath.row].estimatedHeight == nil {
                        let h = Utility.estimatedCellHeightForPost(self.posts[indexPath.row], tableView: self.tableView)
                        return h
                    } else {
                        return self.posts[indexPath.row].estimatedHeight!
                    }
                }
            //}
        }
        return 48
    }

}
