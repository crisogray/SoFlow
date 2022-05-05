//
//  FacebookLinkTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 09/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class FacebookLinkTableViewCell: FacebookTableViewCell {

    @IBOutlet var linkImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.linkImageView.addTap(self, action: "openLink")
        self.linkImageView.backgroundColor = separatorColour
    }
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        super.setPost(post, signedInUser: signedInUser)
        let media = post.media! as! FacebookLink
        self.linkImageView.sd_setImageWithURL(media.url)
    }
    
    func openLink() {
        let media = self.post.media! as! FacebookLink
        let viewController = WebViewController(url: media.linkUrl)
        if self.del != nil {
            self.del!.pushViewController(viewController)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
