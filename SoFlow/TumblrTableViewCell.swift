//
//  TumblrTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 03/07/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class TumblrTableViewCell: PostTableViewCell {

    @IBOutlet var likeButton: UIButton!
    @IBOutlet var reblogImageButton: UIButton!
    @IBOutlet var reblogButton: UIButton!
    @IBOutlet var reblogButtonSpacing: NSLayoutConstraint!
    @IBOutlet var reblogButtonHeight: NSLayoutConstraint!
    @IBOutlet var tagsLabel: KILabel!
    @IBOutlet var tagsLabelSpacing: NSLayoutConstraint!
    @IBOutlet var tagsLabelHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.likeButton.setImage(UIImage(named: "Heart Full White 20px"), forState: .Selected)
    }
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        let p = post as! TumblrPost
        if p.userLikes! {
            self.likeButton.selected = true
        } else {
            self.likeButton.selected = false
        }
        if p.tags != nil {
            if !p.tags!.isEmpty {
                tagsLabel.text = ""
                for tag in p.tags! {
                    var t = tag.capitalizedString.stringByReplacingOccurrencesOfString(" ", withString: "")
                    t = t.stringByReplacingOccurrencesOfString(".", withString: "")
                    tagsLabel.text! += "#" + t + " "
                }
                tagsLabelHeight.constant = tagsLabel.sizeThatFits(CGSizeMake(w - 72, CGFloat.max)).height
                tagsLabelSpacing.constant = 8
            } else {
                tagsLabelSpacing.constant = 0
                tagsLabelHeight.constant = 0
            }
        } else {
            tagsLabelSpacing.constant = 0
            tagsLabelHeight.constant = 0
        }
        tagsLabel.hashtagLinkTapHandler = {
            (label, string, range) -> Void in
            let urlString = Tumblr["base_url"]! + "tagged"
            let params = ["filter" : "text", "tag" : "\(String(string.lowercaseString.characters.dropFirst()))", "api_key" : Tumblr["key"]!, "notes_info" : "true"]
            let postsViewController = PostsTableViewController(urls: [urlString], params: [params], signedInUsers: [post.signedInUser], title: string)
            self.del!.pushViewController(postsViewController)
        }
        if p.reblogUser != nil {
            reblogButton.setTitle("Reblog: " + p.reblogUser!.name!, forState: .Normal)
            reblogButtonHeight.constant = 24
            reblogButtonSpacing.constant = 8
        } else {
            reblogButton.setTitle("", forState: .Normal)
            reblogButtonHeight.constant = 0
            reblogButtonSpacing.constant = 0
        }
        super.setPost(post, signedInUser: signedInUser)
    }
    
    @IBAction func showRetweetUser() {
        let p = post as! TumblrPost
        if p.reblogUser != nil {
            let user = SignedInUser(client: signedInUser.client, user: p.reblogUser!, clientUser: signedInUser.clientUser)
            if self.del != nil {
                self.del!.showUser(user)
            }
        }
    }
    
    @IBAction func reblog() {
        if self.del != nil {
            var username = self.post.from!.name!
            if username.hasSuffix("s") {
                username += "'"
            } else {
                username += "'s"
            }
            let alertController = UIAlertController(title: "Reblog \(username) Post?", message: nil, preferredStyle: .ActionSheet)
            let quoteAction = UIAlertAction(title: "Reblog With Comment", style: .Default, handler: {
                (action) -> Void in
                Utility.retweet(self.post, delegate: self.del!)
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
            self.del!.presentViewController(alertController)
        }
    }
    
    override func showDraw() {
        self.tagsLabel.tintColor = UIColor.whiteColor()
        self.tagsLabel.text = self.tagsLabel.text
        self.reblogButton.tintColor = UIColor.whiteColor()
        self.reblogImageButton.tintColor = UIColor.whiteColor()
        super.showDraw()
    }
    
    override func retractDraw() {
        self.tagsLabel.tintColor = UIColor.lightGrayColor()
        self.tagsLabel.text = self.tagsLabel.text
        self.reblogButton.tintColor = UIColor.darkGrayColor()
        self.reblogImageButton.tintColor = UIColor.darkGrayColor()
        super.retractDraw()
    }
    
    @IBAction func like() {
        Utility.like(self.post, button: self.likeButton, cell: self) {}
    }

}
