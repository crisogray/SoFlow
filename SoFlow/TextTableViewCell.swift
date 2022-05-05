//
//  TextTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 30/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import KILabel

class TextTableViewCell: UITableViewCell {
    
    @IBOutlet var mainLabel: KILabel!
    var del: CellDelegate!
    var post: Post!
    
    override func awakeFromNib() {
        self.mainLabel.tintColor = tintColour
    }
    
    func setLabelText(text: String, post: Post) {
        self.mainLabel.text = text
        self.post = post
        self.mainLabel.urlLinkTapHandler = {
            (label, string, range) -> Void in
            let url = NSURL(string: string)!
            if self.del != nil {
                Utility.openUrl(url, del: self.del!)
            }
        }
        self.mainLabel.userHandleLinkTapHandler = {
            (label, string, range) -> Void in
            switch self.post.type {
            case .Twitter:
                var s: String = String(string.characters.dropFirst())
                if s.rangeOfString(".") != nil {
                    s = s.componentsSeparatedByString(".")[0]
                }
                let p = self.post as! TwitterPost
                var done = false
                if p.userMentions != nil {
                    for t in p.userMentions! {
                        if !done {
                            if t.user.username!.lowercaseString == s.lowercaseString {
                                done = true
                                let signedInUser = SignedInUser(client: self.post.signedInUser.client, user: t.user, clientUser: self.post.signedInUser.clientUser)
                                if self.del != nil {
                                    self.del!.showUser(signedInUser)
                                }
                            }
                        }
                    }
                }
            case .Instagram:
                if !changingViewController {
                    changingViewController = true
                    let urlString = Instagram["base_url"]! + "users/search"
                    let params = ["q" : string, "count" : "1"]
                    self.post.signedInUser.client.get(urlString, parameters: params, success: {
                        (data, response) -> Void in
                        let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                        let data = json["data"] as! NSArray
                        if data.count > 0 {
                            let d = data[0] as! NSDictionary
                            let u = Utility.instagramUserFromDictionary(d)
                            let user = SignedInUser(client: self.post.signedInUser.client, user: u, clientUser: self.post.signedInUser.clientUser)
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
            default:
                print("okidoki")
            }
        }
        self.mainLabel.hashtagLinkTapHandler = {
            (label, string, range) -> Void in
            switch self.post.type {
            case .Twitter:
                let urlString = Twitter["base_url"]! + "search/tweets.json"
                let params = ["count" : "200", "q" : string]
                let postsViewController = PostsTableViewController(urls: [urlString], params: [params], signedInUsers: [self.post.signedInUser], title: string)
                self.del.pushViewController(postsViewController)
            case .Instagram:
                let s = String(string.characters.dropFirst()).lowercaseString
                let urlString = Instagram["base_url"]! + "tags/\(s)/media/recent"
                let params = ["count" : "200"]
                let postsViewController = PostsTableViewController(urls: [urlString], params: [params], signedInUsers: [self.post.signedInUser], title: string)
                self.del.pushViewController(postsViewController)
            case .Tumblr:
                let urlString = Tumblr["base_url"]! + "tagged"
                let params = ["filter" : "text", "tag" : "\(String(string.lowercaseString.characters.dropFirst()))", "api_key" : Tumblr["key"]!, "notes_info" : "true"]
                let postsViewController = PostsTableViewController(urls: [urlString], params: [params], signedInUsers: [self.post.signedInUser], title: string)
                self.del.pushViewController(postsViewController)
            default:
                print("okidoki")
            }
        }
    }

}
