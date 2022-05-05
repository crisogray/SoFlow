//
//  SoundCloudCommentTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 09/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class SoundCloudCommentTableViewCell: PostTableViewCell {

    @IBOutlet var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        super.setPost(post, signedInUser: signedInUser)
        let p = self.post as! Comment
        self.messageLabel.text = p.message
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
