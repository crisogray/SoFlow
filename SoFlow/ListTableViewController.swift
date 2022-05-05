//
//  ListTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 17/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class ListTableViewController: PostsTableViewController {

    let sections = ["Owner", "Members", "Subscribers", "Tweets"]
    var list: TwitterList!
    var loadingMembers = true
    var loadingSubscribers = true
    var users = [String : [TwitterUser]]()
    
    convenience init(list: TwitterList, signedInUser: SignedInUser) {
        let url = Twitter["base_url"]! + "lists/statuses.json"
        let params = ["list_id" : list.id, "count" : "200"]
        self.init(urls: [url], params: [params], signedInUsers: [signedInUser], title: list.name, style: .Grouped, subcallback: nil)
        self.list = list
        let urls = [Twitter["base_url"]! + "lists/members.json", Twitter["base_url"]! + "lists/subscribers.json"]
        let param = ["list_id" : self.list.id, "count" : "100"]
        for (i, url) in urls.enumerate() {
            self.signedInUsers[0].client.get(url, parameters: param, success: {
                (data, response) -> Void in
                let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                let u = json["users"] as! NSArray
                var users = [TwitterUser]()
                for item in u {
                    let i = item as! NSDictionary
                    let user = Utility.twitterUserFromDictionary(i)
                    users.append(user)
                }
                self.users[self.sections[i + 1]] = users
                if i == 0 {
                    self.loadingMembers = false
                } else {
                    self.loadingSubscribers = false
                }
                self.tableView.reloadData()
            }, failure: {
                (error) -> Void in
                Utility.handleError(error, message: "Error Getting List")
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.contentInset.bottom = Utility.contentInsetsFromAudioPlayer()
        self.tableView.scrollIndicatorInsets.bottom = Utility.contentInsetsFromAudioPlayer()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.loading || self.loadingMembers || loadingSubscribers {
            return 2
        }
        return 4
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 || !(self.loading || self.loadingMembers || loadingSubscribers) {
            return self.sections[section]
        } else {
            return nil
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            if self.loading || self.loadingMembers || loadingSubscribers {
                return 1
            } else {
                if section == 3 {
                    return super.tableView(self.tableView, numberOfRowsInSection: 0)
                } else {
                    let count = self.users[self.sections[section]]!.count
                    if count > 3 {
                        return 4
                    } else {
                        return count
                    }
                }
            }
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath) as! UserTableViewCell
            cell.setUser(self.list.owner)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0)
            return cell
        } else if indexPath.section == 3 {
            let iPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
            return super.tableView(self.tableView, cellForRowAtIndexPath: iPath)
        } else {
            if self.loading || self.loadingMembers || loadingSubscribers {
                let cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath) as! LoadingTableViewCell
                cell.selectionStyle = .None
                cell.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
                return cell
            } else {
                if indexPath.row < 3 {
                    let cell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath) as! UserTableViewCell
                    cell.setUser(self.users[self.sections[indexPath.section]]![indexPath.row])
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0)
                    return cell
                } else {
                    let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
                    cell.accessoryType = .DisclosureIndicator
                    cell.textLabel!.text = "View All " + self.tableView(self.tableView, titleForHeaderInSection: indexPath.section)!
                    var count: Int!
                    if indexPath.section == 1 {
                        count = self.list.memberCount
                    } else {
                        count = self.list.subscriberCount
                    }
                    cell.detailTextLabel!.text = "\(count)"
                    return cell
                }
            }
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let c = self.tableView.cellForRowAtIndexPath(indexPath)
        if let cell = c as? UserTableViewCell {
            let user = SignedInUser(client: self.signedInUsers[0].client, user: cell.user, clientUser: self.signedInUsers[0].clientUser)
            let userViewController = ProfileTableViewController(user: user)
            self.pushViewController(userViewController)
        } else if let cell = c as? PostTableViewCell {
            //let postViewController = PostTableViewController(post: cell.post)
            //self.pushViewController(postViewController)
            self.tableView.beginUpdates()
            cell.showDraw()
            self.tableView.endUpdates()
        } else {
            let section = self.sections[indexPath.section]
            let users = self.users[section]!
            var url: String!
            if indexPath.section == 1 {
                url = Twitter["base_url"]! + "lists/members.json"
            } else {
                url = Twitter["base_url"]! + "lists/subscribers.json"
            }
            let param = ["list_id" : self.list.id, "count" : "100"]
            var u = [SignedInUser]()
            for user in users {
                let sU = self.signedInUsers[0]
                let signedInUser = SignedInUser(client: sU.client, user: user, clientUser: sU.clientUser)
                u.append(signedInUser)
            }
            let usersViewController = UsersTableViewController(urls: [url], params: [param], signedInUsers: self.signedInUsers, title: "\(self.title!) \(section)", pages: false, users: u)
            self.pushViewController(usersViewController)
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? PostTableViewCell {
            self.tableView.beginUpdates()
            cell.retractDraw()
            self.tableView.endUpdates()
        }
    }

}
