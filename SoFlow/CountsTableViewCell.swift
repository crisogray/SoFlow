//
//  CountsTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 31/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import Crashlytics

class CountsTableViewCell: UITableViewCell {
    
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    var del: CellDelegate!
    var post: Post!
    var tableView: UITableView!
    
    func setPost(post: Post, tableView: UITableView) {
        self.post = post
        self.tableView = tableView
        var counts: [String: Int]!
        switch self.post.type {
        case .Facebook:
            if self.post.commentCount != nil {
                counts = ["Likes" : self.post.likeCount!, "Comments" : self.post.commentCount!]
                self.button2.addTarget(self, action: "showComments", forControlEvents: .TouchUpInside)
            } else {
                if self.post.likeCount != nil {
                    counts = ["Likes" : self.post.likeCount!]
                } else {
                    counts = [String : Int]()
                }
            }
            self.button1.addTarget(self, action: "showLikes", forControlEvents: .TouchUpInside)
        case .Twitter:
            let p = post as! TwitterPost
            counts = ["Retweets" : p.retweetCount!, "Favourites" : self.post.likeCount!]
            self.button1.addTarget(self, action: "showLikes", forControlEvents: .TouchUpInside)
        case .Instagram:
            counts = ["Likes" : self.post.likeCount!, "Comments" : self.post.commentCount!]
            self.button1.addTarget(self, action: "showLikes", forControlEvents: .TouchUpInside)
            self.button2.addTarget(self, action: "showComments", forControlEvents: .TouchUpInside)
        case .Tumblr:
            counts = ["Notes" : self.post.likeCount!]
        case .SoundCloud:
            counts = ["Likes" : self.post.likeCount!, "Comments" : self.post.commentCount!]
            self.button1.addTarget(self, action: "showLikes", forControlEvents: .TouchUpInside)
            self.button2.addTarget(self, action: "showComments", forControlEvents: .TouchUpInside)
        default:
            print("okidoki")
        }
        let buttons = [self.button1, self.button2]
        for (index, (n, i)) in counts.enumerate() {
            var text = n.uppercaseString
            if i == 1 {
                text = String(text.characters.dropLast())
            }
            let number = Utility.formatNumber(i).uppercaseString
            buttons[index].setTitle(number + " " + text, forState: .Normal)
        }
        if counts.count == 1 {
            self.button2.setTitle(nil, forState: .Normal)
        }
    }
    
    func showLikes() {
        switch self.post.type {
        case .Facebook:
            if self.post.likeCount > 0 {
                let urlString = Facebook["base_url"]! + self.post.id + "/likes"
                let usersViewController = UsersTableViewController(urls: [urlString], params: [["":""]], signedInUsers: [self.post.signedInUser], title: "Likes", pages: false, users: nil)
                if self.del != nil {
                    self.del!.pushViewController(usersViewController)
                }
            }
        case .Twitter:
            let p = self.post as! TwitterPost
            if p.retweetCount > 0 {
                let urlString = Twitter["base_url"]! + "statuses/retweeters/ids.json"
                let params = ["id" : self.post.id, "stringify_ids" : "1"]
                let usersViewController = UsersTableViewController(urls: [urlString], params: [params], signedInUsers: [self.post.signedInUser], title: "Retweets", pages: false, users: nil)
                if self.del != nil {
                    self.del!.pushViewController(usersViewController)
                }
            }
        case .Instagram:
            if post.likeCount > 0 {
                let urlString = Instagram["base_url"]! + "media/" + self.post.id + "/likes"
                let usersViewController = UsersTableViewController(urls: [urlString], params: [["":""]], signedInUsers: [self.post.signedInUser], title: "Likes", pages: false, users: nil)
                if self.del != nil {
                    self.del!.pushViewController(usersViewController)
                }
            }
        case .SoundCloud:
            if post.likeCount > 0 {
                let urlString = SoundCloud["base_url"]! + "tracks/" + self.post.id + "/favoriters"
                let usersViewController = UsersTableViewController(urls: [urlString], params: [Dictionary<String, AnyObject>()], signedInUsers: [self.post.signedInUser], title: "Likes", pages: false, users: nil)
                if self.del != nil {
                    self.del!.pushViewController(usersViewController)
                }
            }
        default:
            print("okidoki")
        }
    }
    
    func showComments() {
        if self.tableView.numberOfSections == 2 {
            let indexPath = NSIndexPath(forRow: 0, inSection: 1)
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        }
    }

}
