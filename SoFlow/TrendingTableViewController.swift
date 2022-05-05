//
//  TrendingTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 29/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit
import Crashlytics

class TrendingTableViewController: UITableViewController, UISearchBarDelegate, CellDelegate {

    let twitterSection = "Trending On Twitter"
    let instagramSection = "Popular On Instagram"
    var loading = true
    var urls = [String]()
    var params = [[String : String]]()
    var twitterUser: SignedInUser?
    var instagramUser: SignedInUser?
    var signedInUsers = [SignedInUser]()
    var sections = [String]()
    var hashtags = [String]()
    var popular = [Post]()
    var searchBar: UISearchBar!
    
    convenience init() {
        self.init(style: .Grouped)
        self.searchBar = UISearchBar()
        self.searchBar.searchBarStyle = .Minimal
        self.searchBar.sizeToFit()
        self.searchBar.placeholder = "Search"
        self.searchBar.delegate = self
        self.navigationItem.titleView = searchBar
        self.searchBar.keyboardAppearance = .Dark
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        Utility.registerCells(self.tableView)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.title = "Trending"
        self.navigationItem.hidesBackButton = true
        self.getSignedInUsers()
        self.getUrls()
    }
    
    func getUrls() {
        var numberDone = 0
        var sectionsToRemove = [String]()
        for (i, signedInUser) in self.signedInUsers.enumerate() {
            signedInUser.client.get(self.urls[i], parameters: self.params[i], success: {
                (data, response) -> Void in
                if signedInUser.clientUser.type == .Twitter {
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSArray
                    let trends = json[0]["trends"] as! NSArray
                    for trend in trends {
                        let t = trend as! NSDictionary
                        let name = t["name"] as! String
                        self.hashtags.append(name)
                    }
                } else if signedInUser.clientUser.type == .Instagram {
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let data = json["data"] as! NSArray
                    self.popular = Utility.instagramPostsFromArray(data, signedInUser: signedInUser)
                }
                numberDone++
                if numberDone == self.signedInUsers.count {
                    let mutableSections = NSMutableArray(array: self.sections)
                    mutableSections.removeObjectsInArray(sectionsToRemove)
                    self.sections = NSArray(array: mutableSections) as! [String]
                    self.loading = false
                    self.tableView.reloadData()
                }
            }, failure: {
                (error) -> Void in
                Utility.handleError(error, message: "Error Getting \(self.sections[i])")
                sectionsToRemove.append(self.sections[i])
                numberDone++
                if numberDone == self.signedInUsers.count {
                    let mutableSections = NSMutableArray(array: self.sections)
                    mutableSections.removeObjectsInArray(sectionsToRemove)
                    self.sections = NSArray(array: mutableSections) as! [String]
                    self.loading = false
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    func getSignedInUsers() {
        self.signedInUsers = [SignedInUser]()
        self.sections = [String]()
        self.urls = [String]()
        self.params = [[String : String]]()
        self.twitterUser = nil
        self.instagramUser = nil
        for user in primaryCurrentSignedInUsers {
            if user.clientUser.type == .Twitter {
                self.twitterUser = user
                self.signedInUsers.append(user)
                self.sections.append(self.twitterSection)
                self.urls.append(Twitter["base_url"]! + "trends/place.json")
                self.params.append(["id" : "23424975"])
            } else if user.clientUser.type == .Instagram {
                self.instagramUser = user
                self.signedInUsers.append(user)
                self.sections.append(self.instagramSection)
                self.urls.append(Instagram["base_url"]! + "media/popular")
                self.params.append(["":""])
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let prevCount = self.signedInUsers.count
        Utility.findUsers()
        self.getSignedInUsers()
        if prevCount != self.signedInUsers.count {
            self.getUrls()
        }
        self.tableView.contentInset.bottom = Utility.contentInsetsFromAudioPlayer()
        self.tableView.scrollIndicatorInsets.bottom = Utility.contentInsetsFromAudioPlayer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.loading {
            return 1
        } else {
            return self.sections.count
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.loading {
            return 1
        } else {
            if self.sections[section] == self.twitterSection {
                if self.hashtags.count > 4 {
                    return 5
                } else {
                    return self.hashtags.count
                }
            } else {
                return 2
            }
        }
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if searchBar.isFirstResponder() {
            searchBar.resignFirstResponder()
        }
        let searchViewController = SearchTableViewController(q: self.searchBar.text!)
        self.pushViewController(searchViewController)
        self.searchBar.showsCancelButton = false
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
        self.searchBar.showsCancelButton = false
    }
    
    func pushViewController(viewController: UIViewController) {
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func presentViewController(viewController: UIViewController) {
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    func showImage(image: UIImage, view: UIView) {
        Utility.showImage(image, view: view, viewController: self)
    }
    
    func showVideo(url: NSURL) {
        Utility.showVideo(url, viewController: self)
    }
    
    func showUser(user: SignedInUser) {
        let profileViewController = ProfileTableViewController(user: user)
        self.pushViewController(profileViewController)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if self.loading {
            let cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath) as! LoadingTableViewCell
            cell.selectionStyle = .None
            cell.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            return cell
        } else {
            let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
            cell.accessoryType = .DisclosureIndicator
            cell.textLabel!.text = "View All \(self.sections[indexPath.section])"
            if self.sections[indexPath.section] == self.twitterSection {
                if indexPath.row < 4 {
                    cell.textLabel!.text = self.hashtags[indexPath.row]
                    cell.textLabel!.textColor = tintColour
                }
                return cell
            } else if self.sections[indexPath.section] == self.instagramSection {
                if indexPath.row == 0 {
                    let c = self.tableView.dequeueReusableCellWithIdentifier("InstagramPopularCell", forIndexPath: indexPath) as! InstagramPopularTableViewCell
                    c.setPosts(self.popular)
                    c.separatorInset = UIEdgeInsets(top: 0, left: w, bottom: 0, right: 0)
                    c.del = self
                    return c
                } else {
                    return cell
                }
            } else {
                return UITableViewCell()
            }
        }
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if !self.loading {
            if self.sections[indexPath.section] == self.instagramSection {
                return w
            }
        }
        return 48
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !self.loading {
            return self.sections[section]
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.sections.count > indexPath.section {
            if self.sections[indexPath.section] == self.twitterSection {
                if indexPath.row < 4 {
                    let url = Twitter["base_url"]! + "search/tweets.json"
                    let cell = self.tableView.cellForRowAtIndexPath(indexPath)!
                    let params = ["q" : cell.textLabel!.text!, "count" : "100"]
                    let postsViewController = PostsTableViewController(urls: [url], params: [params], signedInUsers: [self.signedInUsers[indexPath.section]], title: params["q"])
                    self.pushViewController(postsViewController)
                } else {
                    let hashtagsViewController = HashtagsTableViewController(hashtags: self.hashtags, signedInUser: self.signedInUsers[indexPath.section])
                    self.pushViewController(hashtagsViewController)
                }
            } else {
                if indexPath.row != 0 {
                    let photosViewController = PhotosCollectionViewController(urls: [self.urls[indexPath.section]], params: [self.params[indexPath.section]], signedInUsers: [self.signedInUsers[indexPath.section]], title: self.sections[indexPath.section], posts: self.popular)
                    self.pushViewController(photosViewController)
                }
            }
        }
    }
    
}
