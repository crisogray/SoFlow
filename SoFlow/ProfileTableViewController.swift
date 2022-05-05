//
//  ProfileTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 07/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class ProfileTableViewController: PostsTableViewController {
    
    var facebookRows = ["Likes", "Photos", "Videos"/*, "Pages"*/]
    var twitterRows = ["Followers", "Following", "Favourites", "Recent Photos", "Lists"]
    var instagramRows = ["Followers", "Following", "Likes", "Photos and Videos"]
    var tumblrRows = ["Followers", "Following", "Likes"]
    var soundCloudRows = ["Followers", "Following", "Favourites", "Playlists"]
    var rows: [Service : [String]]!
    var isSameUser: Bool {
        get {
            return self.signedInUsers[0].clientUser.id == self.signedInUsers[0].user.id
        }
    }
    
    convenience init(user: SignedInUser) {
        var urls = [String]()
        var params = [Dictionary<String, AnyObject>]()
        Utility.getUrlForProfileTableViewController(user, urls: &urls, params: &params)
        var title = user.user.name
        if user.user.type == .Instagram || user.user.type == .SoundCloud {
            title = user.user.username
        }
        self.init(urls: urls, params: params, signedInUsers: [user], title: title!, style: .Grouped, subcallback: nil)
        if user.clientUser.id != signedInUsers[0].user.id {
            //self.facebookRows.removeAtIndex(3)
            self.instagramRows.removeAtIndex(2)
            self.tumblrRows = ["Likes"]
        } else {
            self.twitterRows.append("Mentions")
        }
        let view = NSBundle.mainBundle().loadNibNamed("ProfileView", owner: self, options: nil)[0] as! ProfileTableHeaderView
        view.setUser(self.signedInUsers[0], tableViewController: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateHeader()
    }
    
    func updateHeader() {
        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }
    
    override func sortAndAddPosts() {
        super.sortAndAddPosts()
        self.signedInUsers[0].user.timeline = posts
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            switch signedInUsers[0].user.type {
            case .Facebook, .Tumblr:
                return "Posts"
            case .Twitter:
                return "Tweets"
            case .Instagram:
                return "Recent"
            case .SoundCloud:
                return "Tracks"
            default:
                return nil
            }
        } else {
            return nil
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            self.rows = [Service.Facebook : facebookRows, Service.Twitter : twitterRows, Service.Instagram : instagramRows, Service.Tumblr : tumblrRows, Service.SoundCloud : soundCloudRows]
            return self.rows[signedInUsers[0].user.type]!.count
        } else {
            return super.tableView(tableView, numberOfRowsInSection: 0)
        }
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 {
            let iPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
            return super.tableView(tableView, estimatedHeightForRowAtIndexPath: iPath)
        } else {
            return 44
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            if !self.loading {
                let iPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
                return super.tableView(tableView, cellForRowAtIndexPath: iPath)
            } else {
                return tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath) as! LoadingTableViewCell
            }
        } else {
            let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
            cell.accessoryType = .DisclosureIndicator
            switch self.signedInUsers[0].user.type {
            case .Facebook:
                cell.textLabel!.text = facebookRows[indexPath.row]
            case .Twitter:
                cell.textLabel!.text = twitterRows[indexPath.row]
                let u = signedInUsers[0].user as! TwitterUser
                if indexPath.row == 0 {
                    if u.followersCount != nil {
                        cell.detailTextLabel!.text = Utility.formatNumber(u.followersCount!)
                    }
                } else if indexPath.row == 1 {
                    if u.followingCount != nil {
                        cell.detailTextLabel!.text = Utility.formatNumber(u.followingCount!)
                    }
                } else if indexPath.row == 2 {
                    if u.favouriteCount != nil {
                        cell.detailTextLabel!.text = Utility.formatNumber(u.favouriteCount!)
                    }
                }
            case .Instagram:
                cell.textLabel!.text = instagramRows[indexPath.row]
                let u = signedInUsers[0].user as! InstagramUser
                if indexPath.row == 0 {
                    if u.followersCount != nil {
                        cell.detailTextLabel!.text = Utility.formatNumber(u.followersCount!)
                    }
                } else if indexPath.row == 1 {
                    if u.followingCount != nil {
                        cell.detailTextLabel!.text = Utility.formatNumber(u.followingCount!)
                    }
                }
            case .Tumblr:
                cell.textLabel?.text = tumblrRows[indexPath.row]
            case .SoundCloud:
                cell.textLabel?.text = soundCloudRows[indexPath.row]
                let u = self.signedInUsers[0].user as! SoundCloudUser
                if indexPath.row == 0 {
                    if u.followersCount != nil {
                        cell.detailTextLabel!.text = Utility.formatNumber(u.followersCount!)
                    }
                } else if indexPath.row == 1 {
                    if u.followingCount != nil {
                        cell.detailTextLabel!.text = Utility.formatNumber(u.followingCount!)
                    }
                } else if indexPath.row == 2 {
                    if u.favouritesCount != nil {
                        cell.detailTextLabel!.text = Utility.formatNumber(u.favouritesCount!)
                    }
                } else if indexPath.row == 3 {
                    if u.playlistCount != nil {
                        cell.detailTextLabel!.text = Utility.formatNumber(u.playlistCount!)
                    }
                }
            default:
                return UITableViewCell()
            }
            return cell
        }
    }
    
    override func showUser(user: SignedInUser) {
        if user.user.id != self.signedInUsers[0].user.id {
            super.showUser(user)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            let cell = tableView.cellForRowAtIndexPath(indexPath)! as UITableViewCell
            let string = cell.textLabel!.text!
            switch self.signedInUsers[0].user.type {
            case .Facebook:
                let name = self.signedInUsers[0].user.name!
                var title = name
                if name.hasSuffix("s") {
                    title += "' \(string)"
                } else {
                    title += "'s \(string)"
                }
                if self.isSameUser {
                    title = "Your " + string
                }
                if string == "Likes" {
                    let params = ["fields":"name,id,picture,is_verified,category"]
                    let url = Facebook["base_url"]! + signedInUsers[0].user.id + "/" + string
                    let usersViewController = UsersTableViewController(urls: [url], params: [params], signedInUsers: [self.signedInUsers[0]], title: title, pages: true, users: nil)
                    pushViewController(usersViewController)
                } else if string != "Pages" {
                    let url = Facebook["base_url"]! + signedInUsers[0].user.id + "/" + string.lowercaseString
                    var params = ["":""]
                    if string == "Videos" {
                        var p = FacebookVideoParams
                        p["fields"]! += ",format"
                        let postsViewController = PostsTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title)
                        pushViewController(postsViewController)
                    } else {
                        params = FacebookPostParams
                        print(url)
                        let photosViewController = PhotosCollectionViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title, posts: nil)
                        pushViewController(photosViewController)
                    }
                } else {
                    let params = ["":""]
                    let url = Facebook["base_url"]! + signedInUsers[0].user.id + "/accounts"
                    let usersViewController = UsersTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title, pages: true, users: nil)
                    pushViewController(usersViewController)
                }
            case .Twitter:
                let name = self.signedInUsers[0].user.name!
                var title = name
                if name.hasSuffix("s") {
                    title += "' \(string)"
                } else {
                    title += "'s \(string)"
                }
                if self.isSameUser {
                    title = "Your " + string
                }
                if string.hasPrefix("Follow") {
                    var s: String!
                    var users: [SignedInUser]?
                    if string == twitterRows[1] {
                        s = "friends/list.json"
                        if signedInUsers[0].user.friends != nil {
                            var u = [SignedInUser]()
                            for user in self.signedInUsers[0].user.friends! {
                                let us = SignedInUser(client: self.signedInUsers[0].client, user: user, clientUser: self.signedInUsers[0].clientUser)
                                u.append(us)
                            }
                            users = u
                        }
                        title = "\(name) Follows"
                        if self.isSameUser {
                            title = "You Follow"
                        }
                    } else {
                        s = "followers/list.json"
                        if signedInUsers[0].user.followers != nil {
                            var u = [SignedInUser]()
                            for user in self.signedInUsers[0].user.followers! {
                                let us = SignedInUser(client: self.signedInUsers[0].client, user: user, clientUser: self.signedInUsers[0].clientUser)
                                u.append(us)
                            }
                            users = u
                        }
                    }
                    let url = Twitter["base_url"]! + s
                    let params: Dictionary<String, AnyObject> = ["count" :"100", "skip_status" : "true", "user_id" : signedInUsers[0].user.id]
                    let usersViewController = UsersTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title, pages: true, users: users)
                    pushViewController(usersViewController)
                } else if string == "Favourites" {
                    let url = Twitter["base_url"]! + "favorites/list.json"
                    let params = ["count" :"200", "skip_status" : "true", "user_id" : signedInUsers[0].user.id]
                    let postsViewController = PostsTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title)
                    self.pushViewController(postsViewController)
                } else if string == "Recent Photos" {
                    let q = "filter:images from:" + self.signedInUsers[0].user.username!.lowercaseString
                    let url = Twitter["base_url"]! + "search/tweets.json"
                    let photosViewController = PhotosCollectionViewController(urls: [url], params: [["q" : q, "count" : "30", "include_entities" : "1"]], signedInUsers: self.signedInUsers, title: title, posts: nil)
                    self.pushViewController(photosViewController)
                } else if string == "Lists" {
                    let listViewController = GroupedTableViewController(user: self.signedInUsers[0], type: .List, title: title)
                    self.pushViewController(listViewController)
                } else if string == "Mentions" {
                    let url = Twitter["base_url"]! + "statuses/mentions_timeline.json"
                    let params = ["count" :"200"]
                    let postsViewController = PostsTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title)
                    self.pushViewController(postsViewController)
                }
            case .Instagram:
                let name =  self.signedInUsers[0].user.username!
                var title = name
                if name.hasSuffix("s") {
                    title += "' \(string)"
                } else {
                    title += "'s \(string)"
                }
                if self.isSameUser {
                    title = "Your " + string
                }
                if string.hasPrefix("Follow") {
                    var s: String!
                    if string == "Following" {
                        s = "follows"
                        title = "\(name) Follows"
                        if self.isSameUser {
                            title = "You Follow"
                        }
                    } else {
                        s = "followed-by"
                    }
                    let url = Instagram["base_url"]! + "users/" + signedInUsers[0].user.id + "/" + s
                    let usersViewController = UsersTableViewController(urls: [url], params: [["":""]], signedInUsers: self.signedInUsers, title: title, pages: true, users: nil)
                    pushViewController(usersViewController)
                } else if string == "Likes" {
                    if self.signedInUsers[0].clientUser.id == signedInUsers[0].user.id {
                        let url = Instagram["base_url"]! + "users/self/media/liked"
                        print(url)
                        let postsViewController = PostsTableViewController(urls: [url], params: [Dictionary<String, AnyObject>()], signedInUsers: [self.signedInUsers[0]], title: title)
                        self.pushViewController(postsViewController)
                    }
                } else if string == "Photos and Videos" {
                    var posts: [Post]?
                    //if self.posts != nil {
                        posts = self.posts
                    //}
                    let photosViewController = PhotosCollectionViewController(urls: self.urls, params: self.params, signedInUsers: self.signedInUsers, title: title, posts: posts)
                    self.pushViewController(photosViewController)
                }
            case .Tumblr:
                let name = self.signedInUsers[0].user.name!
                var title = name
                if name.hasSuffix("s") {
                    title += "' \(string)"
                } else {
                    title += "'s \(string)"
                }
                if self.isSameUser {
                    title = "Your " + string
                }
                if string == "Followers" {
                    let url = Tumblr["base_url"]! + "blog/\(signedInUsers[0].user.name!).tumblr.com/followers"
                    let params = ["limit" : "20"]
                    let usersViewController = UsersTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title, pages: false, users: nil)
                    self.pushViewController(usersViewController)
                } else if string == "Likes" {
                    let url = Tumblr["base_url"]! + "blog/\(signedInUsers[0].user.name!).tumblr.com/likes"
                    let params = ["limit" : "20", "api_key" : Tumblr["key"]!, "filter" : "text", "notes_info" : "true"]
                    let postsViewController = PostsTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title)
                    self.pushViewController(postsViewController)
                } else if string == "Following" {
                    if self.isSameUser {
                        title = "You Follow"
                    }
                    title = "\(name) Follows"
                    let url = Tumblr["base_url"]! + "user/following"
                    let params = ["limit" : "20"]
                    let usersViewController = UsersTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title, pages: false, users: nil)
                    self.pushViewController(usersViewController)
                }
            case .SoundCloud:
                let name = self.signedInUsers[0].user.username!
                var title = name
                if name.hasSuffix("s") {
                    title += "' \(string)"
                } else {
                    title += "'s \(string)"
                }
                if self.isSameUser {
                    title = "Your " + string
                }
                if string == "Followers" {
                    let url = SoundCloud["base_url"]! + "users/\(self.signedInUsers[0].user.id)/followers"
                    let params = Dictionary<String, String>()
                    let usersViewController = UsersTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title, pages: false, users: nil)
                    self.pushViewController(usersViewController)
                } else if string == "Favourites" {
                    let url = SoundCloud["base_url"]! + "users/\(self.signedInUsers[0].user.id)/favorites"
                    let params = Dictionary<String, String>()
                    let postsViewController = PostsTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title)
                    self.pushViewController(postsViewController)
                } else if string == "Following" {
                    if self.isSameUser {
                        title = "You Follow"
                    } else {
                        title = "\(name) Follows"
                    }
                    let url = SoundCloud["base_url"]! + "users/\(self.signedInUsers[0].user.id)/followings"
                    let params = Dictionary<String, String>()
                    let usersViewController = UsersTableViewController(urls: [url], params: [params], signedInUsers: self.signedInUsers, title: title, pages: false, users: nil)
                    self.pushViewController(usersViewController)
                } else if string == "Playlists" {
                    let playlistsViewController = GroupedTableViewController(user: self.signedInUsers.first!, type: .Playlist, title: title)
                    self.pushViewController(playlistsViewController)
                }
            default:
                print("okidoki", terminator: "")
            }
        } else {
            super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
    }

}