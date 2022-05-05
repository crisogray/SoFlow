//
//  TumblrQuoteTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 03/07/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class TumblrQuoteTableViewCell: TumblrTableViewCell {

    @IBOutlet var quoteLabel: UILabel!
    @IBOutlet var sourceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        let p = post as! TumblrQuotePost
        self.quoteLabel.text = "\"\(p.text)\""
        self.sourceLabel.text = "~ " + p.sourceTitle
        super.setPost(post, signedInUser: signedInUser)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
