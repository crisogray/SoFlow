//
//  FacebookTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 09/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class FacebookCommentTableViewCell: PostTableViewCell {
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var commentImageView: UIImageView!
    @IBOutlet var imageViewHeight: NSLayoutConstraint!
    @IBOutlet var bottomSpace: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //self.likeButton.setImage(UIImage(named: "Like Full 20px"), forState: .Selected)
        //self.likeButton.setTitleColor(UIColor(red: 61 / 255, green: 83 / 255, blue: 159 / 255, alpha: 1), forState: .Selected)
    }
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        super.setPost(post, signedInUser: signedInUser)
        let p = post as! Comment
        self.messageLabel.text = p.message
        if p.media != nil {
            if p.message == nil || p.message == "" {
                self.bottomSpace.constant = 0
            } else {
                self.bottomSpace.constant = 8
            }
            var scale = post.media!.scale!
            if scale > 9 / 16 {
                scale = 9 / 16
            }
            self.imageViewHeight.constant = (w/* - 72*/) * scale
            self.commentImageView.addTap(self, action: "showImage:")
            if p.media!.type == MediaType.Image {
                self.commentImageView.sd_setImageWithURL(p.media!.url)
            } else if p.media!.type == MediaType.Video {
                self.commentImageView.sd_setImageWithURL(p.media!.thumbnail!)
            }
        }
    }
    
    func setLabelText() {
        if post.likeCount != nil {
            if post.likeCount != 0 {
                let lc = Utility.formatNumber(self.post.likeCount!)
                self.likeButton.setTitle(" " + lc, forState: .Normal)
            } else {
                self.likeButton.setTitle(nil, forState: .Normal)
            }
        }
        self.likeButton.sizeToFit()
    }
    
    @IBAction func comment(sender: AnyObject) {
        //let commentViewController = CommentsTableViewController(post: self.post, signedInUser: signedInUser, canComment: true, commentImmediately: true)
        if self.del != nil {
            //self.del!.pushViewController(commentViewController)
        }
    }
    
    @IBAction func like(sender: AnyObject) {
        Utility.like(self.post, button: nil, cell: self) {
            self.setLabelText()
        }
    }
    
}
