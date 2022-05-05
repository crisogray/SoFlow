//
//  PhotoCollectionViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 16/09/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var videoButton: UIButton!
    var post: Post!
    var media: Media!
    var del: CellDelegate!
    var canShowPost = true
    
    override func awakeFromNib() {
        self.imageView.backgroundColor = separatorColour
        self.videoButton.layer.cornerRadius = self.videoButton.frame.height / 2
        self.videoButton.clipsToBounds = true
    }
    
    func setPost(post: Post) {
        self.post = post
        if self.post.media != nil {
            self.setMedia(self.post.media!)
        } else {
            self.videoButton.hidden = true
        }
        self.addLongPress(self, action: "showPost:")
    }
    
    func setMedia(media: Media) {
        self.media = media
        if self.media.type == MediaType.Image {
            self.videoButton.hidden = true
            if let m = self.media as? LibraryPhoto {
                self.setImage(NSURL(), image: m.image)
                self.addLongPress(self, action: "showImage")
            } else {
                self.setImage(self.media.url!, image: nil)
                self.addTap(self, action: "showImage")
            }
        } else if self.media.type == .Video {
            if let m = self.media as? LibraryPhoto {
                self.setImage(NSURL(), image: m.image)
                self.addLongPress(self, action: "showVideo")
            } else {
                self.setImage(self.media.thumbnail!, image: nil)
                self.addTap(self, action: "showVideo")
            }
            self.videoButton.hidden = false
            self.videoButton.addTarget(self, action: "showVideo", forControlEvents: .TouchUpInside)
        }
    }
    
    func setImage(url: NSURL, image: UIImage?) {
        if image == nil {
            self.imageView.sd_setImageWithURL(url)
        } else {
            self.imageView.image = image
        }
    }
    
    func showVideo() {
        if let m = self.media as? LibraryPhoto {
            if m.type == .Video {
                let videoViewController = VideoViewController(asset: m.asset!)
                self.del.pushViewController(videoViewController)
            }
        } else {
            self.del.showVideo(self.post.media!.url)
        }
    }
    
    func showImage() {
        if self.imageView.image != nil {
            self.del.showImage(self.imageView.image!, view: self.imageView)
        }
    }
    
    func showPost(gestureRecogniser: UILongPressGestureRecognizer) {
        if gestureRecogniser.state == .Began {
            let postViewController = PostTableViewController(post: self.post)
            self.del!.pushViewController(postViewController)
        }
    }
    
    
}
