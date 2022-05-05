//
//  TwitterVideoTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 04/06/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class TwitterVideoTableViewCell: TwitterTableViewCell {

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var thumbnailViewHeight: NSLayoutConstraint!
    var scale: CGFloat!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.thumbnailImageView.backgroundColor = separatorColour
    }

    override func setPost(post: Post, signedInUser: SignedInUser) {
        super.setPost(post, signedInUser: signedInUser)
        self.scale = self.post.media!.scale!
        if self.scale > 9 / 16 {
            self.scale = 9 / 16
        }
        self.thumbnailViewHeight.constant = (w/* - 72*/) * self.scale
        self.thumbnailImageView.sd_setImageWithURL(self.post.media!.thumbnail!)
    }
    
    @IBAction func showVideo() {
        if self.del != nil {
            let p = self.post as! TwitterPost
            self.del!.showVideo(p.media!.url)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
