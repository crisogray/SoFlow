//
//  GroupedTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 17/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class GroupedTableViewController: UITableViewController, CellDelegate {

    var user: SignedInUser!
    var type: GroupedType!
    var urls: [String]!
    var params: [Dictionary<String, AnyObject>]!
    var loading = true
    let listSections = ["Owned", "Subscribed to", "Member of"]
    var mutableListSections: NSMutableArray!
    var lists = [String : [TwitterList]]()
    var playlists = [SoundCloudPlaylist]()
    
    convenience init(user: SignedInUser, type: GroupedType, title: String) {
        self.init(style: .Grouped)
        self.mutableListSections = NSMutableArray(array: self.listSections)
        self.user = user
        self.type = type
        self.title = title
        Utility.registerCells(self.tableView)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        self.navigationItem.hidesBackButton = true
        var urls = [String]()
        var params = [Dictionary<String, AnyObject>]()
        if self.type == GroupedType.List {
            Utility.getUrlsForListGroupedTableViewController(&urls, params: &params, user: self.user.user)
            self.urls = urls
            self.params = params
            var numberDone = 0
            let count = self.urls.count
            var indexesToRemove = [String]()
            for (i, url) in urls.enumerate() {
                self.user.client.get(url, parameters: params[i], success: {
                    (data, response) -> Void in
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let l = json["lists"] as! NSArray
                    let lists = Utility.twitterListsFromArray(l)
                    if lists.count != 0 {
                        self.lists[self.listSections[i]] = lists
                    } else {
                        indexesToRemove.append(self.listSections[i])
                    }
                    numberDone++
                    if numberDone == count {
                        self.mutableListSections.removeObjectsInArray(indexesToRemove)
                        self.loading = false
                        self.tableView.reloadData()
                    }
                }, failure: {
                    (error) -> Void in
                    numberDone++
                    if numberDone == count {
                        self.mutableListSections.removeObjectsInArray(indexesToRemove)
                        self.loading = false
                        self.tableView.reloadData()
                    }
                    Utility.handleError(error, message: "Error Getting Lists")
                })
            }
        } else {
            let url = SoundCloud["base_url"]! + "users/\(self.user.user.id)/playlists"
            let params = Dictionary<String, AnyObject>()
            self.user.client.get(url, parameters: params, success: {
                (data, response) -> Void in
                let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSArray
                let playlists = Utility.soundCloudPlaylistsFromArray(json, signedInUser: self.user)
                self.playlists = playlists
                self.loading = false
                self.tableView.reloadData()
            }, failure: {
                (error) -> Void in
                Utility.handleError(error, message: "Error Getting Playlists")
            })
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.tableView.contentInset.bottom = Utility.contentInsetsFromAudioPlayer()
        self.tableView.scrollIndicatorInsets.bottom = Utility.contentInsetsFromAudioPlayer()
    }
    
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.loading {
            return 1
        } else {
            if self.type == GroupedType.List {
                return self.lists.count
            } else {
                return self.playlists.count
            }
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.loading {
            return 1
        } else {
            var count: Int!
            if self.type == GroupedType.List {
                count = self.lists[self.mutableListSections[section] as! String]!.count
            } else {
                count = self.playlists[section].tracks.count
            }
            if count > 3 {
                return 4
            } else {
                return count
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.loading {
            return nil
        } else {
            if self.type == GroupedType.List {
                return self.mutableListSections[section] as? String
            } else {
                return self.playlists[section].title
            }
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if self.loading {
            let cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath) as! LoadingTableViewCell
            cell.selectionStyle = .None
            cell.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            return cell
        } else {
            if self.type == GroupedType.List {
                if indexPath.row < 3 {
                    let cell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath) as! UserTableViewCell
                    cell.setUser(self.lists[self.mutableListSections[indexPath.section] as! String]![indexPath.row])
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 12)
                    return cell
                } else {
                    let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
                    cell.accessoryType = .DisclosureIndicator
                    cell.textLabel!.text = "View All"
                    if indexPath.section < 2 {
                        cell.detailTextLabel!.text = "\(self.lists[self.mutableListSections[indexPath.section] as! String]!.count)"
                    }
                    return cell
                }
            } else {
                let playlist = self.playlists[indexPath.section]
                if indexPath.row < 3 {
                    let track = playlist.tracks[indexPath.row]
                    let cell = Utility.tableViewCellFromPost(track, tableView: self.tableView, indexPath: indexPath, signedInUser: self.user)!
                    cell.del = self
                    return cell
                } else {
                    let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
                    cell.accessoryType = .DisclosureIndicator
                    cell.textLabel!.text = "View All Tracks"
                    cell.detailTextLabel!.text = "\(playlist.trackCount)"
                    return cell
                }
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !self.loading {
            if indexPath.row < 3 {
                if self.type == GroupedType.List {
                    let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! UserTableViewCell
                    let list = cell.user as! TwitterList
                    let listViewController = ListTableViewController(list: list, signedInUser: self.user)
                    self.navigationController!.pushViewController(listViewController, animated: true)
                } else {
                    let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! PostTableViewCell
                    self.tableView.beginUpdates()
                    cell.showDraw()
                    self.tableView.endUpdates()
                }
            } else {
                if self.type == GroupedType.List {
                    var users = [SignedInUser]()
                    for user in self.lists[self.mutableListSections[indexPath.section] as! String]! {
                        let signedInUser = SignedInUser(client: self.user.client, user: user, clientUser: self.user.clientUser)
                        users.append(signedInUser)
                    }
                    let usersViewController = UsersTableViewController(urls: [self.urls[indexPath.section]], params: [self.params[indexPath.section]], signedInUsers: [self.user], title: self.title!, pages: false, users: users)
                    self.navigationController!.pushViewController(usersViewController, animated: true)
                } else {
                    let postsViewController = PostsTableViewController(urls: [String](), params: [["":""]], signedInUsers: [self.user], title: self.tableView(self.tableView, titleForHeaderInSection: indexPath.section))
                    postsViewController.posts = self.playlists[indexPath.section].tracks
                    self.pushViewController(postsViewController)
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PostTableViewCell {
            self.tableView.beginUpdates()
            cell.retractDraw()
            self.tableView.endUpdates()
        }
    }
    
    func showImage(image: UIImage, view: UIView) {
        Utility.showImage(image, view: view, viewController: self)
    }
    
    func showUser(user: SignedInUser) {
        let profileViewcontroller = ProfileTableViewController(user: user)
        self.pushViewController(profileViewcontroller)
    }
    
    func showVideo(url: NSURL) {
        Utility.showVideo(url, viewController: self)
    }
    
    func pushViewController(viewController: UIViewController) {
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func presentViewController(viewController: UIViewController) {
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row < 3 {
            return 56
        } else {
            return 44
        }
    }

}
