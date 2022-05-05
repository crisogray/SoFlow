//
//  ProfileTableHeaderView.swift
//  SoFlow
//
//  Created by Ben Gray on 10/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class ProfileTableHeaderView: UIView {

    @IBOutlet var profilePictureView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var usernameLabelHeight: NSLayoutConstraint!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var descriptionLabelHeight: NSLayoutConstraint!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var locationLabelHeight: NSLayoutConstraint!
    @IBOutlet var urlLabel: UILabel!
    @IBOutlet var urlLabelHeight: NSLayoutConstraint!
    @IBOutlet var urlView: UIView!
    @IBOutlet var followButton: UIButton!
    @IBOutlet var followButtonHeight: NSLayoutConstraint!
    @IBOutlet var verifiedImageView: UIImageView!
    @IBOutlet var verifiedImageViewWidth: NSLayoutConstraint!
    var user: SignedInUser!
    var tableView: UITableView!
    var tableViewController: ProfileTableViewController!
    var isSameUser: Bool {
        get {
            return self.user.clientUser.id == self.user.user.id
        }
    }
    var heightConstraint: NSLayoutConstraint!
    
    func setUser(user: SignedInUser, tableViewController: ProfileTableViewController) {
        self.tableView = tableViewController.tableView
        self.tableViewController = tableViewController
        self.user = user
        self.heightConstraint = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 0)
        self.addConstraint(self.heightConstraint)
        self.updateUser()
        if let u = self.user.user as? TwitterUser {
            if u.followersCount == nil {
                self.followButton.setTitle("   Loading...   ", forState: .Normal)
                let params = ["user_id" : self.user.user.id]
                let urlString = Twitter["base_url"]! + "users/show.json"
                self.user.client.get(urlString, parameters: params, success: {
                    (data, response) -> Void in
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    self.user.user = Utility.twitterUserFromDictionary(json)
                    self.updateUser()
                }, failure: {
                    (error) -> Void in
                    Utility.handleError(error, message: "Error Fetching User Information")
                })
            }
        } else if let _ = self.user.user as? InstagramUser {
            if !self.isSameUser {
                self.followButton.setTitle("   Loading...   ", forState: .Normal)
                let url = Instagram["base_url"]! + "users/\(self.user.user.id)/relationship"
                self.user.client.get(url, parameters: ["":""], success: {
                    (data, response) -> Void in
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSDictionary)
                    let data = json["data"] as! NSDictionary
                    let outgoingStatus = data["outgoing_status"] as! String
                    if outgoingStatus == "none" {
                        self.followButton.setTitle("   Follow   ", forState: .Normal)
                    } else {
                        self.followButton.backgroundColor = tintColour
                        self.followButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                        if outgoingStatus == "follows" {
                            self.followButton.setTitle("   Following   ", forState: .Normal)
                        } else {
                            self.followButton.setTitle("   Requested   ", forState: .Normal)
                        }
                    }
                }, failure: {
                    (error) -> Void in
                    Utility.handleError(error, message: "Error Fetching Relationship")
                })
            }
        } else if let u = self.user.user as? TumblrUser {
            if u.username == nil {
                self.followButton.setTitle("   Loading...   ", forState: .Normal)
                let params = ["api_key" : Tumblr["key"]!]
                let urlString = Tumblr["base_url"]! + "blog/\(self.user.user.id).tumblr.com/info"
                self.user.client.get(urlString, parameters: params, success: {
                    (data, response) -> Void in
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let response = json["response"] as! NSDictionary
                    let user = response["blog"] as! NSDictionary
                    self.user.user = Utility.tumblrUserFromDictionary(user, nameString: "name")
                    self.updateUser()
                }, failure: {
                    (error) -> Void in
                    Utility.handleError(error, message: "Error Fetching User Information")
                })
            }
        } else if let u = self.user.user as? SoundCloudUser {
            if u.name == nil {
                self.followButton.setTitle("   Loading...   ", forState: .Normal)
                let params = ["" :""]
                let urlString = SoundCloud["base_url"]! + "users/\(self.user.user.id)"
                self.user.client.get(urlString, parameters: params, success: {
                    (data, response) -> Void in
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    self.user.user = Utility.soundCloudUserFromDictionary(json)
                    self.updateUser()
                    }, failure: {
                        (error) -> Void in
                        Utility.handleError(error, message: "Error Fetching User Information")
                })
            }
        }
    }
    
    func updateUser() {
        if self.user.user.profilePictureUrl != nil {
            if self.user.user.profilePictureLargeUrl != nil {
                self.profilePictureView.sd_setImageWithURL(self.user.user.profilePictureLargeUrl)
            } else {
                var url: NSURL!
                switch self.user.user.type {
                case .Facebook:
                    url = Utility.facebookProfilePictureFromId(self.user.user.id, large: true)
                    self.user.user.profilePictureLargeUrl = url
                case .Twitter:
                    url = Utility.twitterLargeProfilePictureUrlFromUrl(self.user.user.profilePictureUrl!)
                    self.user.user.profilePictureLargeUrl = url
                default:
                    url = self.user.user.profilePictureUrl!
                }
                self.profilePictureView.sd_setImageWithURL(url)
            }
        } else {
            self.profilePictureView.image = nil
        }
        var h = (w / 3) + 144
        var description: String?
        var location: String?
        var website: String?
        var following = false
        var verified = false
        switch self.user.user.type {
        case .Facebook:
            self.nameLabel.text = self.user.user.name!
            let u = self.user.user as! FacebookUser
            if let page = u as? FacebookPage {
                description = page.category
            }
            if !self.isSameUser {
                self.followButtonHeight.constant = 0
                h -= 44
            }
            self.usernameLabelHeight.constant = 0
            self.usernameLabel.text = nil
            h -= 32
            location = u.location
        case .Twitter:
            self.nameLabel.text = self.user.user.name!
            self.usernameLabel.text = "@" + self.user.user.username!
            let u = self.user.user as! TwitterUser
            description = u.description
            location = u.location
            website = u.url?.relativeString
            if u.following != nil {
                following = u.following!
            }
            if u.verified != nil {
                verified = u.verified!
            }
        case .Instagram:
            if self.user.user.name == nil || self.user.user.name == "" {
                self.nameLabel.text = self.user.user.username!
                self.usernameLabelHeight.constant = 0
                self.usernameLabel.text = nil
                h -= 32
            } else {
                self.nameLabel.text = self.user.user.name!
                self.usernameLabel.text = self.user.user.username!
            }
            let u = self.user.user as! InstagramUser
            description = u.bio
            website = u.website?.relativeString
        case .Tumblr:
            if self.user.user.username == nil || self.user.user.username == "" {
                self.nameLabel.text = self.user.user.name!
                self.usernameLabelHeight.constant = 0
                self.usernameLabel.text = nil
                h -= 32
            } else {
                self.nameLabel.text = self.user.user.name!
                self.usernameLabelHeight.constant = 32
                self.usernameLabel.text = self.user.user.username!
            }
        case .SoundCloud:
            if !self.isSameUser {
                self.followButtonHeight.constant = 0
                h -= 44
            }
            if self.user.user.name == nil || self.user.user.name == "" {
                self.nameLabel.text = self.user.user.username!
                self.usernameLabelHeight.constant = 0
                self.usernameLabel.text = nil
                h -= 32
            } else {
                self.nameLabel.text = self.user.user.name!
                self.usernameLabelHeight.constant = 32
                self.usernameLabel.text = self.user.user.username!
            }
        default:
            print("okidoki")
        }
        if description != nil {
            self.descriptionLabel.text = description!
            let add = 12 + self.descriptionLabel.sizeThatFits(CGSizeMake(w - 64, CGFloat.max)).height
            self.descriptionLabelHeight.constant = add
            h += add
        } else {
            self.descriptionLabel.text = nil
            self.descriptionLabelHeight.constant = 0
        }
        if location != nil {
            self.locationLabel.text = location!
            self.locationLabelHeight.constant = 32
            h += 32
        } else {
            self.locationLabel.text = nil
            self.locationLabelHeight.constant = 0
        }
        if website != nil {
            self.urlLabel.text = website!
            self.urlLabelHeight.constant = 32
            h += 32
        } else {
            self.urlLabel.text = nil
            self.urlLabelHeight.constant = 0
        }
        if self.isSameUser {
            self.followButton.setTitle("   Log Out   ", forState: .Normal)
        } else {
            if following {
                self.followButton.backgroundColor = tintColour
                self.followButton.setTitle("   Following   ", forState: .Normal)
                self.followButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            } else {
                self.followButton.setTitle("   Follow   ", forState: .Normal)
            }
        }
        if verified {
            self.verifiedImageViewWidth.constant = 20
        } else {
            self.verifiedImageViewWidth.constant = 0
        }
        self.heightConstraint.constant = h
        self.tableView.tableHeaderView = self
        self.tableView.tableHeaderView = self.tableView.tableHeaderView
        self.tableViewController.updateHeader()
    }
    
    @IBAction func follow() {
        if !self.isSameUser {
            if self.followButton.titleForState(.Normal) == "   Following   " {
                followUnfollow(false)
            } else if self.followButton.titleForState(.Normal) == "   Follow   " {
                followUnfollow(true)
            }
        } else {
            let alertController = UIAlertController(title: self.nameLabel.text, message: nil, preferredStyle: .Alert)
            /*let primaryAction = UIAlertAction(title: "Make Primary Account", style: .Default, handler: {
                (action) -> Void in
                self.makeAccountPrimary(self.user)
            })
            if self.user.primary! {
                primaryAction.enabled = false
            }*/
            let logOutAction = UIAlertAction(title: "Log Out", style: .Destructive, handler: {
                (action) -> Void in
                let string = self.user.clientUser.type.rawValue
                //if let defaults = NSUserDefaults.standardUserDefaults().arrayForKey(string)! as? [[String : String]] {
                    /*let mutableDefaults = NSMutableArray(array: defaults)
                    for dictionary in defaults {
                        if dictionary["id"] == self.user.clientUser.id {
                            mutableDefaults.removeObject(dictionary)
                        }
                    }
                    if mutableDefaults.count != 0 {
                        var primaryFound = false
                        for user in mutableDefaults {
                            if (user as! [String : String])["primary"] == "true" {
                                primaryFound = true
                            }
                        }
                        if !primaryFound {
                            var user = mutableDefaults[0] as! [String : String]
                            user["primary"] = "true"
                            mutableDefaults[0] = user
                        }
                    }*/
                NSUserDefaults.standardUserDefaults().setValue(nil, forKey: string)
                Utility.findUsers()
                for (i, viewController) in self.tableViewController.tabBarController!.viewControllers!.enumerate() {
                    let navigationController = viewController as! UINavigationController
                    navigationController.popToRootViewControllerAnimated(true)
                    if i == 0 {
                        navigationController.setViewControllers([HomeSwipeViewController()], animated: false)
                    } else if i == 1 {
                        navigationController.setViewControllers([NotificationsTableViewController()], animated: false)
                    }
                }
                //}
                
            })
            //alertController.addAction(primaryAction)
            alertController.addAction(logOutAction)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            self.tableViewController.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func makeAccountPrimary(user: SignedInUser) {
        let string = user.clientUser.type.rawValue
        if NSUserDefaults.standardUserDefaults().arrayForKey(string) != nil {
            for dictionary in NSUserDefaults.standardUserDefaults().arrayForKey(string)! {
                let d = NSMutableDictionary(dictionary: dictionary as! NSDictionary)
                d["primary"] = "false"
                Utility.saveDictionary(d, s: string)
            }
        }
        user.primary = true
        Utility.saveSignedInUser(user)
        let nav = self.tableViewController.tabBarController!.viewControllers![1] as! UINavigationController
        nav.popToRootViewControllerAnimated(false)
        let trending = nav.viewControllers.first! as! TrendingTableViewController
        trending.getSignedInUsers()
        trending.getUrls()
    }
    
    func followUnfollow(follow: Bool) {
        var url: String!
        var params = ["":""]
        switch self.user.user.type {
        case .Twitter:
            params = ["user_id" : self.user.user.id]
            if follow {
                url = Twitter["base_url"]! + "friendships/create.json"
            } else {
                url = Twitter["base_url"]! + "friendships/destroy.json"
            }
        case .Instagram:
            url = Instagram["base_url"]! + "users/\(self.user.user.id)/relationship"
            if follow {
                params = ["action" : "follow"]
            } else {
                params = ["action" : "unfollow"]
            }
        case .Tumblr:
            params = ["url" : "\(self.user.user.id).tumblr.com"]
            if follow {
                url = Tumblr["base_url"]! + "user/follow"
            } else {
                url = Tumblr["base_url"]! + "user/unfollow"
            }
        default:
            return
        }
        self.followButton.setTitle("   Loading...   ", forState: .Normal)
        self.user.client.post(url, parameters: params, success: {
            (data, response) -> Void in
            self.user.user.following = follow
            if follow {
                self.followButton.backgroundColor = tintColour
                self.followButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                self.followButton.setTitle("   Following   ", forState: .Normal)
            } else {
                self.followButton.backgroundColor = UIColor.whiteColor()
                self.followButton.setTitleColor(tintColour, forState: .Normal)
                self.followButton.setTitle("   Follow   ", forState: .Normal)
            }
        }) {
            (error) -> Void in
            if !follow {
                self.followButton.backgroundColor = tintColour
                self.followButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                self.followButton.setTitle("   Following   ", forState: .Normal)
            } else {
                self.followButton.backgroundColor = UIColor.whiteColor()
                self.followButton.setTitleColor(tintColour, forState: .Normal)
                self.followButton.setTitle("   Follow   ", forState: .Normal)
            }
            Utility.handleError(error, message: !follow ? "Error Unfollowing User" : "Error Following User")
        }
    }
    
    override func awakeFromNib() {
        self.profilePictureView.layer.cornerRadius = w / 6
        self.profilePictureView.addTap(self, action: "showImage:")
        self.followButton.layer.borderColor = tintColour.CGColor
        self.followButton.layer.cornerRadius = 4
        self.followButton.layer.borderWidth = 1
        self.urlView.addTap(self, action: "showUserUrl")
    }
    
    func showUserUrl() {
        let url = NSURL(string: self.urlLabel.text!)!
        Utility.openUrl(url, del: self.tableViewController)
    }
    
    func showImage(sender: UITapGestureRecognizer) {
        let iView = sender.view as! UIImageView
        if iView.image != nil {
            Utility.showImage(iView.image!, view: iView, viewController: self.tableViewController)
        }
    }

}
