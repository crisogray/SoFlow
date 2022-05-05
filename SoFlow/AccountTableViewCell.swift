//
//  AccountTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 27/11/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class AccountTableViewCell: UITableViewCell {

    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var serviceLabel: UILabel!
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    var user: SignedInUser!
    var gradientLayer: CAGradientLayer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.height / 2
        self.profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
        self.profileImageView.layer.borderWidth = 2
        self.gradientLayer = CAGradientLayer()
        //self.layer.insertSublayer(self.gradientLayer, atIndex: 0)
    }

    func setAccountsViewController(accountsViewController: AccountsTableViewController, user: SignedInUser) {
        self.user = user
        //let s = user.clientUser.type.rawValue
        //self.serviceLabel.text = s
        self.heightConstraint.constant = 150
        if self.user.clientUser.profilePictureUrl != nil {
            if self.user.clientUser.profilePictureLargeUrl != nil {
                self.profileImageView.sd_setImageWithURL(self.user.clientUser.profilePictureLargeUrl)
            } else {
                var url: NSURL!
                switch user.user.type {
                case .Facebook:
                    url = Utility.facebookProfilePictureFromId(self.user.clientUser.id, large: true)
                    self.user.clientUser.profilePictureLargeUrl = url
                case .Twitter:
                    url = Utility.twitterLargeProfilePictureUrlFromUrl(self.user.clientUser.profilePictureUrl!)
                    self.user.clientUser.profilePictureLargeUrl = url
                default:
                    url = self.user.clientUser.profilePictureUrl!
                }
                self.profileImageView.sd_setImageWithURL(url)
            }
        } else {
            self.profileImageView.image = nil
        }
        /*self.serviceLabel.textColor = UIColor.whiteColor()
        var colours = [
            "Facebook" : [
                UIColor(red: 0.23, green: 0.35, blue: 0.6, alpha: 1).CGColor,
                UIColor(red: 0.32, green: 0.48, blue: 0.82, alpha: 1).CGColor
            ],
            "Twitter" : [
                UIColor(red: 0, green: 0.55, blue: 0.95, alpha: 1).CGColor,
                UIColor(red: 0.3, green: 0.69, blue: 0.98, alpha: 1).CGColor
            ],
            "Instagram" : [
                UIColor(red: 0.18, green: 0.37, blue: 0.52, alpha: 1).CGColor,
                UIColor(red: 0.24, green: 0.49, blue: 0.7, alpha: 1).CGColor
            ]
        ]
        self.gradientLayer.frame.size = CGSizeMake(w, self.heightConstraint.constant)
        self.gradientLayer.colors = colours[s]
        dump(self.user)
        if self.user.clientUser.type != .Instagram || self.user.clientUser.type != .Tumblr {
            self.nameLabel.text = self.user.clientUser.name!
        } else {
            self.nameLabel.text = self.user.clientUser.username!
        }*/
        self.backgroundColor = colours[self.user.clientUser.type]!
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.height / 2
    }
    
}
