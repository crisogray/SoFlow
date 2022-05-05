//
//  HomeTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 01/07/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import Crashlytics

let separatorColour = UIColor(red: 0.783922, green: 0.780392, blue: 0.8, alpha: 1)

class HomeTableViewController: PostsTableViewController {
    
    var postsViewControllers: [UIViewController]!
    var callback: (() -> Void)!
    
    convenience init(title: String, viewControllers: [UIViewController], callback: () -> Void) {
        var urls = [String]()
        var params = [Dictionary<String, AnyObject>]()
        Utility.getUrlsForHomeTableViewController(&urls, params: &params)
        print(params)
        self.init(urls: urls, params: params, signedInUsers: currentSignedInUsers, title: title, style: .Plain) {
            (posts: [Post], index: Int) -> Void in
            let navigationController = viewControllers[index] as! UINavigationController
            (navigationController.viewControllers.first! as! PostsTableViewController).posts = posts
            (navigationController.viewControllers.first! as! PostsTableViewController).sortAndAddPosts()
        }
        self.callback = callback
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Compose 24px"), style: .Plain, target: self, action: "compose")
    }
    
    override func sortAndAddPosts() {
        super.sortAndAddPosts()
        self.callback()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        /*if prevCount != currentSignedInUsers.count {
            prevCount = currentSignedInUsers.count
            var urls = [String]()
            var params = [Dictionary<String, AnyObject>]()
            Utility.getUrlsForHomeTableViewController(&urls, params: &params)
            self.signedInUsers = currentSignedInUsers
            self.urls = urls
            self.params = params
            self.refreshDate = NSDate(timeIntervalSinceNow: -80)
            self.loading = true
            self.tableView.reloadData()
            self.getUrls()
        }*/
    }
    
    func compose() {
        let composeViewController = ChooseUserCollectionViewController(title: "Choose Users")
        self.pushViewController(composeViewController)
    }
    
}
