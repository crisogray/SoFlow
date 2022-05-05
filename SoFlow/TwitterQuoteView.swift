//
//  TwitterView.swift
//  SoFlow
//
//  Created by Ben Gray on 27/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class TwitterQuoteView: QuoteView {

    @IBOutlet var usernameLabel: UILabel!
    
    func setPost(quote: TwitterPost, cell: TwitterQuoteTableViewCell) {
        super.setPost(quote, cell: cell)
        self.usernameLabel.text = "@" + self.quote.from!.username!
    }
    
    override func setParentCell(cell: PostTableViewCell) {
        let cell = self.cell as! TwitterQuoteTableViewCell
        self.messageLabel.urlLinkTapHandler = cell.messageLabel.urlLinkTapHandler
        self.messageLabel.userHandleLinkTapHandler = cell.messageLabel.userHandleLinkTapHandler
        self.messageLabel.hashtagLinkTapHandler = cell.messageLabel.hashtagLinkTapHandler
        self.usernameLabel.addTap(self.cell, action: "showQuoteUser")
        super.setParentCell(cell)
    }

}
