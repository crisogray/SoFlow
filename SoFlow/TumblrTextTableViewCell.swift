//
//  TumblrTextTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 03/07/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class TumblrTextTableViewCell: TumblrTableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var titleLabelSpacing: NSLayoutConstraint!
    @IBOutlet var bodyLabel: UILabel!
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        let p = post as! TumblrTextPost
        titleLabel.text = p.title
        bodyLabel.text = p.body
        super.setPost(post, signedInUser: signedInUser)
    }

    override func showDraw() {
        self.titleLabel.textColor = UIColor.whiteColor()
        self.bodyLabel.textColor = UIColor.whiteColor()
        super.showDraw()
    }
    
    override func retractDraw() {
        self.titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        self.bodyLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        super.retractDraw()
    }
    

}
