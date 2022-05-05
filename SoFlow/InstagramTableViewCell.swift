//
//  InstagramTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 31/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class InstagramTableViewCell: PostTableViewCell {

    @IBOutlet var commentButton: UIButton!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var captionLabelHeight: NSLayoutConstraint!
    @IBOutlet var captionLabelSpacing: NSLayoutConstraint!
    @IBOutlet var captionLabel: KILabel!
    @IBOutlet var instagramImageView: UIImageView!
    @IBOutlet var mapMarkerButtonWidth: NSLayoutConstraint!
    @IBOutlet var tagButtonWidth: NSLayoutConstraint!
    @IBOutlet var imageViewHeight: NSLayoutConstraint!
    var tagsShown = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.likeButton.setImage(UIImage(named: "Heart Full White 20px"), forState: .Selected)
        instagramImageView.backgroundColor = separatorColour
        captionLabel.tintColor = tintColour
    }
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        super.setPost(post, signedInUser: signedInUser)
        let p = post as! InstagramPost
        /*if p.location != nil {
            self.mapMarkerButtonWidth.constant = 36
        } else {
            self.mapMarkerButtonWidth.constant = 0
        }
        if p.photoTags != nil && p.photoTags?.count > 0 {
            self.tagButtonWidth.constant = 36
        } else {
            self.tagButtonWidth.constant = 0
        }*/
        if post.media!.type == MediaType.Image {
            self.imageViewHeight.constant = w * self.post.media!.scale!
            self.instagramImageView.sd_setImageWithURL(post.media!.url)
            self.instagramImageView.addTap(self, action: "showImage:")
        } else {
            self.instagramImageView.sd_setImageWithURL(post.media!.thumbnail!)
        }
        //self.likeButton.setTitleColor(UIColor(red: 240 / 255, green: 72 / 255, blue: 87 / 255, alpha: 1), forState: .Selected)
        if p.caption != nil {
            self.captionLabel.text = p.caption!.message
            self.captionLabelSpacing.constant = 12
            self.captionLabelHeight.constant = captionLabel.sizeThatFits(CGSizeMake(w - 72, CGFloat.max)).height
        } else {
            self.captionLabel.text = ""
            self.captionLabelSpacing.constant = 0
            self.captionLabelHeight.constant = 0
        }
        if p.userLikes! {
            self.likeButton.selected = true
        } else {
            self.likeButton.selected = false
        }
        self.captionLabel.userHandleLinkTapHandler = {
            (label, string, range) -> Void in
            if !changingViewController {
                changingViewController = true
                let urlString = Instagram["base_url"]! + "users/search"
                let params = ["q" : string, "count" : "1"]
                signedInUser.client.get(urlString, parameters: params, success: {
                    (data, response) -> Void in
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let data = json["data"] as! NSArray
                    if data.count > 0 {
                        let d = data[0] as! NSDictionary
                        let u = Utility.instagramUserFromDictionary(d)
                        let user = SignedInUser(client: signedInUser.client, user: u, clientUser: signedInUser.clientUser)
                        let profileViewController = ProfileTableViewController(user: user)
                        if self.del != nil {
                            self.del!.pushViewController(profileViewController)
                            changingViewController = false
                        }
                    }
                }, failure: {
                    (error) -> Void in
                    changingViewController = false
                    Utility.handleError(error, message: "Error Getting User")
                })
            }
        }
        self.captionLabel.urlLinkTapHandler = {
            (label, string, range) -> Void in
            let url = NSURL(string: string)!
            if self.del != nil {
                Utility.openUrl(url, del: self.del!)
            }
        }
        self.captionLabel.hashtagLinkTapHandler = {
            (label, string, range) -> Void in
            let s = String(string.characters.dropFirst()).lowercaseString
            let urlString = Instagram["base_url"]! + "tags/\(s)/media/recent"
            let params = ["count" : "200"]
            let postsViewController = PostsTableViewController(urls: [urlString], params: [params], signedInUsers: [signedInUser], title: string)
            if self.del != nil {
                self.del!.pushViewController(postsViewController)
            }
        }
        self.layoutIfNeeded()
    }
    
    @IBAction func showTags(sender: AnyObject) {
        let p = self.post as! InstagramPost
        if !self.tagsShown {
            for (i, tag) in p.photoTags!.enumerate() {
                let button = UIButton()
                button.tag = i
                button.addTarget(self, action: "showTagUser:", forControlEvents: .TouchUpInside)
                button.setTitle("  " + tag.user.username! + "  ", forState: .Normal)
                button.tintColor = tintColour
                button.backgroundColor = UIColor(white: 0, alpha: 0.8)
                button.titleLabel!.font = UIFont.systemFontOfSize(13)
                button.sizeToFit()
                button.layer.cornerRadius = button.frame.height / 2
                button.clipsToBounds = true
                let size = self.instagramImageView.frame.size
                button.center = CGPointMake(size.width * tag.x, size.height * tag.y)
                self.instagramImageView.addSubview(button)
            }
            self.tagsShown = true
        } else {
            self.removeTags()
            self.tagsShown = false
        }
    }
    
    override func showDraw() {
        //self.serviceLabel.textColor = UIColor(red: 0.67, green: 0.73, blue: 0.79, alpha: 1)
        self.captionLabel.textColor = UIColor.whiteColor()
        self.captionLabel.tintColor = UIColor.whiteColor()
        self.captionLabel.text = self.captionLabel.text
        super.showDraw()
        if self.post != nil {
            self.showTags(self)
        }
    }
    
    override func retractDraw() {
        //self.serviceLabel.textColor = InstagramColour
        self.captionLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        self.captionLabel.tintColor = tintColour
        self.captionLabel.text = self.captionLabel.text
        super.retractDraw()
        if self.post != nil {
            self.removeTags()
        }
    }
    
    func showTagUser(sender: UIButton) {
        let p = self.post as! InstagramPost
        let u = p.photoTags![sender.tag].user
        let user = SignedInUser(client: self.signedInUser.client, user: u, clientUser: self.signedInUser.clientUser)
        self.del!.showUser(user)
    }
    
    func removeTags() {
        for v in self.instagramImageView.subviews {
            if let _ = v as? UIButton {
                v.removeFromSuperview()
            }
        }
    }
    
    override func prepareForReuse() {
        self.removeTags()
    }
    
    @IBAction func showLocation(sender: AnyObject) {
        let mapViewController = MapViewController()
        self.del!.pushViewController(mapViewController)
        mapViewController.setLocation((self.post as! InstagramPost).location!)
    }
    
    func setLabelText() {
        if self.post.commentCount! != 0 {
            let cc = Utility.formatNumber(self.post.commentCount!)
            self.commentButton.setTitle(" " + cc, forState: .Normal)
            self.commentButton.sizeToFit()
        } else {
            self.commentButton.setTitle(nil, forState: .Normal)
            self.commentButton.sizeToFit()
        }
        if self.post.likeCount! != 0 {
            let lc = Utility.formatNumber(self.post.likeCount!)
            self.likeButton.setTitle(" " + lc, forState: .Normal)
            self.likeButton.sizeToFit()
        } else {
            self.likeButton.setTitle(nil, forState: .Normal)
            self.likeButton.sizeToFit()
        }
    }
    
    @IBAction func showComments(sender: AnyObject) {
        let postViewController = PostTableViewController(post: self.post)
        postViewController.showComments = true
        if self.del != nil {
            self.del!.pushViewController(postViewController)
        }
    }
    
    @IBAction func showLikes(sender: AnyObject) {
        if post.likeCount > 0 {
            let urlString = Instagram["base_url"]! + "media/" + post.id + "/likes"
            let usersViewController = UsersTableViewController(urls: [urlString], params: [["":""]], signedInUsers: [signedInUser], title: "Likes", pages: false, users: nil)
            if self.del != nil {
                self.del!.pushViewController(usersViewController)
            }
        }
    }
    
    @IBAction func like(sender: AnyObject) {
        Utility.like(self.post, button: self.likeButton, cell: self) {
            //self.setLabelText()
        }
    }

    @IBAction func showVideo() {
        let p = self.post as! InstagramPost
        self.del!.showVideo(p.media!.url)
    }

}
