//
//  SearchTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 16/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK

class SearchTableViewController: PostsTableViewController, UISearchBarDelegate {
    
    var q: String!
    var sections = [String]()
    var users = [String : [AnyObject]]()
    var usersLoading = true
    var searchBar: UISearchBar!
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if searchBar.isFirstResponder() {
            searchBar.resignFirstResponder()
        }
        if !self.loading && !self.usersLoading || searchBar.text != self.q {
            self.search(self.searchBar!.text!.lowercaseString)
        }
        self.searchBar.showsCancelButton = false
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
        self.searchBar.showsCancelButton = false
    }
    
    convenience init(q: String) {
        self.init(style: .Grouped)
        self.q = q
        self.title = "Trending"
        Utility.registerCells(self.tableView)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.searchBar = UISearchBar()
        self.searchBar.searchBarStyle = .Minimal
        self.searchBar.sizeToFit()
        self.searchBar.placeholder = "Search"
        self.searchBar.delegate = self
        self.navigationItem.titleView = searchBar
        self.searchBar.text = q
        self.searchBar.keyboardAppearance = .Dark
        self.search(q.lowercaseString)
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
    }
    
    func search(q: String) {
        Utility.findUsers()
        Flurry.logEvent("Search", withParameters: ["q" : self.q])
        self.q = q.lowercaseString
        self.setVars()
        self.loading = true
        self.usersLoading = true
        self.tableView.reloadData()
        self.refreshDate = NSDate(timeIntervalSinceNow: -80)
        var sections = [String]()
        var urls = [String]()
        var params = [Dictionary<String, AnyObject>]()
        var signedInUsers = [SignedInUser]()
        var userUrls = [String]()
        var userParams = [Dictionary<String, AnyObject>]()
        var userSignedInUsers = [SignedInUser]()
        Utility.getUrlsForSearchTableViewController(self.q, urls: &urls, params: &params, signedInUsers: &signedInUsers, userUrls: &userUrls, userParams: &userParams, userSignedInUsers: &userSignedInUsers, sections: &sections)
        self.urls = urls
        self.params = params
        self.signedInUsers = signedInUsers
        self.sections = sections
        self.getUrls()
        var count = userUrls.count
        var numberDone = 0
        for (index, url) in userUrls.enumerate() {
            userSignedInUsers[index].client.get(url, parameters: userParams[index], success: {
                (data, response) -> Void in
                let signedInUser = userSignedInUsers[index]
                switch signedInUser.clientUser.type {
                case .Facebook:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let data = json["data"] as! NSArray
                    if data.count != 0 {
                        let test = data[0] as! NSDictionary
                        if test["category"] == nil {
                            let section = "Facebook Users"
                            self.users[section] = [SignedInUser]()
                            for dictionary in data {
                                let d = dictionary as! NSDictionary
                                let user = Utility.facebookUserFromDictionary(d, signedInUser: signedInUser)
                                let signedInUser = SignedInUser(client: signedInUser.client, user: user, clientUser: signedInUser.clientUser)
                                self.users[section]!.append(signedInUser)
                            }
                        } else {
                            let section = "Facebook Pages"
                            self.users[section] = [SignedInUser]()
                            let pages = Utility.facebookPagesFromDictionary(data)
                            for user in pages {
                                let signedInUser = SignedInUser(client: signedInUser.client, user: user, clientUser: signedInUser.clientUser)
                                self.users[section]!.append(signedInUser)
                            }
                        }
                    }
                case .Twitter:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSArray
                    let section = "Twitter Users"
                    self.users[section] = [SignedInUser]()
                    for us in json {
                        let u = us as! NSDictionary
                        let user = Utility.twitterUserFromDictionary(u)
                        let signedInUser = SignedInUser(client: signedInUser.client, user: user, clientUser: signedInUser.clientUser)
                        self.users[section]!.append(signedInUser)
                    }
                case .Instagram:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let data = json["data"] as! NSArray
                    let section = "Instagram Users"
                    self.users[section] = [SignedInUser]()
                    for dat in data {
                        let d = dat as! NSDictionary
                        let user = Utility.instagramUserFromDictionary(d)
                        let signedInUser = SignedInUser(client: signedInUser.client, user: user, clientUser: signedInUser.clientUser)
                        self.users[section]!.append(signedInUser)
                    }
                case .SoundCloud:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSArray
                    if url.hasSuffix("tracks") {
                        let section = "SoundCloud Tracks"
                        self.users[section] = Utility.soundCloudPostsFromArray(json, signedInUser: signedInUser)
                    } else {
                        let section = "SoundCloud Users"
                        self.users[section] = [SignedInUser]()
                        for us in json {
                            let u = us as! NSDictionary
                            let user = Utility.soundCloudUserFromDictionary(u)
                            let signedInUser = SignedInUser(client: signedInUser.client, user: user, clientUser: signedInUser.clientUser)
                            self.users[section]!.append(signedInUser)
                        }
                    }
                default:
                    print("okidoki")
                }
                numberDone++
                if numberDone == count {
                    self.usersLoading = false
                    self.sortSections()
                    self.tableView.reloadData()
                }
            }, failure: {
                (error) -> Void in
                Utility.handleError(error, message: "Error Getting \(self.signedInUsers[index].clientUser.type.rawValue) Results")
                count--
                if numberDone == count {
                    self.usersLoading = false
                    self.sortSections()
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    func titleFromQ(q: String) -> String {
        return "Posts with \"\(q)\""
    }
    
    override func sortAndAddPosts() {
        super.sortAndAddPosts()
        self.refreshControl = nil
    }
    
    func setVars() {
        self.signedInUsers = [SignedInUser]()
        self.urls = [String]()
        self.params = [Dictionary<String, AnyObject>]()
        self.users = [String : [AnyObject]]()
        self.posts = [Post]()
        self.sections = [String]()
    }
    
    func sortSections() {
        let sections = NSMutableArray(array: self.sections)
        var sectionsToRemove = [String]()
        for section in self.sections {
            if section != self.titleFromQ(self.q) {
                if self.users[section] != nil {
                    if self.users[section]!.isEmpty {
                        sectionsToRemove.append(section)
                    }
                } else {
                    sectionsToRemove.append(section)
                }
            } else {
                if !self.posts.isEmpty {
                    if self.posts.count == 0 {
                        sectionsToRemove.append(section)
                    }
                }
            }
        }
        sections.removeObjectsInArray(sectionsToRemove)
        self.sections = NSArray(array: sections) as! [String]
    }
    
    func shouldAddPost(post: Post) -> Bool {
        for po in self.posts {
            if po.type == post.type {
                if po.id == post.id {
                    return false
                }
            }
        }
        return true
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if !self.loading && !self.usersLoading {
            print(self.sections.count)
            return self.sections.count
        } else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !self.loading && !self.usersLoading {
            if self.sections[section] == self.titleFromQ(q) {
                if !self.posts.isEmpty {
                    return self.sections[section]
                }
            } else {
                return self.sections[section]
            }
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.loading || self.usersLoading {
            return 1
        } else {
            if self.sections[section] != self.titleFromQ(self.q) {
                if let users = self.users[self.sections[section]] {
                    if users.count > 3 {
                        return 4
                    } else {
                        return users.count
                    }
                } else {
                    return 0
                }
            } else {
                return posts.count
            }
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if !self.loading && !self.usersLoading {
            if self.sections[indexPath.section] != self.titleFromQ(q) {
                if indexPath.row < 3 {
                    var c: UITableViewCell!
                    if sections[indexPath.section] != "SoundCloud Tracks" {
                        let cell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath) as! UserTableViewCell
                        let user = self.users[sections[indexPath.section]]![indexPath.row] as! SignedInUser
                        cell.setSignedInUser(user)
                        c = cell
                    } else {
                        let post = self.users[sections[indexPath.section]]![indexPath.row] as! Post
                        let cell = Utility.tableViewCellFromPost(post, tableView: self.tableView, indexPath: indexPath, signedInUser: post.signedInUser)!
                        cell.del = self
                        c = cell
                    }
                    c.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0)
                    return c
                } else {
                    let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
                    cell.accessoryType = .DisclosureIndicator
                    cell.textLabel!.text = "View All \(sections[indexPath.section])"
                    return cell
                }
            } else {
                return super.tableView(self.tableView, cellForRowAtIndexPath: NSIndexPath(forRow: indexPath.row, inSection: 0))
            }
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath) as! LoadingTableViewCell
            return cell
        }
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if !self.loading && !self.usersLoading {
            if self.sections[indexPath.section] == self.titleFromQ(self.q) {
                return super.tableView(self.tableView, estimatedHeightForRowAtIndexPath: indexPath)
            }
        }
        return 48
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !self.loading && !self.usersLoading {
            self.searchBar.resignFirstResponder()
            if self.sections[indexPath.section] != self.titleFromQ(self.q) {
                if sections[indexPath.section] != "SoundCloud Tracks" {
                    if indexPath.row < 3 {
                        let cell = tableView.cellForRowAtIndexPath(indexPath) as! UserTableViewCell
                        self.showUser(cell.signedInUser!)
                    } else {
                        let users = self.users[sections[indexPath.section]]! as! [SignedInUser]
                        let usersViewController = UsersTableViewController(urls: [""], params: [Dictionary<String, AnyObject>](), signedInUsers: [users[0]], title: sections[indexPath.section], pages: false, users: users)
                        self.pushViewController(usersViewController)
                    }
                } else {
                    if indexPath.row < 3 {
                        let cell = tableView.cellForRowAtIndexPath(indexPath) as! PostTableViewCell
                        cell.showPost(nil)
                    } else {
                        let posts = self.users[sections[indexPath.section]]! as! [Post]
                        let postViewController = PostsTableViewController(urls: [String](), params: [["":""]], signedInUsers: [posts[0].signedInUser], title: "Tracks")
                        postViewController.posts = posts
                        self.pushViewController(postViewController)
                    }
                }
            } else {
                super.tableView(self.tableView, didSelectRowAtIndexPath: indexPath)
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.searchBar.resignFirstResponder()
    }
    
}
