//
//  OAuthWebViewController.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 2/11/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation
import SVProgressHUD

#if os(iOS)
    import UIKit
    public typealias OAuthViewController = UIViewController
#elseif os(OSX)
    import AppKit
    public typealias OAuthViewController = NSViewController
#endif

public class OAuthWebViewController: OAuthViewController, OAuthSwiftURLHandlerType, UIWebViewDelegate {
    
    public var targetURL : NSURL = NSURL()
    public var webView : UIWebView = UIWebView()
    public var nav: UINavigationController!
    
    public convenience init(nav: UINavigationController) {
        self.init()
        SVProgressHUD.dismiss()
        self.nav = nav
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Back 24px"), style: .Plain, target: self, action: "back")
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = .Gray
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        self.navigationItem.titleView = activityIndicator
    }
    
    public func handle(url: NSURL){
        #if os(iOS)
            self.targetURL = url
            self.nav.pushViewController(self, animated: true)
        #elseif os(OSX)
            if let p = self.parentViewController {
                p.presentViewControllerAsModalWindow(self)
            } else if let window = self.view.window {
                window.makeKeyAndOrderFront(nil)
            }
        #endif
    }

    public func dismissWebViewController() {
        #if os(iOS)
            self.back()
            SVProgressHUD.show()
        #elseif os(OSX)
            if let p = self.presentingViewController {
                self.dismissController(nil)
                if let p = self.parentViewController {
                    self.removeFromParentViewController()
                }
            }
            else if let window = self.view.window {
                window.performClose(nil)
            }
        #endif
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.webView = UIWebView()
        NSURLCache.sharedURLCache().removeAllCachedResponses()
        self.webView.frame.size = self.view.frame.size
        self.webView.frame.size.height -= self.nav.navigationBar.frame.height + self.tabBarController!.tabBar.frame.height + 20
        self.webView.scrollView.contentSize = self.webView.frame.size
        self.webView.scalesPageToFit = true
        self.webView.delegate = self
        self.view.addSubview(self.webView)
        self.loadAddressURL()
    }
    
    func loadAddressURL() {
        if NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies != nil {
            for cookie in NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies! {
                NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie)
            }
        }
        let req = NSURLRequest(URL: self.targetURL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
        self.webView.loadRequest(req)
    }
    
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.URL where (url.scheme == "soflow") || (url.scheme == "fb778085632284419") {
            self.dismissWebViewController()
        }
        return true
    }
    
    public func webViewDidFinishLoad(webView: UIWebView) {
        self.navigationItem.titleView = nil
        self.title = webView.stringByEvaluatingJavaScriptFromString("document.title")
    }
    
}