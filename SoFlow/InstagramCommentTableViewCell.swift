//
//  InstragramCommentTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 07/09/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class InstagramCommentTableViewCell: PostTableViewCell {
    
    var comment: Comment!
    @IBOutlet var messageLabel: KILabel!
    
    override func setPost(post: Post, signedInUser: SignedInUser) {
        super.setPost(post, signedInUser: signedInUser)
        self.comment = post as! Comment
        self.messageLabel.userHandleLinkTapHandler = {
            (label, string, range) -> Void in
            if !changingViewController {
                changingViewController = true
                let urlString = Instagram["base_url"]! + "users/search"
                let params = ["q" : string, "count" : "1"]
                signedInUser.client.get(urlString, parameters: params, success: {
                    (data, response) -> Void in
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let data = json["data"] as! NSArray
                    if data.count > 0 {
                        let d = data[0] as! NSDictionary
                        let u = Utility.instagramUserFromDictionary(d)
                        let user = SignedInUser(client: signedInUser.client, user: u, clientUser: signedInUser.clientUser)
                        let profileViewController = ProfileTableViewController(user: user)
                        if self.del != nil {
                            self.del!.pushViewController(profileViewController)
                            changingViewController = false
                        }
                    }
                    }, failure: {
                        (error) -> Void in
                        changingViewController = false
                        Utility.handleError(error, message: "Error Getting User")
                })
            }
        }
        self.messageLabel.urlLinkTapHandler = {
            (label, string, range) -> Void in
            let url = NSURL(string: string)!
            if self.del != nil {
                Utility.openUrl(url, del: self.del!)
            }
        }
        self.messageLabel.hashtagLinkTapHandler = {
            (label, string, range) -> Void in
            let s = String(string.characters.dropFirst()).lowercaseString
            let urlString = Instagram["base_url"]! + "tags/\(s)/media/recent"
            let params = ["count" : "200"]
            let postsViewController = PostsTableViewController(urls: [urlString], params: [params], signedInUsers: [signedInUser], title: string)
            if self.del != nil {
                self.del!.pushViewController(postsViewController)
            }
        }
        self.messageLabel.text = self.comment.message
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
