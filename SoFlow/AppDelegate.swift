//
//  AppDelegate.swift
//  SoFlow
//
//  Created by Ben Gray on 02/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import OAuthSwift
import SDWebImage
import AVFoundation
import Fabric
import Crashlytics
import Flurry_iOS_SDK
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        Fabric.with([Crashlytics.self])
        Flurry.startSession("FFCNQV5DDBDYXTWS5GPK")
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = UIColor.whiteColor()
        self.window!.makeKeyAndVisible()
        self.window!.tintColor = tintColour
        Utility.findUsers()
        SDImageCache.sharedImageCache().clearDisk()
        _ = (try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback))
        _ = (try? AVAudioSession.sharedInstance().setActive(true))
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        let tabBarController = UITabBarController()
        tabBarController.delegate = self
        tabBarController.tabBar.translucent = false
        tabBarController.tabBar.barTintColor = UIColor.whiteColor()
        for (i, tab) in tabs.enumerate() {
            var viewController: UIViewController!
            switch i {
            case 0:
                viewController = HomeSwipeViewController()
            case 1:
                viewController = TrendingTableViewController()
            default:
                viewController = AccountsTableViewController()
            }
            let navigationController = UINavigationController(rootViewController: viewController)
            if i == 0 {
                navigationController.navigationBarHidden = true
            }
            navigationController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: tab + " 30px"), tag: i)
            navigationController.tabBarItem.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
            navigationController.navigationBar.translucent = false
            tabBarController.addChildViewController(navigationController)
        }
        if currentSignedInUsers.count == 0 {
            tabBarController.selectedIndex = tabs.count - 1
        }
        Flurry.logAllPageViewsForTarget(tabBarController)
        self.window!.rootViewController = tabBarController
        if #available(iOS 9.0, *) {
            if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey]as? UIApplicationShortcutItem {
                handleShortcut(shortcutItem)
                return false
            }
        }
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if url.host == "oauth1-callback" {
            OAuth1Swift.handleOpenURL(url)
            return true
        } else if url.host == "oauth2-callback" {
            OAuth2Swift.handleOpenURL(url)
            return true
        }
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication!, annotation: annotation)
    }
    
    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    @available(iOS 9.0, *)
    private func handleShortcut(shortcutItem: UIApplicationShortcutItem) -> Bool {
        let tabBarController = self.window!.rootViewController! as! UITabBarController
        if shortcutItem.type == "com.graypfruit.so-flow.Search" {
            tabBarController.selectedIndex = 1
            let nav = tabBarController.selectedViewController! as! UINavigationController
            let search = nav.viewControllers.first as! TrendingTableViewController
            search.searchBar.becomeFirstResponder()
        }
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        let navigationController = tabBarController.selectedViewController! as! UINavigationController
        if navigationController != viewController {
            if tabBarController.selectedIndex == tabs.count - 1 {
                if currentSignedInUsers.count == 0 {
                    let alert = UIAlertController(title: "No Accounts", message: "Before you can use SoFlow, you must sign in with at least one account.\rSelect a service to log in", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
                    navigationController.visibleViewController!.presentViewController(alert, animated: true, completion: nil)
                    return false
                }
            }
            return true
        } else {
            if tabBarController.selectedIndex == tabs.count - 1 {
                if currentSignedInUsers.count == 0 {
                    return false
                }
            } else if tabBarController.selectedIndex == 0 {
                let homeSwipeController = viewController.childViewControllers.first! as! HomeSwipeViewController
                let nav = homeSwipeController.viewControllers[homeSwipeController.index] as! UINavigationController
                if let tableViewcontroller = nav.visibleViewController as? UITableViewController {
                    if tableViewcontroller.tableView.contentOffset.y != 0 {
                        tableViewcontroller.tableView.setContentOffset(CGPointZero, animated: true)
                        return false
                    }
                }
                if nav.visibleViewController! != nav.viewControllers.first! {
                    nav.popToRootViewControllerAnimated(true)
                    return false
                }
                return false
            }
            if let tableViewcontroller = navigationController.visibleViewController as? UITableViewController {
                if tableViewcontroller.tableView.contentOffset.y != 0 {
                    tableViewcontroller.tableView.setContentOffset(CGPointZero, animated: true)
                    return false
                }
            }
            for viewController in navigationController.viewControllers {
                if let _ = viewController as? ComposeTableViewController {
                    return false
                }
            }
            if let tableViewController = navigationController.viewControllers.first! as? UITableViewController {
                if tableViewController.tableView.numberOfRowsInSection(0) > 0 {
                    tableViewController.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true)
                }
            }
        }
        return true
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        let navigationController = viewController as! UINavigationController
        if let _ = navigationController.viewControllers.first! as? HomeSwipeViewController {
            UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
        } else {
            UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
        }
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        for user in currentSignedInUsers {
            Utility.saveSignedInUser(user)
        }
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        Utility.findUsers()
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if event != nil {
            if event!.type == UIEventType.RemoteControl {
                if currentAudioUrl.relativeString != nil {
                    if event!.subtype == .RemoteControlPlay {
                        audioPlayer.play()
                    } else if event!.subtype == UIEventSubtype.RemoteControlPause {
                        audioPlayer.pause()
                    } else if event!.subtype == .RemoteControlPreviousTrack {
                        audioPlayer.currentTime = 0
                    }
                }
            }
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }
    
    func applicationWillTerminate(application: UIApplication) {

    }
    
    
}

