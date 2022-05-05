//
//  ActionsTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 31/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class ActionsTableViewCell: UITableViewCell {
    
    @IBOutlet var facebookLikeButton: UIButton!
    @IBOutlet var facebookCommentButton: UIButton!
    @IBOutlet var twitterReplyButton: UIButton!
    @IBOutlet var twitterRetweetButton: UIButton!
    @IBOutlet var twitterFavouriteButton: UIButton!
    @IBOutlet var instagramLikeButton: UIButton!
    @IBOutlet var tumblrReblogButton: UIButton!
    @IBOutlet var tumblrLikeButton: UIButton!
    var post: Post!
    var tableView: UITableView!
    var delegate: CellDelegate!
    var postViewController: PostTableViewController!
    
    func setPost(post: Post, postViewController: PostTableViewController, tableView: UITableView) {
        self.post = post
        self.tableView = tableView
        self.postViewController = postViewController
        switch self.post.type {
        case .Facebook:
            self.facebookLikeButton.setImage(UIImage(named: "Like Full 20px"), forState: .Selected)
            if self.post.userLikes != nil {
                if self.post.userLikes! {
                    self.facebookLikeButton.selected = true
                }
            }
        case .Twitter:
            self.twitterFavouriteButton.setImage(UIImage(named: "Heart Full 20px"), forState: .Selected)
            self.twitterRetweetButton.setImage(UIImage(named: "Retweet Full 20px"), forState: .Selected)
            if self.post.userLikes != nil {
                if self.post.userLikes! {
                    self.twitterFavouriteButton.selected = true
                }
            }
            let p = self.post as! TwitterPost
            if p.userRetweeted! {
                self.twitterRetweetButton.selected = true
            }
        case .Instagram:
            self.instagramLikeButton.setImage(UIImage(named: "Heart Full 20px"), forState: .Selected)
            if self.post.userLikes != nil {
                if self.post.userLikes! {
                    self.instagramLikeButton.selected = true
                }
            }
        case .Tumblr:
            self.tumblrLikeButton.setImage(UIImage(named: "Heart Full 20px"), forState: .Selected)
            if self.post.userLikes != nil {
                if self.post.userLikes! {
                    self.tumblrLikeButton.selected = true
                }
            }
        default:
            print("okidoki")
        }
    }
    
    // Facebook, Twitter, Instagram, Tumblr
    @IBAction func like(sender: AnyObject) {
        let button = sender as! UIButton
        Utility.like(self.post, button: button, cell: self) {
            self.postViewController.countCell.setPost(self.post, tableView: self.tableView)
        }
    }
    
    // Facebook, Twitter
    @IBAction func comment(sender: AnyObject) {
        Utility.replyComment(self.post, delegate: self.delegate)
    }
    
    // Twitter, Tumblr
    @IBAction func retweet(sender: AnyObject) {
        if self.post.type == .Twitter {
            var username = self.post.from!.username!
            if username.hasSuffix("s") {
                username += "'"
            } else {
                username += "'s"
            }
            let alertController = UIAlertController(title: "Retweet @\(username) Tweet?", message: nil, preferredStyle: .ActionSheet)
            let quoteAction = UIAlertAction(title: "Quote Tweet", style: .Default, handler: {
                (action) -> Void in
                Utility.retweet(self.post, delegate: self.delegate)
            })
            let retweetAction = UIAlertAction(title: "Retweet", style: .Default, handler: {
                (action) -> Void in
                let url = Twitter["base_url"]! + "statuses/retweet/\(self.post.id).json"
                let params = ["id" : self.post.id]
                self.post.signedInUser.client.post(url, parameters: params, success: {
                    (data, response) -> Void in
                        self.twitterRetweetButton.selected = true
                    }, failure: {
                        (error) -> Void in
                        Utility.handleError(error, message: "Error Retweeting Tweet")
                })
            })
            let p = self.post as! TwitterPost
            if !p.userRetweeted {
                retweetAction.enabled = false
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(quoteAction)
            alertController.addAction(retweetAction)
            alertController.addAction(cancelAction)
            self.delegate.presentViewController(alertController)
        } else {
            var username = self.post.from!.name!
            if username.hasSuffix("s") {
                username += "'"
            } else {
                username += "'s"
            }
            let alertController = UIAlertController(title: "Reblog \(username) Post?", message: nil, preferredStyle: .ActionSheet)
            let quoteAction = UIAlertAction(title: "Reblog With Comment", style: .Default, handler: {
                (action) -> Void in
                Utility.retweet(self.post, delegate: self.delegate)
            })
            let retweetAction = UIAlertAction(title: "Reblog", style: .Default, handler: {
                (action) -> Void in
                let url = Tumblr["base_url"]! + "blog/\(self.post.signedInUser.clientUser.name!).tumblr.com/post/reblog"
                let p = self.post as! TumblrPost
                let params = ["id" : self.post.id, "reblog_key" : p.reblogKey]
                self.post.signedInUser.client.post(url, parameters: params, success: {
                    (data, response) -> Void in
                }, failure: {
                    (error) -> Void in
                    Utility.handleError(error, message: "Error Reblogging Post")
                })
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(quoteAction)
            alertController.addAction(retweetAction)
            alertController.addAction(cancelAction)
            self.delegate.presentViewController(alertController)
        }
    }

    @IBAction func share(sender: AnyObject) {
        let alertController = UIAlertController(title: "Actions", message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: "Block", style: .Default, handler: {
            (action) -> Void in
            let s = "Blocked\(self.post.type.rawValue)"
            if NSUserDefaults.standardUserDefaults().arrayForKey(s) == nil {
                NSUserDefaults.standardUserDefaults().setObject([self.post.from!.id], forKey: s)
            } else {
                let a = NSMutableArray(array: NSUserDefaults.standardUserDefaults().arrayForKey(s)!)
                a.addObject(self.post.from!.id)
                let array: NSArray = NSArray(array: a)
                NSUserDefaults.standardUserDefaults().setObject(array, forKey: s)
            }
            let tabBarController = UIApplication.sharedApplication().keyWindow!.rootViewController! as! UITabBarController
            tabBarController.delegate?.tabBarController!(tabBarController, shouldSelectViewController: tabBarController.viewControllers![tabBarController.selectedIndex])
        }))
        alertController.addAction(UIAlertAction(title: "Flag", style: .Default, handler: {
            (action) -> Void in
            var url: NSURL!
            switch self.post.type {
            case .Facebook:
                url = NSURL(string: "https://facebook.com/\(self.post.id)")
            case .Twitter:
                url = NSURL(string: "https://twitter.com/\(self.post.from!.username!)/status/\(self.post.id)")
            case .Instagram:
                let p = self.post as! InstagramPost
                url = NSURL(string: p.link)
            case .Tumblr:
                url = NSURL(string: "https://\(self.post.from!.name!).tumblr.com/post/\(self.post.id)")
            default:
                print("okidoki")
            }
            print(url!.absoluteString)
            if UIApplication.sharedApplication().canOpenURL(url!) {
                UIApplication.sharedApplication().openURL(url!)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        if self.delegate != nil {
            self.delegate!.presentViewController(alertController)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
