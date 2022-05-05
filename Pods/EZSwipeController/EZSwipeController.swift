//
//  EZSwipeController.swift
//  EZSwipeController
//
//  Created by Goktug Yilmaz on 24/10/15.
//  Copyright © 2015 Goktug Yilmaz. All rights reserved.
//
import UIKit

@objc public protocol EZSwipeControllerDataSource {
    func viewControllerData() -> [UIViewController]
    optional func indexOfStartingPage() -> Int // Defaults is 0
    optional func titlesForPages() -> [String]
    optional func navigationBarDataForPageIndex(index: Int) -> UINavigationBar
    optional func disableSwipingForLeftButtonAtPageIndex(index: Int) -> Bool
    optional func disableSwipingForRightButtonAtPageIndex(index: Int) -> Bool
    optional func clickedLeftButtonFromPageIndex(index: Int)
    optional func clickedRightButtonFromPageIndex(index: Int)
}

public class EZSwipeController: UIViewController {
    
    public struct Constants {
        public static var Orientation: UIInterfaceOrientation {
            get {
                return UIApplication.sharedApplication().statusBarOrientation
            }
        }
        public static var ScreenWidth: CGFloat {
            get {
                if UIInterfaceOrientationIsPortrait(Orientation) {
                    return UIScreen.mainScreen().bounds.size.width
                } else {
                    return UIScreen.mainScreen().bounds.size.height
                }
            }
        }
        public static var ScreenHeight: CGFloat {
            get {
                if UIInterfaceOrientationIsPortrait(Orientation) {
                    return UIScreen.mainScreen().bounds.size.height
                } else {
                    return UIScreen.mainScreen().bounds.size.width
                }
            }
        }
        public static var StatusBarHeight: CGFloat = 20
        public static var ScreenHeightWithoutStatusBar: CGFloat {
            get {
                if UIInterfaceOrientationIsPortrait(Orientation) {
                    return UIScreen.mainScreen().bounds.size.height - Constants.StatusBarHeight
                } else {
                    return UIScreen.mainScreen().bounds.size.width - Constants.StatusBarHeight
                }
            }
        }
        public static let navigationBarHeight: CGFloat = 64
    }
    
    public var stackNavBars = [UINavigationBar]()
    public var stackVC: [UIViewController]!
    public var stackPageVC: [UIViewController]!
    public var stackStartLocation: Int!
    
    public var bottomNavigationHeight: CGFloat = 0
    public var pageViewController: UIPageViewController!
    public var titleButton: UIButton?
    public var currentStackVC: UIViewController!
    public var datasource: EZSwipeControllerDataSource?
    
    public var navigationBarShouldBeOnBottom = false
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        setupView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViewControllers() {
        stackPageVC = [UIViewController]()
        for index in 0..<stackVC.count {
            let pageVC = UIViewController()
            stackVC[index].view.frame.size.height = Constants.ScreenHeight + self.tabBarController!.tabBar.frame.height
            pageVC.addChildViewController(stackVC[index])
            pageVC.view.addSubview(stackVC[index].view)
            let v = UIView(frame: CGRectMake(0, 64, 0.25, Constants.ScreenHeightWithoutStatusBar))
            v.backgroundColor = UIColor(red: 0.783922, green: 0.780392, blue: 0.8, alpha: 1)
            let v1 = v
            v1.frame.origin.x = Constants.ScreenWidth - 0.25
            pageVC.view.addSubview(v)
            pageVC.view.addSubview(v1)
            pageVC.view.bringSubviewToFront(v)
            pageVC.view.bringSubviewToFront(v1)
            stackVC[index].didMoveToParentViewController(pageVC)
            if !stackNavBars.isEmpty {
                pageVC.view.addSubview(stackNavBars[index])
            }
            stackPageVC.append(pageVC)
        }
        currentStackVC = stackPageVC[stackStartLocation]
    }
    
    private func setupPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([stackPageVC[stackStartLocation]], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        pageViewController.view.frame = CGRect(x: 0, y: 0, width: Constants.ScreenWidth, height: Constants.ScreenHeight)
        pageViewController.view.backgroundColor = UIColor.clearColor()
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMoveToParentViewController(self)
    }
    
    public func setupView() {
        
    }
    
    override public func loadView() {
        super.loadView()
        stackVC = datasource?.viewControllerData()
        stackStartLocation = datasource?.indexOfStartingPage?() ?? 0
        guard stackVC != nil else {
            print("Problem: EZSwipeController needs ViewController Data, please implement EZSwipeControllerDataSource")
            return
        }
        setupViewControllers()
        setupPageViewController()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc private func clickedLeftButton() {
        let currentIndex = stackPageVC.indexOf(currentStackVC)!
        datasource?.clickedLeftButtonFromPageIndex?(currentIndex)
        
        let shouldDisableSwipe = datasource?.disableSwipingForLeftButtonAtPageIndex?(currentIndex) ?? false
        if shouldDisableSwipe {
            return
        }
        
        if currentStackVC == stackPageVC.first {
            return
        }
        currentStackVC = stackPageVC[currentIndex - 1]
        pageViewController.setViewControllers([currentStackVC], direction: UIPageViewControllerNavigationDirection.Reverse, animated: true, completion: nil)
    }
    
    @objc private func clickedRightButton() {
        let currentIndex = stackPageVC.indexOf(currentStackVC)!
        datasource?.clickedRightButtonFromPageIndex?(currentIndex)
        
        let shouldDisableSwipe = datasource?.disableSwipingForRightButtonAtPageIndex?(currentIndex) ?? false
        if shouldDisableSwipe {
            return
        }
        
        if currentStackVC == stackPageVC.last {
            return
        }
        currentStackVC = stackPageVC[currentIndex + 1]
        pageViewController.setViewControllers([currentStackVC], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
    }
    
}

extension EZSwipeController: UIPageViewControllerDataSource {
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if viewController == stackPageVC.first {
            return nil
        }
        return stackPageVC[stackPageVC.indexOf(viewController)! - 1]
    }
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if viewController == stackPageVC.last {
            return nil
        }
        return stackPageVC[stackPageVC.indexOf(viewController)! + 1]
    }
    
}

extension EZSwipeController: UIPageViewControllerDelegate {
    
    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed {
            return
        }
        currentStackVC = stackPageVC[stackPageVC.indexOf(pageViewController.viewControllers!.first!)!]
    }
    
}

