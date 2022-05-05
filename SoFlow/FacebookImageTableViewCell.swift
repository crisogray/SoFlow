//
//  FacebookImageTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 09/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class FacebookImageTableViewCell: FacebookTableViewCell {

    @IBOutlet var imageViewHeight: NSLayoutConstraint!
    @IBOutlet var mainImageView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainImageView.backgroundColor = separatorColour
    }
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        let p = post as! FacebookPost
        var mediaArray = [Media]()
        if p.photos != nil {
            mediaArray = p.photos!
            self.mainImageView.addTap(self, action: "showImage:")
        } else {
            if p.media != nil {
                mediaArray = [p.media!]
            }
        }
        let string = Utility.getStringForNibFromMediaArrayCount(mediaArray.count)
        let view = NSBundle.mainBundle().loadNibNamed(string, owner: self, options: nil)[0] as! ImageView
        view.frame.size = mainImageView.frame.size
        view.setMediaArray(mediaArray, cell: self, constraint: self.imageViewHeight, max: true)
        for s in mainImageView.subviews {
            let subView = s
            subView.removeFromSuperview()
        }
        self.mainImageView.insertSubview(view, atIndex: 0)
        super.setPost(post, signedInUser: signedInUser)
    }
    
    @IBAction func showVideo() {
        if self.del != nil {
            let p = self.post as! FacebookPost
            self.del!.showVideo(p.media!.url)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
