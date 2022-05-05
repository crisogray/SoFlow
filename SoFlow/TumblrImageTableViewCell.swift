//
//  TumblrImageTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 03/07/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class TumblrImageTableViewCell: TumblrTableViewCell {

    @IBOutlet var mainImageView: ImageView!
    @IBOutlet var imageViewHeight: NSLayoutConstraint!
    @IBOutlet var captionLabel: UILabel!
    @IBOutlet var captionLabelSpacing: NSLayoutConstraint!
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        var mediaArray: [TumblrMedia]!
        if let p = post as? TumblrLinkPost {
            mediaArray = p.photos
            captionLabel.text = p.description
        } else {
            let p = post as! TumblrImagePost
            mediaArray = p.mediaArray
            if p.caption == "" || p.caption == nil {
                captionLabel.text = nil
                captionLabelSpacing.constant = 0
            } else {
                captionLabel.text = p.caption
                captionLabelSpacing.constant = 8
            }
        }
        if mediaArray != nil {
            let string = Utility.getStringForNibFromMediaArrayCount(mediaArray.count)
            let view = NSBundle.mainBundle().loadNibNamed(string, owner: self, options: nil)[0] as! ImageView
            view.frame.size = mainImageView.frame.size
            view.setMediaArray(mediaArray!, cell: self, constraint: imageViewHeight, max: true)
            for s in mainImageView.subviews {
                let subView = s 
                subView.removeFromSuperview()
            }
            mainImageView.insertSubview(view, atIndex: 0)
        }
        super.setPost(post, signedInUser: signedInUser)
    }
    
    override func showDraw() {
        self.captionLabel.textColor = UIColor.whiteColor()
        super.showDraw()
    }
    
    override func retractDraw() {
        self.captionLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        super.retractDraw()
    }

}
