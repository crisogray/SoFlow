//
//  UserCollectionViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 23/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class UserCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var serviceTypeImageView: UIImageView!
    var signedInUser: SignedInUser!
    
    override func awakeFromNib() {
        self.serviceTypeImageView.backgroundColor = UIColor.whiteColor()
        self.serviceTypeImageView.layer.cornerRadius = self.serviceTypeImageView.frame.height / 2
        self.serviceTypeImageView.layer.borderColor = UIColor.whiteColor().CGColor
        self.serviceTypeImageView.layer.borderWidth = 2
        self.imageView.layer.cornerRadius = (((w - 2) / 2) - 16) / 4
        self.imageView.backgroundColor = separatorColour
        self.imageView.layer.borderColor = UIColor.whiteColor().CGColor
        self.imageView.layer.borderWidth = 2
    }
    
    func setUser(signedInUser: SignedInUser) {
        self.signedInUser = signedInUser
        let u = self.signedInUser.clientUser
        if u.profilePictureUrl != nil {
            if u.profilePictureLargeUrl != nil {
                self.imageView.sd_setImageWithURL(u.profilePictureLargeUrl!)
            } else {
                var url: NSURL!
                switch u.type {
                case .Facebook:
                    url = Utility.facebookProfilePictureFromId(u.id, large: true)
                    u.profilePictureLargeUrl = url
                case .Twitter:
                    url = Utility.twitterLargeProfilePictureUrlFromUrl(u.profilePictureUrl!)
                    u.profilePictureLargeUrl = url
                default:
                    url = u.profilePictureUrl!
                }
                self.imageView.sd_setImageWithURL(url)
            }
        }
        self.serviceTypeImageView.image = UIImage(named: "\(u.type.rawValue) 24px")
        switch u.type {
        case .Facebook:
            self.nameLabel.text = u.name!
        case .Twitter:
            self.nameLabel.text = "@" + u.username!
        case .Instagram:
            self.nameLabel.text = u.username!
        case .Tumblr:
            self.nameLabel.text = u.name!
        case .SoundCloud:
            self.nameLabel.text = u.username!
        default:
            print("okidoki")
        }
    }
    
    func deselectCell() {
        self.nameLabel.textColor = UIColor.darkGrayColor()
    }
    
    func selectCell() {
        self.nameLabel.textColor = UIColor.whiteColor()
    }
    
}
