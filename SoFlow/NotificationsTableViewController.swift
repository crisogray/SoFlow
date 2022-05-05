//
//  NotificationsTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 04/12/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class NotificationsTableViewController: PostsTableViewController {

    convenience init() {
        var urls = [String]()
        var params = [Dictionary<String, AnyObject>]()
        var signedInUsers = [SignedInUser]()
        Utility.getUrlsForNotificationsTableViewController(&urls, params: &params, signedInUsers: &signedInUsers)
        self.init(urls: urls, params: params, signedInUsers: signedInUsers, title: "Notifications")
        self.getUrls()
        self.refreshDate = NSDate()
        self.firstLoad = true
    }
    
    func collectUrls() {
        var urls = [String]()
        var params = [Dictionary<String, AnyObject>]()
        var signedInUsers = [SignedInUser]()
        Utility.getUrlsForNotificationsTableViewController(&urls, params: &params, signedInUsers: &signedInUsers)
        self.urls = urls
        self.params = params
        self.signedInUsers = signedInUsers
        self.getUrls()
    }
    
    override func getUrls() {
        var numberDone = 0
        for (index, user) in self.signedInUsers.enumerate() {
            user.client.get(self.urls[index], parameters: self.params[index], success: {
                (data, response) -> Void in
                var p = [Post]()
                if user.user.type == .Facebook {
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let data = json["data"] as! NSArray
                    p = Utility.facebookNotificationsFromArray(data, signedInUser: user)
                } else {
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSArray
                    p = Utility.twitterPostsFromArray(json, signedInUser: user)
                }
                for post in p {
                    var add = true
                    for po in self.posts {
                        if po.type == post.type {
                            if po.id == post.id {
                                add = false
                            }
                        }
                    }
                    if add {
                        self.posts.append(post)
                    }
                }
                numberDone++
                if numberDone == self.urls.count {
                    self.sortAndAddPosts()
                }
            }, failure: {
                (error) -> Void in
                numberDone++
                if numberDone == self.urls.count {
                    self.sortAndAddPosts()
                }
                Utility.handleError(error, message: "Error Fetching Notifications")
            })
        }
    }
}
