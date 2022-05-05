//
//  InstagramCountsTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 23/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class InstagramCountsTableViewCell: CountsTableViewCell {

    @IBOutlet var tagButtonWidth: NSLayoutConstraint!
    var instagramImageView: UIImageView!
    var tagsShown = false
    
    func setPost(post: Post, tableView: UITableView, imageView: UIImageView) {
        super.setPost(post, tableView: tableView)
        self.instagramImageView = imageView
        let p = self.post as! InstagramPost
        if p.photoTags!.isEmpty {
            self.tagButtonWidth.constant = 0
        } else {
            self.tagButtonWidth.constant = 36
        }
    }
    
    @IBAction func toggleTags(sender: AnyObject) {
        let p = self.post as! InstagramPost
        if !self.tagsShown {
            for (i, tag) in p.photoTags!.enumerate() {
                let button = UIButton()
                button.tag = i
                button.addTarget(self, action: "showTagUser:", forControlEvents: .TouchUpInside)
                button.setTitle("  " + tag.user.username! + "  ", forState: .Normal)
                button.tintColor = tintColour
                button.backgroundColor = UIColor(white: 0, alpha: 0.8)
                button.titleLabel!.font = UIFont.systemFontOfSize(13)
                button.sizeToFit()
                button.layer.cornerRadius = button.frame.height / 2
                button.clipsToBounds = true
                let size = self.instagramImageView.frame.size
                button.center = CGPointMake(size.width * tag.x, size.height * tag.y)
                self.instagramImageView.addSubview(button)
            }
            self.tagsShown = true
        } else {
            self.removeTags()
            self.tagsShown = false
        }
    }
    
    func showTagUser(sender: UIButton) {
        let p = self.post as! InstagramPost
        let u = p.photoTags![sender.tag].user
        let user = SignedInUser(client: self.post.signedInUser.client, user: u, clientUser: self.post.signedInUser.clientUser)
        self.del!.showUser(user)
    }
    
    func removeTags() {
        for v in self.instagramImageView.subviews {
            if let _ = v as? UIButton {
                v.removeFromSuperview()
            }
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
