//
//  ComposeTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 30/09/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

protocol ComposeDelegate {
    func updateMedia(media: [LibraryPhoto])
    func returnLocation(location: Location?) -> Bool
}

class ComposeTableViewController: UITableViewController, CellDelegate, ComposeDelegate {
    
    var futurePosts: [FuturePost]!
    var media = [LibraryPhoto]()
    var location: Location?
    var composeCell: ComposeTableViewCell?
    var cells = [[UITableViewCell]]()
    var attachmentSection = 1
    var inReplyToPost: Post?
    var postCell: Post?
    var retweetUrl: String?
    
    convenience init(futurePosts: [FuturePost], postCell: Post?) {
        self.init(style: .Grouped)
        self.futurePosts = futurePosts
        self.postCell = postCell
        self.tableView.estimatedRowHeight = 72
        Utility.registerCells(self.tableView)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.title = "Compose"
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        if self.futurePosts.count == 1 {
            let first = self.futurePosts.first!
            if first.type == FuturePostType.Comment {
                self.inReplyToPost = first.inReplyToPost!
            } else {
                self.retweetUrl = first.retweetUrl
            }
            if self.postCell != nil {
                self.attachmentSection = 2
            }
        }
        self.collectCells()
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    func collectCells() {
        self.cells = [[UITableViewCell](), [UITableViewCell](), [UITableViewCell]()]
        if self.composeCell == nil {
            self.composeCell = tableView.dequeueReusableCellWithIdentifier("ComposeCell")! as? ComposeTableViewCell
            self.composeCell!.tableViewController = self
            self.composeCell!.setFuturePosts(self.futurePosts)
            self.composeCell!.del = self
            self.composeCell!.composeDel = self
            self.composeCell!.retweetUrl = self.retweetUrl
            if self.inReplyToPost != nil {
                self.composeCell!.inReplyToPost = self.inReplyToPost!
                if self.inReplyToPost!.type == .Twitter {
                    self.composeCell!.textView.text = "@" + self.inReplyToPost!.from!.username!
                }
            }
        }
        self.cells[0].append(self.composeCell!)
        if self.postCell != nil {
            self.cells[1] = [Utility.tableViewCellFromPost(self.postCell!, tableView: self.tableView, indexPath: NSIndexPath(forRow: 0, inSection: 1), signedInUser: self.postCell!.signedInUser)!]
        }
        for m in self.media {
            self.mediaCellFromMediaArray([m])
        }
        if self.location != nil {
            self.mapCellFromLocation(self.location!)
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Tap a user to submit the post with that user"
        } else if section != self.attachmentSection {
            if self.postCell!.type == .Twitter {
                if self.inReplyToPost != nil {
                    return "In reply to tweet above"
                } else {
                    return "Retweeting tweet above"
                }
            } else if self.postCell!.type == .Facebook {
                return "Commenting on post above"
            } else if self.postCell!.type == .Tumblr {
                return "Retweeting post above"
            }
        } else if self.location != nil || !self.media.isEmpty {
            return "Attachments"
        }
        return nil
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if self.tableView.indexPathsForVisibleRows != nil {
            if !self.tableView.indexPathsForVisibleRows!.contains(NSIndexPath(forRow: 0, inSection: 0)) {
                if self.composeCell != nil {
                    self.composeCell!.textView.resignFirstResponder()
                }
            }
        }
    }
    
    func mapCellFromLocation(location: Location) {
        let mapCell = self.tableView.dequeueReusableCellWithIdentifier("TallMapCell") as! MapTableViewCell
        mapCell.setLocation(location)
        mapCell.del = self
        self.cells[self.attachmentSection].append(mapCell)
    }
    
    func mediaCellFromMediaArray(media: [Media]) {
        let mediaCell = self.tableView.dequeueReusableCellWithIdentifier("TallImageVideoCell") as! ImageVideoTableViewCell
        mediaCell.setMediaArray(media)
        mediaCell.del = self
        self.cells[self.attachmentSection].append(mediaCell)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var count = self.cells.count
        if self.postCell == nil {
            count -= 1
        }
        return count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cells[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.cells[indexPath.section][indexPath.row]
        cell.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        if let c = cell as? ImageVideoTableViewCell {
            c.setMediaArray([self.media[indexPath.row]])
        } else if let c = cell as? PostTableViewCell {
            c.setPost(self.postCell!, signedInUser: self.postCell!.signedInUser)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 12)
        }
        cell.selectionStyle = .None
        return cell
    }

    func back() {
        // ARE YOU SURE
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    func forceBack() {
        if let _ = self.navigationController!.viewControllers[self.navigationController!.viewControllers.count - 2] as? ChooseUserCollectionViewController {
            self.navigationController!.popToRootViewControllerAnimated(true)
        } else {
            self.navigationController!.popViewControllerAnimated(true)
        }
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
    
    func pushViewController(viewController: UIViewController) {
        if self.composeCell != nil {
            self.composeCell!.textView.resignFirstResponder()
        }
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func presentViewController(viewController: UIViewController) {
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    func updateMedia(media: [LibraryPhoto]) {
        self.media = media
        self.collectCells()
        self.tableView.reloadData()
    }
    
    func returnLocation(location: Location?) -> Bool {
        var b = false
        if self.location == nil {
            self.location = location
            self.collectCells()
            let indexPath = NSIndexPath(forRow: self.tableView(self.tableView, numberOfRowsInSection: 1) - 1, inSection: 1)
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        } else {
            b = true
            self.location = nil
            self.collectCells()
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: self.tableView(self.tableView, numberOfRowsInSection: 1), inSection: 1)], withRowAnimation: .Left)
        }
        return b
    }
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == self.attachmentSection {
            if let _ = self.tableView.cellForRowAtIndexPath(indexPath) as? ImageVideoTableViewCell {
                return true
            } else if let _ = self.tableView.cellForRowAtIndexPath(indexPath) as? MapTableViewCell {
                return true
            }
        }
        return false
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let _ = self.tableView.cellForRowAtIndexPath(indexPath) as? ImageVideoTableViewCell {
                self.media.removeAtIndex(indexPath.row)
                self.composeCell!.media = self.media
                self.collectCells()
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Bottom)
            } else if let _ = self.tableView.cellForRowAtIndexPath(indexPath) as? MapTableViewCell {
                self.composeCell?.returnLocation()
            }
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
