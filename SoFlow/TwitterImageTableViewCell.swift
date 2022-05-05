//
//  TwitterImageTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 04/06/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class TwitterImageTableViewCell: TwitterTableViewCell {

    @IBOutlet var mainImageView: UIView!
    @IBOutlet var imageViewHeight: NSLayoutConstraint!
    

    override func setPost(post: Post, signedInUser: SignedInUser) {
        let p = post as! TwitterPost
        if p.mediaArray != nil {
            let string = Utility.getStringForNibFromMediaArrayCount(p.mediaArray!.count)
            let view = NSBundle.mainBundle().loadNibNamed(string, owner: self, options: nil)[0] as! ImageView
            view.frame.size = mainImageView.frame.size
            view.setMediaArray(p.mediaArray!, cell: self, constraint: imageViewHeight, max: true)
            for s in mainImageView.subviews {
                let subView = s 
                subView.removeFromSuperview()
            }
            self.mainImageView.insertSubview(view, atIndex: 0)
        }
        super.setPost(post, signedInUser: signedInUser)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
