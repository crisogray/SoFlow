//
//  UsersTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 11/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class UsersTableViewController: UITableViewController, UISearchBarDelegate {

    var signedInUsers: [SignedInUser]!
    var users: [SignedInUser]!
    var searchUsers: [SignedInUser]!
    var loading = true
    
    convenience init(urls: [String], params: [Dictionary<String, AnyObject>], signedInUsers: [SignedInUser], title: String!, pages: Bool, users: [SignedInUser]?) {
        self.init()
        Utility.registerCells(self.tableView)
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .Minimal
        searchBar.sizeToFit()
        if title.hasSuffix("Follows") || title.hasSuffix("Follow") {
            searchBar.placeholder = "Search Who " + title
        } else {
            searchBar.placeholder = "Search " + title
        }
        searchBar.delegate = self
        searchBar.keyboardAppearance = .Dark
        self.tableView.tableHeaderView = searchBar
        self.title = title
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.signedInUsers = signedInUsers
        if users != nil {
            self.users = users
            self.searchUsers = users
            self.loading = false
            self.tableView.reloadData()
        } else {
            self.users = [SignedInUser]()
            self.searchUsers = [SignedInUser]()
            let count = urls.count
            var numberDone = 0
            for (index, url) in urls.enumerate() {
                self.signedInUsers[index].client.get(url, parameters: params[index], success: {
                    (data, response) -> Void in
                    var tempUsers = [SignedInUser]()
                    switch signedInUsers[index].user.type {
                    case .Facebook:
                        let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                        let data = json["data"] as! NSArray
                        var u = [FacebookUser]()
                        if !pages {
                            for item in data {
                                let i = item as! NSDictionary
                                let user = Utility.facebookUserFromDictionary(i, signedInUser: signedInUsers[index])
                                u.append(user)
                            }
                        } else {
                            u = Utility.facebookPagesFromDictionary(data)
                        }
                        var users = [SignedInUser]()
                        for user in u {
                            let us = SignedInUser(client: signedInUsers[index].client, user: user, clientUser: signedInUsers[index].clientUser)
                            users.append(us)
                        }
                        tempUsers = users
                    case .Twitter:
                        if !url.hasSuffix("/ids.json") {
                            let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                            let data = json["users"] as! NSArray
                            var u = [TwitterUser]()
                            for item in data {
                                let i = item as! NSDictionary
                                let user = Utility.twitterUserFromDictionary(i)
                                u.append(user)
                            }
                            if url.hasSuffix("friends/list.json") {
                                signedInUsers[index].user.friends = u
                            } else if url.hasSuffix("followers/list.json") {
                                signedInUsers[index].user.followers = u
                            }
                            var users = [SignedInUser]()
                            for user in u {
                                let us = SignedInUser(client: signedInUsers[index].client, user: user, clientUser: signedInUsers[index].clientUser)
                                users.append(us)
                            }
                            tempUsers = users
                        } else {
                            let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                            let data = json["ids"] as! NSArray
                            var ids = String()
                            for id in data {
                                let i = id as! String
                                ids += i
                                if i != data.lastObject as! String {
                                    ids += ","
                                }
                            }
                            let urlString = Twitter["base_url"]! + "users/lookup.json"
                            let params = ["user_id" : ids]
                            signedInUsers[index].client.post(urlString, parameters: params, success: {
                                (data, response) -> Void in
                                let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSArray
                                var u = [TwitterUser]()
                                for item in json {
                                    let i = item as! NSDictionary
                                    let user = Utility.twitterUserFromDictionary(i)
                                    u.append(user)
                                }
                                var users = [SignedInUser]()
                                for user in u {
                                    let us = SignedInUser(client: signedInUsers[index].client, user: user, clientUser: signedInUsers[index].clientUser)
                                    users.append(us)
                                    var add = true
                                    for u in self.users {
                                        if us.user.type == u.user.type {
                                            if us.user.id == u.user.id {
                                                add = false
                                            }
                                        }
                                    }
                                    if add {
                                        self.users.append(us)
                                    }
                                }
                                tempUsers = users
                                numberDone++
                                if numberDone == count {
                                    self.addUsers()
                                }
                            }, failure: {
                                (error) -> Void in
                                Utility.handleError(error, message: "Error Getting Twitter Users")
                            })
                        }
                    case .Instagram:
                        let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                        let data = json["data"] as! NSArray
                        var u = [InstagramUser]()
                        for item in data {
                            let i = item as! NSDictionary
                            let user = Utility.instagramUserFromDictionary(i)
                            u.append(user)
                        }
                        var users = [SignedInUser]()
                        for user in u {
                            let us = SignedInUser(client: signedInUsers[index].client, user: user, clientUser: signedInUsers[index].clientUser)
                            users.append(us)
                        }
                        tempUsers = users
                    case .Tumblr:
                        let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                        let response = json["response"] as! NSDictionary
                        var usersArray: NSArray!
                        if let users = response["users"] as? NSArray {
                            usersArray = users
                        } else if let users = response["blogs"] as? NSArray {
                            usersArray = users
                        }
                        var u = [TumblrUser]()
                        for user in usersArray {
                            let i = user as! NSDictionary
                            let user = Utility.tumblrUserFromDictionary(i, nameString: "name")
                            u.append(user)
                        }
                        if url.hasSuffix("followers") {
                            (self.signedInUsers[index].user as! TumblrUser).followers = u
                        }
                        var users = [SignedInUser]()
                        for user in u {
                            let us = SignedInUser(client: signedInUsers[index].client, user: user, clientUser: signedInUsers[index].clientUser)
                            users.append(us)
                        }
                        tempUsers = users
                    case .SoundCloud:
                        var j = [NSDictionary]()
                        let js = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers))
                        if let _ = js as? NSDictionary {
                            j = js["collection"] as! [NSDictionary]
                        } else {
                            j = js as! [NSDictionary]
                        }
                        var u = [SoundCloudUser]()
                        for user in j {
                            let user = Utility.soundCloudUserFromDictionary(user)
                            u.append(user)
                        }
                        var users = [SignedInUser]()
                        for user in u {
                            let us = SignedInUser(client: signedInUsers[index].client, user: user, clientUser: signedInUsers[index].clientUser)
                            users.append(us)
                        }
                        tempUsers = users
                    default:
                        print("okidoki", terminator: "")
                    }
                    if !url.hasSuffix("/ids.json") {
                        numberDone++
                        for user in tempUsers {
                            var add = true
                            for u in self.users {
                                if u.user.type == user.user.type {
                                    if u.user.id == user.user.id {
                                        add = false
                                    }
                                }
                            }
                            if add {
                                self.users.append(user)
                            }
                        }
                        if numberDone == count {
                            self.addUsers()
                        }
                    }
                }) {
                    (error) -> Void in
                    if self.users.count > index {
                        Utility.handleError(error, message: "Error Getting \(self.users[index].clientUser.type.rawValue) Users")
                    }
                }
            }
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchUsers = [SignedInUser]()
        if searchText == "" {
            self.searchUsers = self.users
        } else {
            for user in self.users {
                var add = false
                if user.user.name != nil {
                    if user.user.name!.lowercaseString.rangeOfString(searchText.lowercaseString) != nil {
                        add = true
                    }
                }
                if user.user.username != nil {
                    if user.user.username!.lowercaseString.rangeOfString(searchText.lowercaseString) != nil {
                        add = true
                    }
                }
                if add {
                    self.searchUsers.append(user)
                }
            }
        }
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.tableView.contentInset.bottom = Utility.contentInsetsFromAudioPlayer()
        self.tableView.scrollIndicatorInsets.bottom = Utility.contentInsetsFromAudioPlayer()
    }
    
    func addUsers() {
        self.searchUsers = self.users
        self.loading = false
        self.tableView.reloadData()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loading {
            return 1
        } else {
            return self.searchUsers.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if !loading {
            let c = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath) as! UserTableViewCell
            c.setSignedInUser(self.searchUsers[indexPath.row])
            c.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0)
            cell = c
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath) 
            cell.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        }
        return cell

    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 48
    }
    
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.cellForRowAtIndexPath(indexPath)!.isKindOfClass(UserTableViewCell.classForCoder()) {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! UserTableViewCell
            if let list = cell.user as? TwitterList {
                let listViewController = ListTableViewController(list: list, signedInUser: cell.signedInUser!)
                self.navigationController!.pushViewController(listViewController, animated: true)
            } else {
                let u = SignedInUser(client: cell.signedInUser!.client, user: cell.user, clientUser: cell.signedInUser!.clientUser)
                let profileViewController = ProfileTableViewController(user: u)
                self.navigationController!.pushViewController(profileViewController, animated: true)
            }
        }
    }
    
}
