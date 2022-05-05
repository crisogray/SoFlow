//
//  TwitterQuoteTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 08/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class FacebookEmbeddedPostTableViewCell: FacebookTableViewCell {
    
    @IBOutlet var quoteView: QuoteView!
    var quote: FacebookPost!
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        let p = post as! FacebookPost
        self.quote = p.embeddedPost!
        let caption = Utility.facebookCaptionFromPost(self.quote)
        if self.quote.message == nil && caption == nil {
            self.quoteView.messageLabel.text = nil
        } else if self.quote.message == nil && caption != nil {
            self.quoteView.messageLabel.text = caption!
        } else if self.quote.message != nil && caption == nil {
            self.quoteView.messageLabel.text = self.quote.message
        } else if self.quote.message != nil && caption != nil {
            self.quoteView.messageLabel.text = self.quote.message! + "\r" + caption!
        }
        p.description = nil
        if p.story != nil {
            p.name = p.story!
        }
        self.quoteView.setPost(self.quote, cell: self)
        super.setPost(p, signedInUser: signedInUser)
        
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
        super.showDraw()
    }
    
    override func retractDraw() {
        self.quoteView.layer.borderColor = separatorColour.CGColor
        self.quoteView.messageLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        self.quoteView.messageLabel.tintColor = tintColour
        self.quoteView.messageLabel.text = self.quoteView.messageLabel.text
        self.quoteView.nameLabel.textColor = UIColor.blackColor()
        super.retractDraw()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
