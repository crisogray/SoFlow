//
//  PostTableViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 17/07/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import Crashlytics

class PostTableViewController: UITableViewController, CellDelegate {
    
    var post: Post!
    var video: Media?
    var cells = [UITableViewCell]()
    var insetCellReuseIdentifiers = ["DateCell", "TallDateCell", "CountsCell", "InstagramCountsCell", "TwitterCell", "TwitterImageCell", "TwitterVideoCell"]
    var countCell: CountsTableViewCell!
    var loading = true
    var comments = [Post]()
    var commentsUrl: String?
    var params = ["":""]
    var twitterQuote: TwitterPost?
    var showComments = false
    var loadingPost = false
    
    convenience init(url: String, params: Dictionary<String, AnyObject>, signedInUser: SignedInUser) {
        self.init(style: .Grouped)
        self.loadingPost = true
        if signedInUser.user.type == Service.Twitter {
            self.navigationItem.title = "Tweet"
        } else if signedInUser.user.type == Service.SoundCloud {
            self.navigationItem.title = "Track"
        } else {
            self.navigationItem.title = "Post"
        }
        Utility.registerCells(self.tableView)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        signedInUser.client.get(url, parameters: params, success: {
            (data, response) -> Void in
            var p: Post?
            let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
            switch signedInUser.user.type {
            case .Facebook:
                p = Utility.facebookPostsFromData([json], type: nil, signedInUser: signedInUser).first
            case .Twitter:
                p = Utility.twitterPostsFromArray([json], signedInUser: signedInUser).first
            default:
                print("okidoki")
            }
            if p != nil {
                self.post = p!
                self.loadingPost = false
                self.setPost()
                self.tableView.reloadData()
            }
        }) {
            (error) -> Void in
            Utility.handleError(error, message: "Error Fetching Post")
        }
    }
    
    convenience init(post: Post) {
        self.init(style: .Grouped)
        self.post = post
        if self.post.type == Service.Twitter {
            self.navigationItem.title = "Tweet"
        } else if self.post.type == Service.SoundCloud {
            self.navigationItem.title = "Track"
        } else {
            self.navigationItem.title = "Post"
        }
        Utility.registerCells(self.tableView)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.setPost()
    }
    
    func setPost() {
        let userCell = self.tableView.dequeueReusableCellWithIdentifier("PostUserCell") as! UserTableViewCell
        userCell.setPost(self.post)
        userCell.del = self
        self.cells.append(userCell)
        let dateCell = tableView.dequeueReusableCellWithIdentifier("DateCell") as! DateTableViewCell
        dateCell.setDate(self.post.date)
        switch self.post.type {
        case .Facebook:
            if let p = self.post as? FacebookPost {
                if p.story != nil {
                    self.textCellFromText(p.story!)
                }
                if p.message != nil {
                    self.textCellFromText(p.message!)
                }
                if p.media != nil {
                    if p.media!.type != MediaType.Link {
                        self.mediaCellFromMediaArray([p.media!])
                    }
                }
                let caption = Utility.facebookCaptionFromPost(p)
                if caption != nil {
                    self.textCellFromText(caption!)
                }
            } else if let p = self.post as? FacebookComment {
                self.navigationItem.title = "Comment"
                self.textCellFromText(p.message)
                if p.media != nil {
                    self.mediaCellFromMediaArray([p.media!])
                }
            }
            self.cells.append(dateCell)
            self.countsCell()
            self.actionsCell()
            self.commentsUrl = Facebook["base_url"]! + "\(self.post.id)/comments"
            self.params = ["fields" : "created_time,from,id,like_count,message,attachment,user_likes"]
        case .Twitter:
            let p = self.post as! TwitterPost
            var row = 2
            if p.retweeted! {
                self.retweetCellFromRetweetUser(p.retweetUser!)
                row++
            }
            if p.quotedStatus != nil {
                self.twitterQuote = p.quotedStatus!
                let textCell = self.tableView.dequeueReusableCellWithIdentifier("TallTextCell") as! TextTableViewCell
                textCell.setLabelText(p.text, post: self.post)
                textCell.del = self
                self.cells.append(textCell)
                if p.mediaArray != nil {
                    self.mediaCellFromMediaArray(p.mediaArray!)
                }
                let tweetCell = Utility.tableViewCellFromPost(p.quotedStatus!, tableView: self.tableView, indexPath: NSIndexPath(forRow: row, inSection: 0), signedInUser: self.post.signedInUser)!
                tweetCell.del = self
                tweetCell.setPost(p.quotedStatus!, signedInUser: p.signedInUser)
                self.cells.append(tweetCell)
                if p.location != nil {
                    self.mapCellFromLocation(p.location!)
                }
                self.insetCellReuseIdentifiers.append("TallTextCell")
                let dCell = self.tableView.dequeueReusableCellWithIdentifier("TallDateCell") as! DateTableViewCell
                dCell.setDate(self.post.date)
                self.cells.append(dCell)
            } else {
                self.textCellFromText(p.text)
                if p.mediaArray != nil {
                    self.mediaCellFromMediaArray(p.mediaArray!)
                    /*for m in p.mediaArray! {
                    self.mediaCellFromMediaArray([m])
                    }*/
                }
                if p.location != nil {
                    self.mapCellFromLocation(p.location!)
                }
                self.cells.append(dateCell)
            }
            self.countsCell()
            self.actionsCell()
            self.commentsUrl = Twitter["base_url"]! + "search/tweets.json"
            self.params = ["q" : "to:\(self.post.from!.username!)", "count" : "200", "since_id" : self.post.id]
        case .Instagram:
            let p = self.post as! InstagramPost
            if p.caption != nil {
                self.textCellFromText(p.caption!.message)
            }
            self.mediaCellFromMediaArray([p.media!])
            if p.location != nil {
                self.mapCellFromLocation(p.location!)
            }
            self.cells.append(dateCell)
            self.instagramCountsCell()
            self.actionsCell()
            self.commentsUrl = Instagram["base_url"]! + "media/\(self.post.id)/comments"
        case .Tumblr:
            let p = self.post as! TumblrPost
            if p.reblogUser != nil {
                self.retweetCellFromRetweetUser(p.reblogUser!)
            }
            switch p.postType! {
            case .Text:
                let po = p as! TumblrTextPost
                if po.title != nil {
                    self.textCellFromText(po.title!)
                }
                self.textCellFromText(po.body)
            case .Image:
                let po = p as! TumblrImagePost
                if po.caption != "" {
                    self.textCellFromText(po.caption)
                }
                self.mediaCellFromMediaArray(po.mediaArray)
            case .Link:
                let po = p as! TumblrLinkPost
                self.textCellFromText(po.description)
                if po.photos != nil {
                    self.mediaCellFromMediaArray(po.photos!)
                }
                if po.author != nil {
                    self.textCellFromText("~ \(po.author!)")
                }
            default:
                print("okidoki")
            }
            if p.tags != nil {
                var tagsString = ""
                for tag in p.tags! {
                    tagsString += "#" + tag.capitalizedString.stringByReplacingOccurrencesOfString(" ", withString: "") + " "
                }
                if tagsString != "" {
                    self.textCellFromText(tagsString)
                }
            }
            self.cells.append(dateCell)
            self.countsCell()
            self.actionsCell()
        case .SoundCloud:
            let p = self.post as! SoundCloudPost
            self.textCellFromText(p.title)
            if p.description != nil {
                if p.description! != "" {
                    self.textCellFromText(p.description!)
                }
            }
            self.mediaCellFromMediaArray([p.media!])
            self.audioCell(p.audio, data: p.soundData)
            self.cells.append(dateCell)
            if self.post.likeCount != nil && self.post.commentCount != nil {
                print(self.post.likeCount)
                print(self.post.commentCount)
                self.countsCell()
            }
            self.commentsUrl = SoundCloud["base_url"]! + "tracks/\(self.post.id)/comments"
            self.params = Dictionary<String, String>()
        default:
            print("okidoki")
        }
        if self.commentsUrl != nil {
            if self.showComments {
                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.tableView.numberOfRowsInSection(0) - 1 , inSection: 0), atScrollPosition: .Top, animated: false)
            }
            self.post.signedInUser.client.get(self.commentsUrl!, parameters: self.params, success: {
                (data, response) -> Void in
                switch self.post.type {
                case .Facebook:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let data = json["data"] as! NSArray
                    self.comments = Utility.facebookCommentsFromArray(data, signedInUser: self.post.signedInUser)
                case .Twitter:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let statuses = json["statuses"] as! NSArray
                    let posts = Utility.twitterPostsFromArray(statuses, signedInUser: self.post.signedInUser)
                    var p = [TwitterPost]()
                    for post in posts {
                        if post.inReplyToStatusId != nil {
                            if post.inReplyToStatusId! == self.post.id {
                                p.append(post)
                            }
                        }
                    }
                    self.comments = p
                case .Instagram:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let data = json["data"] as! NSArray
                    for dat in data {
                        let d = dat as! NSDictionary
                        self.comments.append(Utility.instagramCommentFromDictionary(d, signedInUser: self.post.signedInUser))
                    }
                case .SoundCloud:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSArray
                    self.comments = Utility.soundCloudCommentsFromArray(json, signedInUser: self.post.signedInUser)
                default:
                    print("okidoki")
                }
                self.loading = false
                self.tableView.reloadData()
                if self.showComments {
                    if self.comments.count > 0 {
                        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1), atScrollPosition: .Top, animated: true)
                    } else {
                        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.tableView.numberOfRowsInSection(0) - 1 , inSection: 0), atScrollPosition: .Top, animated: true)
                    }
                }
                if self.post.commentCount != nil {
                    if self.comments.count > self.post.commentCount! {
                        self.post.commentCount = self.comments.count
                        self.countCell.setPost(self.post, tableView: self.tableView)
                    }
                }
                }, failure: {
                    (error) -> Void in
                    Utility.handleError(error, message: "Error Cetting comments")
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.tableView.contentInset.bottom = Utility.contentInsetsFromAudioPlayer()
        self.tableView.scrollIndicatorInsets.bottom = Utility.contentInsetsFromAudioPlayer()
    }
    
    func audioCell(media: Media!, data: NSData?) {
        let audioCell = self.tableView.dequeueReusableCellWithIdentifier("AudioCell") as! AudioTableViewCell
        audioCell.setPost(self.post, media: media, data: data)
        self.cells.append(audioCell)
    }
    
    func mapCellFromLocation(location: Location) {
        let mapCell = self.tableView.dequeueReusableCellWithIdentifier("MapCell") as! MapTableViewCell
        mapCell.setLocation(location)
        mapCell.del = self
        self.cells.append(mapCell)
    }
    
    func actionsCell() {
        var nibName: String!
        switch post.type {
        case .Facebook:
            nibName = "FacebookActionsCell"
        case .Twitter:
            nibName = "TwitterActionsCell"
        case .Instagram:
            nibName = "InstagramActionsCell"
        case .Tumblr:
            nibName = "TumblrActionsCell"
        default:
            print("okidoki")
        }
        let actionsCell = self.tableView.dequeueReusableCellWithIdentifier(nibName) as! ActionsTableViewCell
        actionsCell.delegate = self
        actionsCell.setPost(self.post, postViewController: self, tableView: self.tableView)
        self.cells.append(actionsCell)
    }
    
    func instagramCountsCell() {
        let countsCell = self.tableView.dequeueReusableCellWithIdentifier("InstagramCountsCell") as! InstagramCountsTableViewCell
        var imageView: UIImageView!
        for cell in self.cells {
            if let c = cell as? ImageVideoTableViewCell {
                imageView = (c.mainView.subviews.first as! ImageView).imageView1
            }
        }
        countsCell.setPost(self.post, tableView: self.tableView, imageView: imageView)
        countsCell.del = self
        self.cells.append(countsCell)
        self.countCell = countsCell
    }
    
    func countsCell() {
        let countsCell = self.tableView.dequeueReusableCellWithIdentifier("CountsCell") as! CountsTableViewCell
        countsCell.setPost(self.post, tableView: self.tableView)
        countsCell.del = self
        self.cells.append(countsCell)
        self.countCell = countsCell
    }
    
    func retweetCellFromRetweetUser(user: User) {
        let retweetedCell = self.tableView.dequeueReusableCellWithIdentifier("RetweetedCell") as! RetweetedTableViewCell
        retweetedCell.setRetweetUser(user, signedInUser: self.post.signedInUser)
        retweetedCell.del = self
        self.cells.insert(retweetedCell, atIndex: 0)
    }
    
    func textCellFromText(text: String) {
        let textCell = self.tableView.dequeueReusableCellWithIdentifier("TextCell") as! TextTableViewCell
        textCell.setLabelText(text, post: self.post)
        textCell.del = self
        self.cells.append(textCell)
    }
    
    func mediaCellFromMediaArray(media: [Media]) {
        let mediaCell = self.tableView.dequeueReusableCellWithIdentifier("ImageVideoCell") as! ImageVideoTableViewCell
        mediaCell.setMediaArray(media)
        mediaCell.del = self
        self.cells.append(mediaCell)
    }
    
    func showImage(image: UIImage, view: UIView) {
        Utility.showImage(image, view: view, viewController: self)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            if self.post.type == Service.Twitter {
                return "Replies"
            } else if post.type != Service.Tumblr {
                return "Comments"
            }
        }
        return nil
    }
    
    func showUser(user: SignedInUser) {
        let profileViewController = ProfileTableViewController(user: user)
        self.pushViewController(profileViewController)
    }
    
    func showVideo(url: NSURL) {
        Utility.showVideo(url, viewController: self)
    }

    func pushViewController(viewController: UIViewController) {
        self.navigationController!.pushViewController(viewController, animated: true)
    }
        
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if !self.loadingPost {
            if (self.loading || !self.comments.isEmpty) && self.post.type != Service.Tumblr {
                return 2
            } else {
                return 1
            }
        } else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !self.loadingPost {
            if section == 0 {
                return self.cells.count
            } else {
                if self.loading {
                    return 1
                } else {
                    return self.comments.count
                }
            }
        } else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if !self.loadingPost {
            if indexPath.section == 0 {
                var cell = self.cells[indexPath.row]
                if let _ = cell as? PostTableViewCell {
                    let c = Utility.tableViewCellFromPost(self.twitterQuote!, tableView: self.tableView, indexPath: indexPath, signedInUser: self.post.signedInUser)!
                    c.del = self
                    cell = c
                }
                if self.insetCellReuseIdentifiers.contains((cell.reuseIdentifier!)) {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
                } else {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: w, bottom: 0, right: 0)
                }
                cell.selectionStyle = .None
                cell.contentView.userInteractionEnabled = false
                return cell
            } else {
                if self.loading {
                    return self.tableView.dequeueReusableCellWithIdentifier("LoadingCell")!
                } else {
                    switch self.post.type {
                    case .Facebook:
                        let comment = self.comments[indexPath.row]
                        var cell: FacebookCommentTableViewCell!
                        if let _ = comment as? FacebookImageComment {
                            cell = self.tableView.dequeueReusableCellWithIdentifier("FacebookImageCommentCell", forIndexPath: indexPath) as! FacebookCommentTableViewCell
                        } else {
                            cell = self.tableView.dequeueReusableCellWithIdentifier("FacebookCommentCell", forIndexPath: indexPath) as! FacebookCommentTableViewCell
                        }
                        cell.setPost(self.comments[indexPath.row], signedInUser: self.post.signedInUser)
                        cell.del = self
                        cell.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0)
                        return cell
                    case .Twitter:
                        let cell = Utility.tableViewCellFromPost(self.comments[indexPath.row], tableView: self.tableView, indexPath: indexPath, signedInUser: self.post.signedInUser)!
                        cell.del = self
                        cell.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0)
                        return cell
                    case .Instagram:
                        let cell = self.tableView.dequeueReusableCellWithIdentifier("InstagramCommentCell", forIndexPath: indexPath) as! InstagramCommentTableViewCell
                        cell.setPost(self.comments[indexPath.row], signedInUser: self.post.signedInUser)
                        cell.del = self
                        cell.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0)
                        return cell
                    case .SoundCloud:
                        let cell = self.tableView.dequeueReusableCellWithIdentifier("SoundCloudCommentCell", forIndexPath: indexPath) as! SoundCloudCommentTableViewCell
                        cell.setPost(self.comments[indexPath.row], signedInUser: self.post.signedInUser)
                        cell.del = self
                        return cell
                    default:
                        print("okidoki")
                        return UITableViewCell()
                    }
                }
            }
        } else {
            return self.tableView.dequeueReusableCellWithIdentifier("LoadingCell")!
        }
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 48
    }
    
    func presentViewController(viewController: UIViewController) {
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.post.type != .Instagram && self.post.type != .SoundCloud {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PostTableViewCell {
                cell.showPost(nil)
            }
        }
    }

}
