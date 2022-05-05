//
//  TwitterTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 04/06/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class TwitterTableViewCell: PostTableViewCell {

    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var favouriteButton: UIButton!
    @IBOutlet var retweetButton: UIButton!
    @IBOutlet var messageLabel: KILabel!
    @IBOutlet var retweetedImageButton: UIButton!
    @IBOutlet var retweetedButton: UIButton!
    @IBOutlet var retweetedButtonHeight: NSLayoutConstraint!
    @IBOutlet var retweetedButtonSpacing: NSLayoutConstraint!
    @IBOutlet var mapMarkerButtonWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.favouriteButton.setImage(UIImage(named: "Heart Full White 20px"), forState: .Selected)
        //self.retweetButton.setImage(UIImage(named: "Retweet Full 20px"), forState: .Selected)
        self.usernameLabel.addTap(self, action: "showUser")
        self.messageLabel.tintColor = tintColour
        self.messageLabel.urlLinkTapHandler = {
            (label, string, range) -> Void in
            let url = NSURL(string: string)!
            if self.del != nil {
                Utility.openUrl(url, del: self.del!)
            }
        }
        self.messageLabel.userHandleLinkTapHandler = {
            (label, string, range) -> Void in
            var s: String = String(string.characters.dropFirst())
            if s.rangeOfString(".") != nil {
                s = s.componentsSeparatedByString(".")[0]
            }
            let p = self.post as! TwitterPost
            var done = false
            if p.userMentions != nil {
                for t in p.userMentions! {
                    if !done {
                        if t.user.username!.lowercaseString == s.lowercaseString {
                            done = true
                            let signedInUser = SignedInUser(client: self.signedInUser.client, user: t.user, clientUser: self.signedInUser.clientUser)
                            if self.del != nil {
                                self.del!.showUser(signedInUser)
                            }
                        }
                    }
                }
            }
        }
        self.messageLabel.hashtagLinkTapHandler = {
            (label, string, range) -> Void in
            let urlString = Twitter["base_url"]! + "search/tweets.json"
            let params = ["count" : "200", "q" : string]
            let postsViewController = PostsTableViewController(urls: [urlString], params: [params], signedInUsers: [self.signedInUser], title: string)
            if self.del != nil {
                self.del!.pushViewController(postsViewController)
            }
        }
    }
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        super.setPost(post, signedInUser: signedInUser)
        let p = post as! TwitterPost
        if p.location != nil {
            //self.mapMarkerButtonWidth.constant = 36
        } else {
            //self.mapMarkerButtonWidth.constant = 0
        }
        self.usernameLabel.text = "@" + post.from!.username!
        //self.usernameLabel.textColor = TwitterColour
        //self.usernameLabel.sizeToFit()
        self.messageLabel.text = p.text
        if self.favouriteButton != nil {
            if p.userLikes! {
                self.favouriteButton.selected = true
            } else {
                self.favouriteButton.selected = false
            }
        }
        if p.retweeted! {
            if p.retweetUser!.id == p.signedInUser.clientUser.id {
                self.retweetedButton.setTitle("You retweeted", forState: .Normal)
            } else {
                self.retweetedButton.setTitle(p.retweetUser!.name! + " retweeted", forState: .Normal)
            }
            self.retweetedButtonHeight.constant = 20
            self.retweetedButtonSpacing.constant = 8
        } else {
            self.retweetedButton.setTitle("", forState: .Normal)
            self.retweetedButtonHeight.constant = 0
            self.retweetedButtonSpacing.constant = 4
        }
    }
    
    func setLabelText() {
        let p = post as! TwitterPost
        if self.post.likeCount != 0 {
            let lc = Utility.formatNumber(post.likeCount!)
            self.favouriteButton.setTitle("  " + lc, forState: .Normal)
        } else {
            self.favouriteButton.setTitle(nil, forState: .Normal)
        }
        self.favouriteButton.sizeToFit()
        if p.retweetCount != 0 {
            let cc = Utility.formatNumber(p.retweetCount!)
            self.retweetButton.setTitle("  " + cc, forState: .Normal)
        } else {
            self.retweetButton.setTitle(nil, forState: .Normal)
        }
        self.retweetButton.sizeToFit()
    }
    
    @IBAction func showLocation(sender: AnyObject) {
        if self.del != nil {
            let mapViewController = MapViewController()
            self.del!.pushViewController(mapViewController)
            mapViewController.setLocation((self.post as! TwitterPost).location!)
        }
    }

    @IBAction func reply(sender: AnyObject) {
        if self.del != nil {
            Utility.replyComment(self.post, delegate: self.del!)
        }
    }
    
    @IBAction func retweet(sender: AnyObject) {
        if self.del != nil {
            var username = self.post.from!.username!
            if username.hasSuffix("s") {
                username += "'"
            } else {
                username += "'s"
            }
            let alertController = UIAlertController(title: "Retweet @\(username) Tweet?", message: nil, preferredStyle: .ActionSheet)
            let quoteAction = UIAlertAction(title: "Quote Tweet", style: .Default, handler: {
                (action) -> Void in
                Utility.retweet(self.post, delegate: self.del!)
            })
            let retweetAction = UIAlertAction(title: "Retweet", style: .Default, handler: {
                (action) -> Void in
                let url = Twitter["base_url"]! + "statuses/retweet/\(self.post.id).json"
                let params = ["id" : self.post.id]
                //self.retweetButton.selected = true
                (self.post as! TwitterPost).userRetweeted = true
                (self.post as! TwitterPost).retweetCount!++
                self.post.signedInUser.client.post(url, parameters: params, success: {
                    (data, response) -> Void in
                }, failure: {
                    (error) -> Void in
                    Utility.handleError(error, message: "Error Retweeting Tweet")
                })
            })
            let p = self.post as! TwitterPost
            if p.userRetweeted! {
                retweetAction.enabled = false
                print("ok")
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(quoteAction)
            alertController.addAction(retweetAction)
            alertController.addAction(cancelAction)
            self.del!.presentViewController(alertController)
        }
    }
    
    @IBAction func favourite(sender: AnyObject) {
        Utility.like(self.post, button: self.favouriteButton, cell: self) {
            //self.setLabelText()
        }
    }
    
    @IBAction func showRetweetUser(sender: AnyObject) {
        let p = post as! TwitterPost
        let u = SignedInUser(client: signedInUser.client, user: p.retweetUser!, clientUser: signedInUser.clientUser)
        if self.del != nil {
            self.del!.showUser(u)
        }
    }
    
    @IBAction func showFavourites(sender: AnyObject) {
    }
    
    @IBAction func showRetweets(sender: AnyObject) {
        let p = post as! TwitterPost
        if p.retweetCount > 0 {
            let urlString = Twitter["base_url"]! + "statuses/retweeters/ids.json"
            let params = ["id" : post.id, "stringify_ids" : "1"]
            let usersViewController = UsersTableViewController(urls: [urlString], params: [params], signedInUsers: [signedInUser], title: "Retweets", pages: false, users: nil)
            if self.del != nil {
                self.del!.pushViewController(usersViewController)
            }
        }
    }
    
    override func showDraw() {
        self.retweetedButton.tintColor = UIColor.whiteColor()
        self.retweetedImageButton.tintColor = UIColor.whiteColor()
        //self.serviceLabel.textColor = UIColor(red: 0.67, green: 0.81, blue: 0.98, alpha: 1)
        self.usernameLabel.textColor = UIColor.whiteColor()
        self.messageLabel.textColor = UIColor.whiteColor()
        self.messageLabel.tintColor = UIColor.whiteColor()
        self.messageLabel.text = self.messageLabel.text
        super.showDraw()
    }
    
    override func retractDraw() {
        self.retweetedButton.tintColor = UIColor.darkGrayColor()
        self.retweetedImageButton.tintColor = UIColor.darkGrayColor()
        //self.serviceLabel.textColor = TwitterColour
        self.usernameLabel.textColor = UIColor.darkGrayColor()
        self.messageLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        self.messageLabel.tintColor = tintColour
        self.messageLabel.text = self.messageLabel.text
        super.retractDraw()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        /*if self.favouriteButton != nil {
            let p = self.post as! TwitterPost
            if p.userLikes! {
                self.favouriteButton.selected = true
                self.favouriteButton.titleLabel!.font = UIFont.systemFontOfSize(13)
            } else {
                self.favouriteButton.selected = false
                self.favouriteButton.titleLabel!.font = UIFont(name: ".SFUIText-Light", size: 13)
            }
            if p.userRetweeted! {
                self.retweetButton.selected = true
                self.retweetButton.titleLabel!.font = UIFont.systemFontOfSize(13)
            } else {
                self.retweetButton.selected = false
                self.retweetButton.titleLabel!.font = UIFont(name: ".SFUIText-Light", size: 13)
            }
            self.setLabelText()
        }*/
    }

}
