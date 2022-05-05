//
//  TwitterQuoteTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 08/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class TwitterQuoteTableViewCell: TwitterTableViewCell {

    @IBOutlet var quoteView: TwitterQuoteView!
    var quote: TwitterPost!
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        let p = post as! TwitterPost
        self.quote = p.quotedStatus!
        self.quoteView.messageLabel.text = self.quote.text
        self.quoteView.setPost(quote, cell: self)
        if quote.userMentions != nil {
            if p.userMentions != nil {
                for userMention in quote.userMentions! {
                    p.userMentions!.append(userMention)
                }
            } else {
                p.userMentions = quote.userMentions!
            }
        }
        super.setPost(post, signedInUser: signedInUser)
    }
    
    func showQuoteUser() {
        if self.del != nil {
            if quote.from != nil {
                let u = SignedInUser(client: signedInUser.client, user: quote.from!, clientUser: signedInUser.clientUser)
                self.del!.showUser(u)
            }
        }
    }

    @IBAction func showVideo() {
        if self.del != nil {
            self.del!.showVideo(self.quote.media!.url)
        }
    }
    
    override func showDraw() {
        self.quoteView.layer.borderColor = UIColor.whiteColor().CGColor
        self.quoteView.messageLabel.textColor = UIColor.whiteColor()
        self.quoteView.messageLabel.tintColor = UIColor.whiteColor()
        self.quoteView.messageLabel.text = self.quoteView.messageLabel.text
        self.quoteView.nameLabel.textColor = UIColor.whiteColor()
        self.quoteView.usernameLabel.textColor = UIColor.whiteColor()
        super.showDraw()
    }
    
    override func retractDraw() {
        self.quoteView.layer.borderColor = separatorColour.CGColor
        self.quoteView.messageLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        self.quoteView.messageLabel.tintColor = tintColour
        self.quoteView.messageLabel.text = self.quoteView.messageLabel.text
        self.quoteView.nameLabel.textColor = UIColor.blackColor()
        self.quoteView.usernameLabel.textColor = UIColor.darkGrayColor()
        super.retractDraw()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
