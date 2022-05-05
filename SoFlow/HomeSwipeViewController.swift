//
//  HomeSwipeViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 19/11/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit
import EZSwipeController

class HomeSwipeViewController: EZSwipeController {

    var viewControllers: [UIViewController]!
    var index = 0
    
    override func setupView() {
        datasource = self
    }
    
    func getViewControllers() {
        var viewControllers = [UIViewController]()
        var urls = [String]()
        var params = [Dictionary<String, AnyObject>]()
        Utility.getUrlsForHomeTableViewController(&urls, params: &params)
        print(urls)
        print(params)
        for (i, url) in urls.enumerate() {
            let postsViewController = PostsTableViewController(urls: [url], params: [params[i]], signedInUsers: [currentSignedInUsers[i]], title: currentSignedInUsers[i].clientUser.type.rawValue)
            let navigationController = UINavigationController(rootViewController: postsViewController)
            navigationController.navigationBar.tintColor = UIColor.whiteColor()
            navigationController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
            let titleView = NSBundle.mainBundle().loadNibNamed("TitleView", owner: self, options: nil)[0] as! TitleView
            titleView.setTitle(currentSignedInUsers[i].clientUser.type.rawValue, index: UInt(i + 1), total: UInt(urls.count + 1), dark: false)
            postsViewController.navigationItem.titleView = titleView
            postsViewController.navigationController?.navigationBar.barTintColor = colours[currentSignedInUsers[i].clientUser.type]
            postsViewController.navigationController?.navigationBar.translucent = false
            postsViewController.firstLoad = true
            viewControllers.append(navigationController)
        }
        let homeViewController = HomeTableViewController(title: "Home", viewControllers: viewControllers) {}
        let navigationController = UINavigationController(rootViewController: homeViewController)
        let titleView = NSBundle.mainBundle().loadNibNamed("TitleView", owner: self, options: nil)[0] as! TitleView
        titleView.setTitle("Timeline", index: 0, total: UInt(homeViewController.urls.count + 1), dark: true)
        homeViewController.navigationItem.titleView = titleView
        homeViewController.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        homeViewController.navigationController?.navigationBar.translucent = false
        self.viewControllers = viewControllers
        self.viewControllers.insert(navigationController, atIndex: 0)
        
    }
    
    override func loadView() {
        super.loadView()
        (self.pageViewController.view.subviews.first as! UIScrollView).scrollsToTop = false
        self.view.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        if self.index == 0 {
            UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
        } else {
            UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if prevCount != currentSignedInUsers.count {
            prevCount = currentSignedInUsers.count
            //self.tabBarController!.viewControllers!.first! = HomeSwipeViewController()
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        self.index = self.viewControllers.indexOf(pendingViewControllers.first!.childViewControllers.first!)!
    }
    
    override func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if self.index == 0 {
                UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
            } else {
                UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
            }
        }
    }
    
}

extension HomeSwipeViewController: EZSwipeControllerDataSource {
    
    func viewControllerData() -> [UIViewController] {
        self.getViewControllers()
        return self.viewControllers
    }
    
}
