//
//  SoundCloudTrackSummaryTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 02/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class SoundCloudTrackSummaryTableViewCell: PostTableViewCell {

    @IBOutlet var artworkImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var commentButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setPost(post: Post, signedInUser: SignedInUser) {
        super.setPost(post, signedInUser: signedInUser)
        let p = post as! SoundCloudPost
        self.titleLabel.text = p.title
        self.artworkImageView.sd_setImageWithURL(p.media!.url)
        self.setLabelText()
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
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
