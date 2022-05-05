//
//  AccountsTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 03/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import Social
import Accounts
import OAuthSwift
import SVProgressHUD
import Flurry_iOS_SDK
import FBSDKCoreKit
import FBSDKLoginKit

var prevCount = currentSignedInUsers.count

class AccountsTableViewController: UITableViewController {

    // var users = [String : [SignedInUser]]()
    var users = [String : SignedInUser]()
    var sections = [String]()
    var selectedUser : User!
    var index = 0
    var accountStore = ACAccountStore()
    var firstAppear = true
    
    convenience init() {
        self.init(style: .Plain)
        Utility.registerCells(self.tableView)
        self.title = "Accounts"
        self.tableView.bounces = false
        let layer = CAGradientLayer()
        layer.frame.size = CGSizeMake(w, self.tableView.contentSize.height)
        layer.colors = [UIColor.whiteColor().CGColor, UIColor(red: 0.93, green: 0.93, blue: 0.94, alpha: 1).CGColor]
        self.tableView.layer.insertSublayer(layer, atIndex: 0)
        self.tableView.backgroundColor = UIColor.clearColor()
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.Black)
        SVProgressHUD.setForegroundColor(tintColour)
        self.tableView.layoutMargins = UIEdgeInsetsZero
    }
    
    override func viewWillAppear(animated: Bool) {
        self.updateTable()
        self.tableView.contentInset.bottom = Utility.contentInsetsFromAudioPlayer()
        self.tableView.scrollIndicatorInsets.bottom = Utility.contentInsetsFromAudioPlayer()
    }
    
    func updateTable() {
        prevCount = currentSignedInUsers.count
        Utility.findUsers()
        if prevCount != currentSignedInUsers.count {
            for (i, viewController) in self.tabBarController!.viewControllers!.enumerate() {
                let navigationController = viewController as! UINavigationController
                navigationController.popToRootViewControllerAnimated(true)
                if i == 0 {
                    navigationController.setViewControllers([HomeSwipeViewController()], animated: false)
                } else if i == 1 {
                    navigationController.setViewControllers([TrendingTableViewController()], animated: false)
                }
            }
        }
        self.users = [String : SignedInUser]()
        /*
        self.sections = [String]()
        for u in currentSignedInUsers {
            let section = Utility.stringFromService(u.clientUser.type)
            if !self.sections.contains(section) {
                self.sections.append(section)
            }
            if self.users[section] == nil {
                self.users[section] = [u]
            } else {
                self.users[section]!.append(u)
            }
        }
        */
        for user in currentSignedInUsers {
            self.users[user.clientUser.type.rawValue] = user
        }
        self.tableView.reloadData()
    }
    

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if self.users[services[indexPath.row]] != nil {
            let c = tableView.dequeueReusableCellWithIdentifier("AccountCell", forIndexPath: indexPath) as! AccountTableViewCell
            c.setAccountsViewController(self, user: self.users[services[indexPath.row]]!)
            c.separatorInset = UIEdgeInsets(top: 0, left: w, bottom: 0, right: 0)
            cell = c
        } else {
            let c = tableView.dequeueReusableCellWithIdentifier("AddAccountCell", forIndexPath: indexPath) as! AddAccountTableViewCell
            c.setAccountsViewController(self, s: services[indexPath.row])
            c.separatorInset = UIEdgeInsetsZero
            c.preservesSuperviewLayoutMargins = false
            c.layoutMargins = UIEdgeInsetsZero
            cell = c
        }
        cell.selectionStyle = .None
        cell.tag = indexPath.row
        return cell
    }
    
    func addAccount() {
        let view = NSBundle.mainBundle().loadNibNamed("AddAccountView", owner: self, options: nil)[0] as! AddAccountView
        view.frame = CGRectMake(0, 0, w, w * 1.4)
        view.tableView = tableView
        view.navigationController = self.navigationController!
        let viewController = UIViewController()
        viewController.view = view
        let button = Utility.backButtonForTarget(self)
        viewController.navigationItem.hidesBackButton = true
        viewController.navigationItem.leftBarButtonItem = button
        viewController.title = "Add an Account"
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func back() {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? AccountTableViewCell {
            cell.user!.user = cell.user!.clientUser
            let profileViewController = ProfileTableViewController(user: cell.user!)
            self.navigationController!.pushViewController(profileViewController, animated: true)
        } else {
            let authFunctions = [
                self.authFacebook,
                self.authTwitter,
                self.authInstagram,
                self.authTumblr,
                self.authSoundCloud
            ]
            authFunctions[indexPath.row]()
        }
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 48
    }

    @IBAction func authFacebook() {
        /*SVProgressHUD.show()
        let oauth = OAuth2Swift(
            consumerKey: Facebook["key"]!,
            consumerSecret: Facebook["secret"]!,
            authorizeUrl: "https://www.facebook.com/dialog/oauth",
            accessTokenUrl: "https://graph.facebook.com/v2.3/oauth/access_token",
            responseType: "code"
        )
        let id = Facebook["key"]!
        let permissions = [
            "user_likes",
            "publish_actions",
            "user_videos",
            "user_photos",
        ]
        var scope = ""
        for permission in permissions {
            scope += "\(permission),"
        }
        let url = NSURL(string: "fb\(id)://authorize/")!
        oauth.authorize_url_handler = OAuthWebViewController(nav: self.navigationController!)
        oauth.authorizeWithCallbackURL(url, scope: scope, state: "", params: ["":""], success: {
            (credential, response, params) -> Void in
            let urlString = Facebook["base_url"]! + "me"
            oauth.client.get(urlString, parameters: ["fields" : "name,picture"], success: {
                (data, response) -> Void in
                let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                let user = Utility.facebookUserFromDictionary(json, signedInUser: nil)
                let client = oauth.client
                let signedInUser = SignedInUser(client: client, user: user, clientUser: user)
                Utility.saveSignedInUser(signedInUser)
                self.updateTable()
                self.navigationController!.popToRootViewControllerAnimated(true)
                SVProgressHUD.dismiss()
                Flurry.logEvent("Log In", withParameters: ["User" : user.name!, "Type" : "Facebook"])
                }, failure: {
                    (error) -> Void in
                    SVProgressHUD.dismiss()
                    Utility.handleError(error, message: "Error Authenticating User")
            })
        }){
            (error) -> Void in
            SVProgressHUD.dismiss()
            Utility.handleError(error, message: "Error Authenticating User")
        }*/
        let permissions = [
            "user_likes",
            "user_videos",
            "user_photos",
        ]
        let loginManager = FBSDKLoginManager()
        loginManager.logInWithReadPermissions(permissions, fromViewController: self) {
            (result, error) -> Void in
            if error == nil {
                FBSDKGraphRequest(graphPath: "me", parameters: ["fields" : "name,picture"]).startWithCompletionHandler({
                    (connection, result, error) -> Void in
                    
                    let user = Utility.facebookUserFromDictionary(result as! NSDictionary, signedInUser: nil)
                    let client = OAuthSwiftClient(consumerKey: Facebook["key"]!, consumerSecret: Facebook["secret"]!, accessToken: FBSDKAccessToken.currentAccessToken().tokenString, accessTokenSecret: "")
                    let signedInUser = SignedInUser(client: client, user: user, clientUser: user)
                    Utility.saveSignedInUser(signedInUser)
                    self.updateTable()
                    self.navigationController!.popToRootViewControllerAnimated(true)
                    SVProgressHUD.dismiss()
                    Flurry.logEvent("Log In", withParameters: ["User" : user.name!, "Type" : "Facebook"])
                })
            }
        }
    }
    
    @IBAction func authTwitter() {
        SVProgressHUD.show()
        let oauth = OAuth1Swift(
            consumerKey: Twitter["key"]!,
            consumerSecret: Twitter["secret"]!,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl: "https://api.twitter.com/oauth/authorize",
            accessTokenUrl: "https://api.twitter.com/oauth/access_token"
        )
        let url = NSURL(string: "soflow://oauth1-callback")!
        oauth.authorize_url_handler = OAuthWebViewController(nav: self.navigationController!)
        oauth.authorizeWithCallbackURL(url, success: {
            (credential, response) -> Void in
            let params = ["skip_status" : "1"]
            let urlString = Twitter["base_url"]! + "account/verify_credentials.json"
            oauth.client.get(urlString, parameters: params, success: {
                (data, response) -> Void in
                let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                let user = Utility.twitterUserFromDictionary(json)
                let client = oauth.client
                let signedInUser = SignedInUser(client: client, user: user, clientUser: user)
                Utility.saveSignedInUser(signedInUser)
                self.updateTable()
                SVProgressHUD.dismiss()
                Flurry.logEvent("Log In", withParameters: ["User" : "@\(user.username!)", "Type" : "Twitter"])
                let alert = UIAlertController(title: "Follow @BCGray00", message: "Would you like to follow @BCGray00 on Twitter for updates on SoFlow?", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "No", style: .Destructive, handler: {
                    (action) -> Void in
                    self.navigationController!.popToRootViewControllerAnimated(true)
                }))
                alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: {
                    (action) -> Void in
                    dispatch_async(dispatch_get_main_queue(), {
                        () -> Void in
                        SVProgressHUD.show()
                    })
                    let url = Twitter["base_url"]! + "friendships/create.json"
                    let params = ["user_id" : "562201813", "follow" : "true"]
                    signedInUser.client.post(url, parameters: params, success: {
                        (data, response) -> Void in
                        SVProgressHUD.dismiss()
                        self.navigationController!.popToRootViewControllerAnimated(true)
                        }, failure: {
                            (error) -> Void in
                            SVProgressHUD.dismiss()
                            Utility.handleError(error, message: "Error Following @BCGray00")
                            self.navigationController!.popToRootViewControllerAnimated(true)
                    })
                }))
                self.navigationController!.presentViewController(alert, animated: true, completion: nil)
            }, failure: {
                (error) -> Void in
                SVProgressHUD.dismiss()
                Utility.handleError(error, message: "Error Authenticating User")
            })
        }) {
            (error) -> Void in
            SVProgressHUD.dismiss()
            Utility.handleError(error, message: "Error Authenticating User")
        }
    }
    
    @IBAction func authInstagram() {
        SVProgressHUD.show()
        let oauth = OAuth2Swift(
            consumerKey: Instagram["key"]!,
            consumerSecret: Instagram["secret"]!,
            authorizeUrl: "https://api.instagram.com/oauth/authorize",
            accessTokenUrl: "https://api.instagram.com/oauth/access_token",
            responseType: "code"
        )
        let scope = "likes+comments+relationships"
        let url = NSURL(string: "soflow://oauth2-callback")!
        oauth.authorize_url_handler = OAuthWebViewController(nav: self.navigationController!)
        oauth.authorizeWithCallbackURL(url, scope: scope, state: "", params: Dictionary<String, String>(), success: {
            (credential, response, params) -> Void in
            let urlString = Instagram["base_url"]! + "users/self"
            oauth.client.get(urlString, parameters: Dictionary<String, AnyObject>(), success: {
                (data, response) -> Void in
                let jsonObject = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                let json = jsonObject["data"] as! NSDictionary
                let user = Utility.instagramUserFromDictionary(json)
                let client = oauth.client
                let signedInUser = SignedInUser(client: client, user: user, clientUser: user)
                Utility.saveSignedInUser(signedInUser)
                self.updateTable()
                self.navigationController!.popToRootViewControllerAnimated(true)
                SVProgressHUD.dismiss()
                Flurry.logEvent("Log In", withParameters: ["User" : user.username!, "Type" : "Instagram"])
                }, failure: {
                    (error) -> Void in
                    SVProgressHUD.dismiss()
                    Utility.handleError(error, message: "Error Authenticating User")
            })
            }) {
                (error) -> Void in
                SVProgressHUD.dismiss()
                Utility.handleError(error, message: "Error Authenticating User")
        }
    }
    
    @IBAction func authTumblr() {
        SVProgressHUD.show()
        let oauth = OAuth1Swift(
            consumerKey: Tumblr["key"]!,
            consumerSecret: Tumblr["secret"]!,
            requestTokenUrl: "https://www.tumblr.com/oauth/request_token",
            authorizeUrl: "https://www.tumblr.com/oauth/authorize",
            accessTokenUrl: "https://www.tumblr.com/oauth/access_token"
        )
        oauth.authorize_url_handler = OAuthWebViewController(nav: self.navigationController!)
        oauth.authorizeWithCallbackURL(NSURL(string: "soflow://oauth1-callback")!, success: {
            (credential, response) -> Void in
            SVProgressHUD.show()
            let urlString = Tumblr["base_url"]! + "user/info"
            oauth.client.get(urlString, parameters: Dictionary<String, AnyObject>(), success: {
                (data, response) -> Void in
                SVProgressHUD.show()
                let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                let response = json["response"] as! NSDictionary
                let userDictionary = response["user"] as! NSDictionary
                let user = Utility.tumblrUserFromDictionary(userDictionary, nameString: "name")
                let client = oauth.client
                let signedInUser = SignedInUser(client: client, user: user, clientUser: user)
                Utility.saveSignedInUser(signedInUser)
                self.updateTable()
                self.navigationController!.popToRootViewControllerAnimated(true)
                SVProgressHUD.dismiss()
                Flurry.logEvent("Log In", withParameters: ["User" : user.name!, "Type" : "Tumblr"])
                }, failure: {
                    (error) -> Void in
                    SVProgressHUD.dismiss()
                    Utility.handleError(error, message: "Error Authenticating User")
            })
            }) {
                (error) -> Void in
                SVProgressHUD.dismiss()
                Utility.handleError(error, message: "Error Authenticating User")
        }
    }
    
    @IBAction func authSoundCloud() {
        SVProgressHUD.show()
        let oauth = OAuth2Swift(
            consumerKey: SoundCloud["key"]!,
            consumerSecret: SoundCloud["secret"]!,
            authorizeUrl: "https://soundcloud.com/connect",
            accessTokenUrl: "https://api.soundcloud.com/oauth2/token",
            responseType: "code"
        )
        oauth.authorize_url_handler = OAuthWebViewController(nav: self.navigationController!)
        oauth.authorizeWithCallbackURL(NSURL(string: "soflow://oauth2-callback")!, scope: "", state: "", success: {
            (credential, response, parameters) -> Void in
            let urlString = SoundCloud["base_url"]! + "me"
            oauth.client.get(urlString, parameters: Dictionary<String, AnyObject>(), success: {
                (data, response) -> Void in
                let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                let user = Utility.soundCloudUserFromDictionary(json)
                let client = oauth.client
                let signedInUser = SignedInUser(client: client, user: user, clientUser: user)
                Utility.saveSignedInUser(signedInUser)
                self.updateTable()
                self.navigationController!.popToRootViewControllerAnimated(true)
                SVProgressHUD.dismiss()
                Flurry.logEvent("Log In", withParameters: ["User" : user.username!, "Type" : "SoundCloud"])
                }, failure: {
                    (error) -> Void in
                    SVProgressHUD.dismiss()
                    Utility.handleError(error, message: "Error Authenticating User")
            })
            }) {
                (error) -> Void in
                SVProgressHUD.dismiss()
                Utility.handleError(error, message: "Error Authenticating User")
        }
    }
    
}
