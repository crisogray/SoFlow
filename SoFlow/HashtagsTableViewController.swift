//
//  HashtagsTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 29/11/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class HashtagsTableViewController: UITableViewController {

    var hashtags: [String]!
    var signedInUser: SignedInUser!
    
    convenience init(hashtags: [String], signedInUser: SignedInUser) {
        self.init()
        self.hashtags = hashtags
        self.signedInUser = signedInUser
        self.title = "Trending On Twitter"
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.hashtags.count
    }

    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = self.tableView.dequeueReusableCellWithIdentifier("HashtagCell") {
            cell.textLabel!.text = self.hashtags[indexPath.row]
            return cell
        } else {
            let cell = UITableViewCell(style: .Default, reuseIdentifier: "HashtagCell")
            cell.textLabel!.textColor = tintColour
            cell.textLabel!.text = self.hashtags[indexPath.row]
            cell.accessoryType = .DisclosureIndicator
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let url = Twitter["base_url"]! + "search/tweets.json"
        let params = ["q" : self.hashtags[indexPath.row], "count" : "100"]
        let postsViewController = PostsTableViewController(urls: [url], params: [params], signedInUsers: [self.signedInUser], title: params["q"])
        self.navigationController!.pushViewController(postsViewController, animated: true)
    }

}
