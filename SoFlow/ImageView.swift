//
//  TwitterImageView.swift
//  SoFlow
//
//  Created by Ben Gray on 16/06/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import SDWebImage


class ImageView: UIView {

    @IBOutlet var imageView1: UIImageView!
    @IBOutlet var imageView2: UIImageView!
    @IBOutlet var imageView3: UIImageView!
    @IBOutlet var imageView4: UIImageView!
    @IBOutlet var imageView5: UIImageView!
    @IBOutlet var imageView6: UIImageView!
    @IBOutlet var imageView7: UIImageView!
    @IBOutlet var imageView8: UIImageView!
    @IBOutlet var imageView9: UIImageView!
    @IBOutlet var imageView10: UIImageView!
    @IBOutlet var videoButton: UIButton!
    var media: [Media]!
    var cell: UITableViewCell!
    
    func setMediaArray(media: [Media], cell: UITableViewCell, constraint: NSLayoutConstraint, max: Bool) {
        self.media = media
        self.cell = cell
        constraint.constant = Utility.constraintHeightForImageViewFromMediaArray(media, max: max)
        let imageViews = [
            imageView1,
            imageView2,
            imageView3,
            imageView4,
            imageView5,
            imageView6,
            imageView7,
            imageView8,
            imageView9,
            imageView10
        ]
        for (i, m) in media.enumerate() {
            if i < imageViews.count {
                imageViews[i].backgroundColor = separatorColour
                if m.type != MediaType.Video {
                    if let lp = m as? LibraryPhoto {
                        imageViews[i].image = lp.image
                    } else {
                        imageViews[i].sd_setImageWithURL(m.url)
                    }
                    imageViews[i].addTap(cell, action: "showImage:")
                } else {
                    if let lp = m as? LibraryPhoto {
                        imageViews[i].image = lp.image
                    } else {
                        if m.thumbnail != nil {
                            imageViews[i].sd_setImageWithURL(m.thumbnail!)
                        }
                    }
                }
            }
        }
        if self.media.count == 1 {
            if self.media[0].type == MediaType.Video {
                videoButton.hidden = false
                self.videoButton.addTarget(cell, action: "showVideo", forControlEvents: .TouchUpInside)
                self.videoButton.layer.borderWidth = self.videoButton.frame.height / 27
                self.videoButton.layer.borderColor = tintColour.CGColor
                self.videoButton.layer.cornerRadius = self.videoButton.frame.height / 2
                self.videoButton.clipsToBounds = true
            } else {
                videoButton.hidden = true
            }
        }
    }
    
}
