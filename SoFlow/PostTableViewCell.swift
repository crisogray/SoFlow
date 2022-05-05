//
//  PostTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 10/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import SDWebImage

protocol CellDelegate {
    func pushViewController(viewController: UIViewController)
    func presentViewController(viewController: UIViewController)
    func showImage(image: UIImage, view: UIView)
    func showVideo(url: NSURL)
    func showUser(user: SignedInUser)
}

class PostTableViewCell: UITableViewCell {

    @IBOutlet var profilePictureImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var serviceTypeImageView: UIImageView!
    @IBOutlet var videoButton: UIButton!
    @IBOutlet var drawerHeight: NSLayoutConstraint!
    @IBOutlet var heightView: UIView!
    var post: Post!
    var signedInUser: SignedInUser!
    var del: CellDelegate? = nil
    var heightForEstimate: CGFloat?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if self.drawerHeight != nil {
            self.retractDraw()
        }
        self.clipsToBounds = true
        self.selectionStyle = .None
        if self.profilePictureImageView != nil {
            self.profilePictureImageView.layer.cornerRadius = self.profilePictureImageView.frame.height / 2 // 12 // 6.5
            self.profilePictureImageView.clipsToBounds = true
            self.profilePictureImageView.addTap(self, action: "showUser")
            self.profilePictureImageView.backgroundColor = separatorColour
        }
        self.nameLabel.addTap(self, action: "showUser")
        if self.videoButton != nil {
            self.videoButton.layer.cornerRadius = self.videoButton.frame.height / 2
            self.videoButton.clipsToBounds = true
        }
        self.addLongPress(self, action: "showPost:")
        self.contentView.userInteractionEnabled = false
    }
    
    func setPost(post: Post, signedInUser: SignedInUser) {
        self.signedInUser = signedInUser
        self.post = post
        self.nameLabel.text = nil
        if self.dateLabel != nil {
            self.dateLabel.text = self.post.date.shortTimeAgoSinceNow()
        }
        if self.post.from != nil {
            if self.profilePictureImageView != nil {
                if self.post.from!.profilePictureUrl != nil {
                    self.profilePictureImageView.image = nil
                    self.profilePictureImageView.sd_setImageWithURL(self.post.from!.profilePictureUrl!)
                }
            }
            if post.type == Service.Instagram || post.type == Service.SoundCloud {
                self.nameLabel.text = self.post.from!.username!
            } else {
                self.nameLabel.text = self.post.from!.name!
            }
            self.nameLabel.sizeToFit()
        }
        self.layoutIfNeeded()
        //print(self.frame.height - self.post.estimatedHeight!)
        //print(self.post.type.rawValue)
    }
    
    func showUser() {
        if post.from != nil {
            let u = SignedInUser(client: self.signedInUser.client, user: self.post.from!, clientUser: self.signedInUser.clientUser)
            self.del!.showUser(u)
        }
    }
    
    func showPost(gestureRecogniser: UILongPressGestureRecognizer?) {
        if gestureRecogniser != nil {
            if gestureRecogniser!.state == .Began {
                let postViewController = PostTableViewController(post: self.post)
                self.del!.pushViewController(postViewController)
            }
        } else {
            let postViewController = PostTableViewController(post: self.post)
            self.del!.pushViewController(postViewController)
        }
    }
    
    func showDraw() {
        if self.drawerHeight != nil {
            let h: CGFloat = 32
            var colours = [CGColor]()
            switch self.post.type {
            case .Facebook:
                colours = [
                    UIColor(red: 0.23, green: 0.35, blue: 0.6, alpha: 1).CGColor,
                    UIColor(red: 0.32, green: 0.48, blue: 0.82, alpha: 1).CGColor
                ]
            case .Twitter:
                colours = [
                    UIColor(red: 0, green: 0.55, blue: 0.95, alpha: 1).CGColor,
                    UIColor(red: 0.3, green: 0.69, blue: 0.98, alpha: 1).CGColor
                ]
            case .Instagram:
                colours = [
                    UIColor(red: 0.18, green: 0.37, blue: 0.52, alpha: 1).CGColor,
                    UIColor(red: 0.24, green: 0.49, blue: 0.7, alpha: 1).CGColor
                ]
            case .Tumblr:
                colours = [
                    UIColor(red: 0.15, green: 0.23, blue: 0.33, alpha: 1).CGColor,
                    UIColor(red: 0.25, green: 0.39, blue: 0.56, alpha: 1).CGColor
                ]
            default:
                print("okidoki")
            }
            if self.drawerHeight.constant != h {
                self.layoutIfNeeded()
                self.drawerHeight.constant = h
                self.nameLabel.textColor = UIColor.whiteColor()
                self.dateLabel.textColor = UIColor.whiteColor()
                let layer = CAGradientLayer()
                layer.frame.size = CGSizeMake(w, self.heightView.frame.height + h)
                self.layer.insertSublayer(layer, atIndex: 0)
                layer.opacity = 0
                layer.colors = colours
                UIView.animateWithDuration(animationDuration, animations: {
                    () -> Void in
                    self.layoutIfNeeded()
                })
                let fadeAnimation = CABasicAnimation(keyPath: "opacity")
                fadeAnimation.fromValue = 0
                fadeAnimation.toValue = 1
                fadeAnimation.duration = animationDuration
                fadeAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
                layer.addAnimation(fadeAnimation, forKey: "opacity")
                layer.opacity = 1
            } else {
                self.retractDraw()
            }
        }
    }
    
    func retractDraw() {
        if self.drawerHeight != nil {
            self.layoutIfNeeded()
            self.drawerHeight.constant = 0
            self.nameLabel.textColor = UIColor.blackColor()
            self.dateLabel.textColor = UIColor.lightGrayColor()
            UIView.animateWithDuration(animationDuration) {
                () -> Void in
                self.layoutIfNeeded()
            }
            for layer in self.layer.sublayers! {
                if layer.isKindOfClass(CAGradientLayer.classForCoder()) {
                    let fadeAnimation = CABasicAnimation(keyPath: "opacity")
                    fadeAnimation.fromValue = 1
                    fadeAnimation.toValue = 0
                    fadeAnimation.duration = animationDuration
                    fadeAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
                    layer.addAnimation(fadeAnimation, forKey: "opacity")
                    layer.opacity = 0
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(animationDuration * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                        () -> Void in
                        layer.removeFromSuperlayer()
                    })
                }
            }
        }
    }
    
    override func prepareForReuse() {
        self.clipsToBounds = true
        if self.drawerHeight != nil {
            self.retractDraw()
        }
    }
    
    func showImage(sender: UITapGestureRecognizer) {
        let iView = sender.view as! UIImageView
        if iView.image != nil {
            self.del!.showImage(iView.image!, view: iView)
        }
    }
    
}
