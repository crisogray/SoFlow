//
//  TextInputTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 30/09/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import CWStatusBarNotification
import SVProgressHUD

class ComposeTableViewCell: UITableViewCell, UITextViewDelegate, CLLocationManagerDelegate, UIDocumentInteractionControllerDelegate      {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var locationButton: UIButton!
    @IBOutlet var tagUserButton: UIButton!
    @IBOutlet var separator1: UIView!
    @IBOutlet var separator2: UIView!
    @IBOutlet var twitterCharacterCountLabel: UILabel!
    let documentController = UIDocumentInteractionController()
    let textViewPlaceholder = "What's Up?"
    var tableViewController: ComposeTableViewController!
    var hasEdited = false
    var composeDel: ComposeDelegate!
    var del: CellDelegate!
    var media = [LibraryPhoto]() {
        didSet {
            if !self.media.isEmpty {
                self.twitterLimit = 117
            } else {
                self.twitterLimit = 140
            }
            if self.retweetUrl != nil {
                self.twitterLimit -= 25
            }
            self.checkEligibility()
        }
    }
    var message = ""
    var choosePhotoViewController: ChoosePhotoCollectionViewController?
    var manager: CLLocationManager!
    var location: Location?
    var futurePosts: [FuturePost]!
    var composeUserViews = [ComposeUserView]()
    var inReplyToPost: Post?
    var exportedAsset: AVAsset?
    var instagramIndex = 0
    var twitterLimit = 140
    var retweetUrl: String? {
        didSet {
            if self.retweetUrl != nil {
                self.twitterLimit -= 25
            }
            self.checkEligibility()
        }
    }
    var twitterCount = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.textView.delegate = self
        self.textView.scrollEnabled = false
        self.textView.keyboardAppearance = .Dark
        self.textView.text = self.textViewPlaceholder
        self.separator1.backgroundColor = separatorColour
        self.separator2.backgroundColor = separatorColour
    }
    
    func updateMedia() {
        self.composeDel.updateMedia(self.media)
        self.checkEligibility()
    }
    
    func makeIneligible(index: Int, message: String) {
        self.composeUserViews[index].eligible = false
        self.composeUserViews[index].ineligibilityMessage = message
    }
    
    func checkEligibility() {
        self.twitterCount = false
        for (i, futurePost) in self.futurePosts.enumerate() {
            var eligible = true
            var videoFound = false
            var photoFound = false
            for m in self.media {
                if m.type == MediaType.Image {
                    photoFound = true
                } else if m.type == .Video {
                    videoFound = true
                }
            }
            if videoFound && photoFound {
                eligible = false
                self.makeIneligible(i, message: "Can't post images and video")
            } else if videoFound && !photoFound {
                if self.media.count > 1 {
                    eligible = false
                    self.makeIneligible(i, message: "Can't post more than one video")
                }
            }
            switch futurePost.signedInUser.clientUser.type {
            case .Facebook:
                if (!self.hasEdited || self.message == "") && self.media.isEmpty {
                    eligible = false
                    self.makeIneligible(i, message: "Needs a message or an attachment")
                }
                if self.inReplyToPost == nil {
                    if self.media.count > 10 {
                        eligible = false
                        self.makeIneligible(i, message: "Too many images")
                    }
                } else {
                    if videoFound {
                        eligible = false
                        self.makeIneligible(i, message: "Can't post videos")
                    }
                    if self.media.count > 1 {
                        eligible = false
                        self.makeIneligible(i, message: "Too many images")
                    }
                }
            case .Twitter:
                self.twitterCount = true
                let charactersLeft = self.twitterLimit - self.message.characters.count
                if charactersLeft < 0 {
                    self.twitterCharacterCountLabel.textColor = UIColor.lightGrayColor()
                } else {
                    self.twitterCharacterCountLabel.textColor = tintColour
                }
                self.twitterCharacterCountLabel.text = String(charactersLeft)
                if self.inReplyToPost != nil {
                    if self.textView.text.lowercaseString.rangeOfString("@" + self.inReplyToPost!.from!.username!.lowercaseString) == nil {
                        eligible = false
                        self.makeIneligible(i, message: "Text must contain the \"@username\" of the author of the tweet you are replying to")
                    }
                    let username = "@" + self.inReplyToPost!.from!.username!
                    if self.message.lowercaseString == username.lowercaseString {
                        self.hasEdited = false
                    }
                }
                if self.textView.text.characters.count > self.twitterLimit {
                    eligible = false
                    self.makeIneligible(i, message: "Too many characters")
                }
                if !self.hasEdited || self.message == "" {
                    eligible = false
                    self.makeIneligible(i, message: "Write something!")
                }
                if self.media.count > 4 {
                    eligible = false
                    self.makeIneligible(i, message: "Too many images")
                }
            case .Instagram:
                if !UIApplication.sharedApplication().canOpenURL(NSURL(string: "instagram:/app")!) {
                    eligible = false
                    self.makeIneligible(i, message: "Instagram app must be installed")
                }
                if self.media.count > 1 {
                    eligible = false
                    self.makeIneligible(i, message: "Too many images")
                } else if self.media.isEmpty {
                    eligible = false
                    self.makeIneligible(i, message: "Needs an image")
                }
                if self.media.count == 1 {
                    if self.media.first!.type == .Video {
                        eligible = false
                        self.makeIneligible(i, message: "SoFlow only currently supports posting images to Instagram")
                    }
                }
            case .Tumblr:
                if futurePost.type == FuturePostType.Post {
                    if self.media.count > 1 {
                        eligible = false
                        self.makeIneligible(i, message: "Too many images")
                    }
                    if (!self.hasEdited || self.message == "") && self.media.isEmpty {
                        eligible = false
                        self.makeIneligible(i, message: "Needs a message or an attachment")
                    }
                } else {
                    if self.media.count > 0 {
                        eligible = false
                        self.makeIneligible(i, message: "Can't post image when reblogging a Tumblr post")
                    }
                    if !self.hasEdited || self.message == "" {
                        eligible = false
                        self.makeIneligible(i, message: "Write something!")
                    }
                }
            default:
                print("okidoki")
            }
            if eligible {
                self.composeUserViews[i].eligible = true
            }
        }
        if !self.twitterCount {
            self.twitterCharacterCountLabel.text = nil
            self.textView.keyboardType = .Twitter
        } else {
            self.textView.keyboardType = .Default
        }
    }
    
    func setFuturePosts(futurePosts: [FuturePost]) {
        self.futurePosts = futurePosts
        if self.futurePosts.count == 0 {
            self.tableViewController.forceBack()
        }
        self.scrollView.contentSize.width = CGFloat(60 * futurePosts.count)
        self.composeUserViews = [ComposeUserView]()
        for subview in self.scrollView.subviews {
            if let u = subview as? ComposeUserView {
                u.removeFromSuperview()
            }
        }
        for (i, futurePost) in self.futurePosts.enumerate() {
            let userView = NSBundle.mainBundle().loadNibNamed("ComposeUserView", owner: self, options: nil)[0] as! ComposeUserView
            userView.frame = CGRectMake(CGFloat(60 * i), 0, 48, 48)
            userView.setFuturePost(futurePost)
            userView.tag = i
            userView.composeCell = self
            self.scrollView.addSubview(userView)
            self.composeUserViews.append(userView)
        }
        self.checkEligibility()
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.Black)
        SVProgressHUD.setForegroundColor(tintColour)
    }
    
    func sendCompletion(index: Int, success: Bool) {
        SVProgressHUD.dismiss()
        if success {
            self.futurePosts.removeAtIndex(index)
            self.setFuturePosts(self.futurePosts)
        }
    }
    
    func sendFuturePost(index: Int) {
        let futurePost = self.futurePosts[index]
        let url = futurePost.destinationUrl
        if futurePost.signedInUser.clientUser.type != .Instagram {
            SVProgressHUD.show()
        }
        switch futurePost.signedInUser.clientUser.type {
        case .Facebook:
            if self.media.isEmpty {
                let params = ["message" : self.message]
                self.postFacebookWithParams(futurePost, params: params, index: index)
            } else {
                let media = self.media.first!
                if media.type == .Video {
                    self.exportAsset(media.asset!, completion: {
                        (videoData) -> Void in
                        let url = "https://graph-video.facebook.com/me/videos"
                        let params = ["":""]
                        futurePost.signedInUser.client.multiPartRequest(url, method: "POST", parameters: params, image: videoData, success: {
                            (data, response) -> Void in
                            let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers))
                            let id = json["id"] as! String
                            var params = ["object_attachment" : id]
                            if self.hasEdited {
                                params["message"] = self.message
                            }
                            self.postFacebookWithParams(futurePost, params: params, index: index)
                        }, failure: {
                            (error) -> Void in
                            self.sendCompletion(index, success: false)
                            Utility.handleError(error, message: "Error Uploading Video To Facebook")
                        }, videoKey: "source")
                    })
                } else if media.type == .Image {
                    if self.inReplyToPost == nil {
                        let url = Facebook["base_url"]! + "me/albums"
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "hh:mm a - dd MMM yyyy"
                        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
                        let dateString = dateFormatter.stringFromDate(NSDate())
                        var params = ["name" : "SoFlow: \(dateString)"]
                        if self.hasEdited {
                            params["message"] = self.message
                        }
                        futurePost.signedInUser.client.post(url, parameters: params, success: {
                            (data, response) -> Void in
                            let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                            let id = json["id"] as! String
                            let count = self.media.count
                            var numberDone = 0
                            for media in self.media.reverse() {
                                let url = Facebook["base_url"]! + "\(id)/photos"
                                let data = UIImageJPEGRepresentation(media.image, 0.5)!
                                futurePost.signedInUser.client.postImage(url, parameters: ["":""], image: data, success: {
                                    (data, response) -> Void in
                                    numberDone++
                                    if numberDone == count {
                                        self.sendCompletion(index, success: true)
                                    }
                                }, failure: {
                                    (error) -> Void in
                                    self.sendCompletion(index, success: false)
                                    Utility.handleError(error, message: "Error Uploading Photo")
                                    print(error.localizedDescription)
                                })
                            }
                        }, failure: {
                            (error) -> Void in
                            self.sendCompletion(index, success: false)
                            Utility.handleError(error, message: "Error Uploading Photo")
                            print(error.localizedDescription)
                        })
                    } else {
                        var u = url!
                        if self.hasEdited {
                            u += "?message=\(self.message)"
                        }
                        let data = UIImageJPEGRepresentation(media.image, 0.5)!
                        futurePost.signedInUser.client.postImage(u, parameters: ["":""], image: data, success: {
                            (data, response) -> Void in
                            self.sendCompletion(index, success: true)
                        }, failure: {
                            (error) -> Void in
                            self.sendCompletion(index, success: false)
                            Utility.handleError(error, message: "Error Sending Facebook Comment")
                        })
                    }
                }
            }
        case .Twitter:
            var m = self.message
            if self.retweetUrl != nil {
                if self.message.hasPrefix(" ") {
                    m += self.retweetUrl!
                } else {
                    m += " " + self.retweetUrl!
                }
            }
            var params = ["status" : m]
            if self.inReplyToPost != nil {
                params["in_reply_to_status_id"] = self.inReplyToPost!.id
            }
            if self.location != nil {
                params["lat"] = String(self.location!.coordinate.latitude)
                params["long"] = String(self.location!.coordinate.longitude)
                params["display_coordinates"] = "true"
            }
            if self.media.isEmpty {
                futurePost.signedInUser.client.post(url, parameters: params, success: {
                    (data, response) -> Void in
                    self.sendCompletion(index, success: true)
                }, failure: {
                    (error) -> Void in
                    self.sendCompletion(index, success: false)
                    Utility.handleError(error, message: "Error Sending Tweet")
                })
            } else {
                var mediaIds = [String]()
                var count = self.media.count
                let u = "https://upload.twitter.com/1.1/media/upload.json"
                for media in self.media {
                    var data: NSData!
                    if media.type == .Image {
                        data = UIImageJPEGRepresentation(media.image, 0.5)!
                        futurePost.signedInUser.client.postImage(u, parameters: Dictionary<String, AnyObject>(), image: data, success: {
                            (data, response) -> Void in
                            let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                            let mediaId = json["media_id_string"] as! String
                            mediaIds.append(mediaId)
                            if mediaIds.count == count {
                                self.postTwitterWithMediaIds(mediaIds, params: params, url: url, futurePost: futurePost, index: index)
                            }
                        }, failure: {
                            (error) -> Void in
                            self.sendCompletion(index, success: false)
                            Utility.handleError(error, message: "Error Uploading Image")
                            count--
                            if mediaIds.count == count {
                                self.postTwitterWithMediaIds(mediaIds, params: params, url: url, futurePost: futurePost, index: index)
                            }
                        })
                    } else {
                        self.exportAsset(media.asset!, completion: {
                            (data) -> Void in
                            let videoDataString = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                            let p = ["command" : "INIT", "total_bytes" : String(data.length), "media_type" : "video/mp4"]
                            futurePost.signedInUser.client.post(u, parameters: p,  success: {
                                (data, response) -> Void in
                                let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                                let mediaId = json["media_id_string"] as! String
                                let p: [String : AnyObject] = ["command" : "APPEND", "segment_index" : "0", "media_id" : mediaId, "media_data" : videoDataString]
                                futurePost.signedInUser.client.post(u, parameters: p, success: {
                                    (data, response) -> Void in
                                    let p = ["command" : "FINALIZE", "media_id" : mediaId]
                                    futurePost.signedInUser.client.post(u, parameters: p, success: {
                                        (data, response) -> Void in
                                        self.postTwitterWithMediaIds([mediaId], params: params, url: url, futurePost: futurePost, index: index)
                                    }, failure: {
                                        (error) -> Void in
                                        self.sendCompletion(index, success: false)
                                        Utility.handleError(error, message: "Error Uploading Video")
                                    })
                                }, failure: {
                                    (error) -> Void in
                                    self.sendCompletion(index, success: false)
                                    Utility.handleError(error, message: "Error Uploading Video")
                                })
                            }, failure: {
                                (error) -> Void in
                                self.sendCompletion(index, success: false)
                                Utility.handleError(error, message: "Error Uploading Video")
                            })
                        })
                    }
                }
            }
        case .Instagram:
            let path = NSTemporaryDirectory().stringByAppendingString("/image.igo")
            var data: NSData!
            data = UIImageJPEGRepresentation(self.media.first!.image, 0.5)
            data.writeToFile(path, atomically: true)
            self.instagramIndex = index
            self.documentController.URL = NSURL(string: "file://\(path)")
            self.documentController.UTI = "com.instagram.exclusivegram"
            self.documentController.delegate = self
            if self.hasEdited {
                UIPasteboard.generalPasteboard().string = self.message
                Utility.handleError(nil, message: "Caption Copied To Clipboard")
            }
            self.documentController.presentOpenInMenuFromRect(self.composeUserViews[index].bounds, inView: self.tableViewController.tableView, animated: true)
        case .Tumblr:
            if futurePost.type == .Post {
                if self.media.isEmpty {
                    let params = ["type" : "text", "body" : self.message]
                    futurePost.signedInUser.client.post(url, parameters: params, success: {
                        (data, response) -> Void in
                        self.sendCompletion(index, success: true)
                    }, failure: {
                        (error) -> Void in
                        self.sendCompletion(index, success: false)
                        Utility.handleError(error, message: "Error Sending Tumblr Post")
                    })
                } else {
                    let media = self.media.first!
                    if media.type == .Video {
                        self.exportAsset(media.asset!, completion: {
                            (data) -> Void in
                            let videoData = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                            var params: [String : AnyObject] = ["type" : "video", "data64" : videoData]
                            if self.hasEdited && self.message != "" {
                                params["caption"] = self.message
                            }
                            futurePost.signedInUser.client.postMultiPartRequest(url, method: "POST", parameters: params, success: {
                                (data, response) -> Void in
                                self.sendCompletion(index, success: true)
                            }, failure: {
                                (error) -> Void in
                                self.sendCompletion(index, success: false)
                                Utility.handleError(error, message: "Error Uploading Video")
                            })
                        })
                    } else if media.type == .Image {
                        var params: [String : AnyObject] = ["type" : "photo"]
                        if self.hasEdited && self.message != "" {
                            params["caption"] = self.message
                        }
                        let data = UIImageJPEGRepresentation(media.image, 0.5)!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                        params["data64"] = data
                        futurePost.signedInUser.client.post(url, parameters: params, success: {
                            (data, response) -> Void in
                            self.sendCompletion(index, success: true)
                        }, failure: {
                            (error) -> Void in
                            self.sendCompletion(index, success: false)
                            Utility.handleError(error, message: "Error Sending Tumblr Post")
                        })
                        
                    }
                }
            } else {
                let url = Tumblr["base_url"]! + "blog/\(self.inReplyToPost!.signedInUser.clientUser.name!).tumblr.com/post/reblog"
                let p = self.inReplyToPost! as! TumblrPost
                var params = ["id" : self.inReplyToPost!.id, "reblog_key" : p.reblogKey]
                if self.hasEdited  {
                    params["comment"] = self.message
                }
                self.inReplyToPost!.signedInUser.client.post(url, parameters: params, success: {
                    (data, response) -> Void in
                    self.sendCompletion(index, success: true)
                }, failure: {
                    (error) -> Void in
                    self.sendCompletion(index, success: false)
                    Utility.handleError(error, message: "Error Reblogging Post")
                })
            }
        default:
            print("okidoki")
        }
    }
    
    func postFacebookWithParams(futurePost: FuturePost, params: [String : AnyObject], index: Int) {
        futurePost.signedInUser.client.post(futurePost.destinationUrl, parameters: params, success: {
            (data, response) -> Void in
            self.sendCompletion(index, success: true)
        }, failure: {
            (error) -> Void in
            self.sendCompletion(index, success: false)
            var errorMessage: String!
            if self.inReplyToPost == nil {
                errorMessage = "Error Sending Facebook Post"
            } else {
                errorMessage = "Error Sending Facebook Comment"
            }
            Utility.handleError(error, message: errorMessage)
        })
    }
    
    func exportAsset(asset: AVAsset, completion: (data: NSData) -> Void) {
        var pathString = NSTemporaryDirectory().stringByAppendingString("/video.mp4")
        if self.exportedAsset != asset {
                if NSFileManager.defaultManager().fileExistsAtPath(pathString) {
                    (try! NSFileManager.defaultManager().removeItemAtPath(pathString))
                }
                pathString = "file://" + pathString
                let path = NSURL(string: pathString)!
                let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720)!
                session.outputURL = path
                session.outputFileType = AVFileTypeMPEG4
                session.shouldOptimizeForNetworkUse = true
                session.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
                session.exportAsynchronouslyWithCompletionHandler({
                    () -> Void in
                    self.exportedAsset = asset
                    let videoData = NSData(contentsOfURL: path)!
                    completion(data: videoData)
                })
        } else {
            pathString = "file://" + pathString
            let path = NSURL(string: pathString)!
            let videoData = NSData(contentsOfURL: path)!
            completion(data: videoData)
        }
    }

    func postTwitterWithMediaIds(ids: [String], var params: Dictionary<String, AnyObject>, url: String, futurePost: FuturePost, index: Int) {
        var mediaIdsString = ""
        for id in ids {
            if id != ids.last {
                mediaIdsString.appendContentsOf("\(id),")
            } else {
                mediaIdsString.appendContentsOf(id)
            }
        }
        params["media_ids"] = mediaIdsString
        futurePost.signedInUser.client.post(url, parameters: params, success: {
            (data, response) -> Void in
            self.sendCompletion(index, success: true)
        }, failure: {
            (error) -> Void in
            self.sendCompletion(index, success: false)
            Utility.handleError(error, message: "Error Sending Tweet")
        })
    }

    func textViewDidBeginEditing(textView: UITextView) {
        if !self.hasEdited && textView.text == self.textViewPlaceholder {
            self.textView.text = nil
        }
    }

    func textViewDidChange(textView: UITextView) {
        self.hasEdited = true
        let currentSize = self.textView.frame
        let newSize = self.textView.sizeThatFits(CGSizeMake(currentSize.width, CGFloat.max))
        if newSize.height != currentSize.height {
            UIView.setAnimationsEnabled(false)
            self.tableViewController.tableView.beginUpdates()
            self.tableViewController.tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        }
        self.tableViewController.tableView.scrollToRowAtIndexPath(self.tableViewController.tableView.indexPathForCell(self)!, atScrollPosition: .Bottom , animated: false)
        self.message = self.textView.text
        self.checkEligibility()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if !self.hasEdited && self.message == "" {
            self.textView.text = self.textViewPlaceholder
            self.hasEdited = false
        }
    }
    
    @IBAction func tagUser(sender: AnyObject) {
    }
    
    @IBAction func addPhoto(sender: AnyObject) {
        self.textView.resignFirstResponder()
        var viewController = self.choosePhotoViewController
        if viewController == nil {
            viewController = ChoosePhotoCollectionViewController(max: 4, cell: self)
        }
        self.del.pushViewController(viewController!)
    }
    
    @IBAction func addLocation(sender: AnyObject) {
        if self.location == nil {
            if self.locationButton.currentImage != nil {
                self.manager = CLLocationManager()
                self.manager.desiredAccuracy = kCLLocationAccuracyBest
                self.manager.delegate = self
                self.manager.requestAlwaysAuthorization()
                self.manager.startUpdatingLocation()
                self.locationButton.setImage(nil, forState: .Normal)
                let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
                let xY = self.locationButton.frame.width / 2
                activityIndicator.center = CGPointMake(xY, xY)
                activityIndicator.startAnimating()
                self.locationButton.addSubview(activityIndicator)
            }
        } else {
            self.returnLocation()
        }
    }
    
    func documentInteractionController(controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
        self.sendCompletion(self.instagramIndex, success: true)
    }
    
    func returnLocation() {
        self.textView.resignFirstResponder()
        self.locationButton.setImage(UIImage(named: "Map Marker 24px")!, forState: .Normal)
        if self.composeDel.returnLocation(self.location!) {
            self.locationButton!.tintColor = UIColor.blackColor()
        } else {
            self.locationButton!.tintColor = tintColor
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc = locations.first!
        CLGeocoder().reverseGeocodeLocation(loc) {
            (placemarks, error) -> Void in
            if error == nil {
                if placemarks != nil {
                    if placemarks!.count > 0 {
                        let placemark = placemarks!.first!
                        var locality: String!
                        var thoroughfare: String!
                        if placemark.subLocality != nil {
                            locality = placemark.subLocality!
                        } else if placemark.locality != nil {
                            locality = placemark.locality!
                        } else if placemark.subAdministrativeArea != nil {
                            locality = placemark.subAdministrativeArea!
                        } else if placemark.administrativeArea != nil {
                            locality = placemark.administrativeArea!
                        } else if placemark.country != nil {
                            locality = placemark.country!
                        } else {
                            locality = ""
                        }
                        if placemark.thoroughfare != nil {
                            thoroughfare = placemark.thoroughfare!
                        } else {
                            thoroughfare = ""
                        }
                        let name = "\(thoroughfare), \(locality!)"
                        let location = Location(coordinate: loc.coordinate, name: name)
                        self.location = location
                        for view in self.locationButton.subviews {
                            if let aI = view as? UIActivityIndicatorView {
                                aI.removeFromSuperview()
                            }
                        }
                        self.returnLocation()
                    }
                }
            }            
        }
        manager.stopUpdatingLocation()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.textView.endEditing(true)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error.localizedDescription)
    }

}
