//
//  TwitterView.swift
//  SoFlow
//
//  Created by Ben Gray on 27/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class QuoteView: UIView {
    
    @IBOutlet var imageView: UIView!
    @IBOutlet var imageViewSpacing: NSLayoutConstraint!
    @IBOutlet var imageViewHeight: NSLayoutConstraint!
    @IBOutlet var profilePictureView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var messageLabel: KILabel!
    @IBOutlet var messageLabelHeight: NSLayoutConstraint!
    var quote: Post!
    var cell: PostTableViewCell!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clearColor()
        self.profilePictureView.layer.cornerRadius = self.profilePictureView.frame.height / 2
        self.profilePictureView.clipsToBounds = true
        self.messageLabel.tintColor = tintColour
        self.imageView.backgroundColor = separatorColour
        self.profilePictureView.backgroundColor = separatorColour
        self.layer.borderWidth = 0.5
        self.layer.borderColor = separatorColour.CGColor
        self.layer.cornerRadius = 8
    }
    
    func setPost(quote: Post, cell: PostTableViewCell) {
        self.quote = quote
        self.cell = cell
        self.setParentCell(cell)
        for s in imageView.subviews {
            let subView = s
            subView.removeFromSuperview()
        }
        if self.quote.media != nil {
            self.imageViewHeight.constant = Utility.constraintHeightForImageViewFromMediaArray([self.quote.media!], max: true)
            self.imageViewSpacing.constant = 12
            var mediaArray = [Media]()
            if let p = self.quote as? FacebookPost {
                if p.photos != nil {
                    mediaArray = p.photos!
                    self.imageView.addTap(self, action: "showImage:")
                } else {
                    if p.media != nil {
                        mediaArray = [p.media!]
                    }
                }
            } else if let p = self.quote as? TwitterPost {
                mediaArray = p.mediaArray!
            }
            let string = Utility.getStringForNibFromMediaArrayCount(mediaArray.count)
            let view = NSBundle.mainBundle().loadNibNamed(string, owner: self, options: nil)[0] as! ImageView
            view.frame.size = self.imageView.frame.size
            view.setMediaArray(mediaArray, cell: self.cell, constraint: self.imageViewHeight, max: true)
            self.imageView.insertSubview(view, atIndex: 0)
        } else {
            self.imageViewHeight.constant = 0
            self.imageViewSpacing.constant = 12
        }
        self.messageLabelHeight.constant = messageLabel.sizeThatFits(CGSizeMake(w - 96, CGFloat.max)).height
        self.profilePictureView.sd_setImageWithURL(self.quote.from!.profilePictureUrl)
        self.nameLabel.text = self.quote.from!.name
    }
    
    func setParentCell(cell: PostTableViewCell) {
        self.nameLabel.addTap(self.cell, action: "showQuoteUser")
        self.profilePictureView.addTap(self.cell, action: "showQuoteUser")
    }
    
}
