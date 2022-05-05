//
//  AddAccountTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 04/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import OAuthSwift
import SVProgressHUD
import Flurry_iOS_SDK

class AddAccountView: UIView {
    
    @IBOutlet var button: UIButton!
    var tableView: UITableView!
    var navigationController: UINavigationController!
    var type = Service.All
    
    override func awakeFromNib() {
        super.awakeFromNib()
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.Black)
        SVProgressHUD.setForegroundColor(tintColour)
    }
    
    @IBAction func authFacebook() {
        SVProgressHUD.show()
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
            "user_friends",
            "user_about_me",
            "read_stream",
            "read_mailbox",
            "publish_actions",
            "manage_pages",
            "user_videos",
            "user_photos",
            "user_location",
            "publish_pages"
        ]
        var scope = ""
        for permission in permissions {
            scope += "\(permission),"
        }
        let url = NSURL(string: "fb\(id)://authorize/")!
        oauth.authorize_url_handler = OAuthWebViewController(nav: self.navigationController)
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
                self.tableView.reloadData()
                self.navigationController.popToRootViewControllerAnimated(true)
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
        oauth.authorize_url_handler = OAuthWebViewController(nav: self.navigationController)
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
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
                Flurry.logEvent("Log In", withParameters: ["User" : "@\(user.username!)", "Type" : "Twitter"])
                let alert = UIAlertController(title: "Follow @BCGray00", message: "Would you like to follow @BCGray00 on Twitter for updates on SoFlow?", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "No", style: .Destructive, handler: {
                    (action) -> Void in
                    self.navigationController.popToRootViewControllerAnimated(true)
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
                        self.navigationController.popToRootViewControllerAnimated(true)
                    }, failure: {
                        (error) -> Void in
                        SVProgressHUD.dismiss()
                        Utility.handleError(error, message: "Error Following @BCGray00")
                        self.navigationController.popToRootViewControllerAnimated(true)
                    })
                }))
                self.navigationController.presentViewController(alert, animated: true, completion: nil)
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
        oauth.authorize_url_handler = OAuthWebViewController(nav: self.navigationController)
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
                self.tableView.reloadData()
                self.navigationController.popToRootViewControllerAnimated(true)
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
        oauth.authorize_url_handler = OAuthWebViewController(nav: self.navigationController)
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
                self.tableView.reloadData()
                self.navigationController.popToRootViewControllerAnimated(true)
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
        oauth.authorize_url_handler = OAuthWebViewController(nav: self.navigationController)
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
                self.tableView.reloadData()
                self.navigationController.popToRootViewControllerAnimated(true)
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
