//
//  TumblrLinkTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 03/07/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class TumblrLinkTableViewCell: TumblrImageTableViewCell {

    @IBOutlet var titleLabel: UILabel!
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        let p = post as! TumblrLinkPost
        self.titleLabel.text = p.title
        if self.captionLabel.text == nil || self.captionLabel.text == "" {
            self.captionLabel.text = p.url!.absoluteString
        } else {
            self.captionLabel.text! += "\n\n\(p.url!.absoluteString)"
        }
        super.setPost(post, signedInUser: signedInUser)
    }
    
    func showLink() {
        let p = post as! TumblrLinkPost
        if self.del != nil {
            Utility.openUrl(p.url, del: self.del!)
        }
    }
    
    override func showDraw() {
        self.titleLabel.textColor = UIColor.whiteColor()
        super.showDraw()
    }
    
    override func retractDraw() {
        self.titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        super.retractDraw()
    }

}
