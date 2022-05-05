//
//  FacebookTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 09/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class FacebookTableViewCell: PostTableViewCell {
    
    @IBOutlet var messageLabel: KILabel!
    @IBOutlet var commentButton: UIButton!
    @IBOutlet var likeButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        if self.likeButton != nil {
            self.likeButton.setImage(UIImage(named: "Like Full White 20px"), forState: .Selected)
        }
    }
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        super.setPost(post, signedInUser: signedInUser)
        let p = post as! FacebookPost
        let caption = Utility.facebookCaptionFromPost(p)
        if p.message == nil && caption == nil {
            self.messageLabel.text = nil
        } else if p.message == nil && caption != nil {
            self.messageLabel.text = caption!
        } else if p.message != nil && caption == nil {
            self.messageLabel.text = p.message
        } else if p.message != nil && caption != nil {
            self.messageLabel.text = p.message! + "\r" + caption!
        }
        if self.likeButton != nil {
            if post.userLikes! {
                self.likeButton.selected = true
            } else {
                self.likeButton.selected = false
            }
        }
        self.messageLabel.urlLinkTapHandler = {
            (label, string, range) -> Void in
            if let url = NSURL(string: string) {
                if self.del != nil {
                    Utility.openUrl(url, del: self.del!)
                }
            }
        }
    }
    
    func setLabelText() {
        if self.post.likeCount != nil {
            if self.post.likeCount != 0 {
                let lc = Utility.formatNumber(self.post.likeCount!)
                self.likeButton.setTitle(" " + lc, forState: .Normal)
            } else {
                self.likeButton.setTitle(nil, forState: .Normal)
            }
        }
        self.likeButton.sizeToFit()
        if self.post.commentCount != nil {
            if self.commentButton != nil {
                if self.post.commentCount! != 0 {
                    let cc = Utility.formatNumber(self.post.commentCount!)
                    self.commentButton.setTitle(" " + cc, forState: .Normal)
                } else {
                    self.commentButton.setTitle(nil, forState: .Normal)
                }
                self.commentButton.sizeToFit()
            }
        } else {
            self.commentButton = nil
        }
    }
    
    @IBAction func showComments(sender: AnyObject) {
        if self.post.commentCount > 0 {
            //let commentViewController = CommentsTableViewController(post: self.post, signedInUser: signedInUser, canComment: true, commentImmediately: false)
            if self.del != nil {
                //self.del!.pushViewController(commentViewController)
            }
        }
    }
    
    @IBAction func showLikes(sender: AnyObject) {
        if self.post.likeCount > 0 {
            let urlString = Facebook["base_url"]! + post.id + "/likes"
            let usersViewController = UsersTableViewController(urls: [urlString], params: [["":""]], signedInUsers: [self.signedInUser], title: "Likes", pages: false, users: nil)
            if self.del != nil {
                self.del!.pushViewController(usersViewController)
            }
        }
    }
    
    @IBAction func comment(sender: AnyObject) {
        if self.del != nil {
            Utility.replyComment(self.post, delegate: self.del!)
        }
    }
    
    @IBAction func like(sender: AnyObject) {
        Utility.like(self.post, button: self.likeButton, cell: self) {
            //self.setLabelText()
        }
    }
    
    override func showDraw() {
        //self.serviceLabel.textColor = UIColor(red: 0.67, green: 0.71, blue: 0.82, alpha: 1)
        self.messageLabel.textColor = UIColor.whiteColor()
        self.messageLabel.tintColor = UIColor.whiteColor()
        self.messageLabel.text = self.messageLabel.text
        super.showDraw()
    }
    
    override func retractDraw() {
        //self.serviceLabel.textColor = FacebookColour
        self.messageLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        self.messageLabel.tintColor = tintColour
        self.messageLabel.text = self.messageLabel.text
        super.retractDraw()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}
