//
//  UserTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 10/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import DateTools
import SDWebImage

class UserTableViewCell: UITableViewCell {

    @IBOutlet var primaryImageView: UIImageView!
    @IBOutlet var secondLabel: UILabel!
    @IBOutlet var secondLabelHeight: NSLayoutConstraint!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var profilePictureImageView: UIImageView!
    @IBOutlet var verifiedImageView: UIImageView!
    @IBOutlet var verifiedImageViewWidth: NSLayoutConstraint!
    var user: User!
    var signedInUser: SignedInUser?
    var post: Post?
    var del: CellDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height / 2
        self.profilePictureImageView.backgroundColor = separatorColour
        self.verifiedImageViewWidth.constant = 0
    }
    
    func setPost(post: Post) {
        self.setUser(post.from!)
        self.profilePictureImageView.addTap(self, action: "showUser")
        self.nameLabel.addTap(self, action: "showUser")
        self.secondLabel.addTap(self, action: "showUser")
        self.signedInUser = post.signedInUser
        self.post = post
    }
    
    func setSignedInUser(u: SignedInUser) {
        self.signedInUser = u
        self.setUser(u.user)
        if u.primary != nil {
            if u.primary! {
                self.primaryImageView.image = UIImage(named: "Star Full Green 16px")
            } else {
                self.primaryImageView.image = nil
            }
        }
    }
    
    func setUser(user: User) {
        self.primaryImageView.image = UIImage(named: user.type.rawValue + " 24px")
        self.verifiedImageViewWidth.constant = 0
        self.verifiedImageView.image = UIImage(named: "Verified 16px")
        self.user = user
        self.profilePictureImageView.sd_setImageWithURL(self.user.profilePictureUrl)
        switch user.type {
        case .Facebook:
            self.nameLabel.text = self.user.name!
            if let u = self.user as? FacebookPage {
                if u.category != nil {
                    secondLabelHeight.constant = 20
                    secondLabel.text = u.category!
                    return
                }
            }
            let u = self.user as! FacebookUser
            if u.verified != nil {
                if u.verified! {
                    self.verifiedImageViewWidth.constant = 20
                }
            }
            secondLabel.text = nil
            secondLabelHeight.constant = 0
        case .Twitter:
            nameLabel.text = self.user.name!
            if let u = self.user as? TwitterUser {
                secondLabelHeight.constant = 20
                secondLabel.text = "@" + self.user.username!
                if u.verified! {
                    self.verifiedImageViewWidth.constant = 16
                }
            } else {
                secondLabelHeight.constant = 0
                secondLabel.text = nil
            }
        case .Instagram:
            nameLabel.text = self.user.username!
            if self.user.name != "" {
                nameLabel.text = self.user.name!
                secondLabelHeight.constant = 20
                secondLabel.text = self.user.username!
            } else {
                nameLabel.text = self.user.username!
                secondLabel.text = nil
                secondLabelHeight.constant = 0
            }
        case .Tumblr:
            nameLabel.text = user.name
            if user.username != nil && user.username != "" {
                secondLabelHeight.constant = 20
                secondLabel.text = user.username!
            } else {
                secondLabel.text = nil
                secondLabelHeight.constant = 0
            }
        case .SoundCloud:
            nameLabel.text = user.username!
            if user.name != nil && user.name != "" {
                secondLabelHeight.constant = 20
                secondLabel.text = user.name!
            } else {
                secondLabel.text = nil
                secondLabelHeight.constant = 0
            }
        default:
            print("okidoki", terminator: "")
        }
        /*if founderIds[self.user.type]!.contains(self.user.id) {
            self.verifiedImageView.image = UIImage(named: "Verified Me 16px")
            self.verifiedImageViewWidth.constant = 22
        }*/
    }
    
    func showUser() {
        if self.post!.from != nil {
            let u = SignedInUser(client: self.post!.signedInUser.client, user: self.post!.from!, clientUser: self.post!.signedInUser.clientUser)
            self.del!.showUser(u)
        }
    }

}
