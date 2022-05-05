//
//  SoundCloudTrackSummaryTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 02/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class SoundCloudTrackTableViewCell: PostTableViewCell {
    
    @IBOutlet var artworkImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var commentButton: UIButton!
    @IBOutlet var trackView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.artworkImageView.backgroundColor = separatorColour
    }
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        super.setPost(post, signedInUser: signedInUser)
        let p = post as! SoundCloudPost
        self.titleLabel.text = p.title
        self.artworkImageView.sd_setImageWithURL(p.media!.url)
        //self.setLabelText()
        self.trackView.layer.borderWidth = 0.5
        self.trackView.layer.borderColor = separatorColour.CGColor
        self.trackView.clipsToBounds = true
        self.trackView.layer.cornerRadius = self.trackView.frame.height / 8
    }
    
    func setLabelText() {
        if self.post.likeCount != 0 {
            let lc = Utility.formatNumber(post.likeCount!)
            self.likeButton.setTitle("  " + lc, forState: .Normal)
        } else {
            self.likeButton.setTitle(nil, forState: .Normal)
        }
        self.likeButton.sizeToFit()
        if self.post.commentCount! != 0 {
            let cc = Utility.formatNumber(self.post.commentCount!)
            self.commentButton.setTitle("  " + cc, forState: .Normal)
        } else {
            self.commentButton.setTitle(nil, forState: .Normal)
        }
        self.commentButton.sizeToFit()
    }
    
    override func showDraw() {
        self.showPost(nil)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
