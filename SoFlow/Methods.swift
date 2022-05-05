//
//  Methods.swift
//  SoFlow
//
//  Created by Ben Gray on 07/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import AVKit
import OAuthSwift
import JTSImageViewController
import MapKit
import CWStatusBarNotification
import PBWebViewController

extension UIView {
    func addTap(target: AnyObject, action: Selector) {
        if self.gestureRecognizers != nil {
            if !self.gestureRecognizers!.isEmpty {
                for gR in self.gestureRecognizers! {
                    if gR.isKindOfClass(UITapGestureRecognizer.classForCoder()) {
                        let gestureRecogniser = gR 
                        self.removeGestureRecognizer(gestureRecogniser)
                    }
                }
            }
        }
        let tapRec = UITapGestureRecognizer(target: target, action: action)
        self.addGestureRecognizer(tapRec)
        self.userInteractionEnabled = true
    }
    
    func addLongPress(target: AnyObject, action: Selector) {
        if self.gestureRecognizers != nil {
            if !self.gestureRecognizers!.isEmpty {
                for gR in self.gestureRecognizers! {
                    if gR.isKindOfClass(UILongPressGestureRecognizer.classForCoder()) {
                        let gestureRecogniser = gR 
                        self.removeGestureRecognizer(gestureRecogniser)
                    }
                }
            }
        }
        let longPressRec = UILongPressGestureRecognizer(target: target, action: action)
        longPressRec.minimumPressDuration = animationDuration
        self.addGestureRecognizer(longPressRec)
        self.userInteractionEnabled = true
    }
    
}

class Utility {

    class func facebookUserFromDictionary(json: NSDictionary, signedInUser: SignedInUser?) -> FacebookUser {
        let id = json["id"] as! String
        let name = json["name"] as! String
        var verified: Bool?
        if let v = json["is_verified"] as? Bool {
            verified = v
        }
        var profilePictureUrl: NSURL!
        if let p = json["picture"] as? NSDictionary {
            let data = p["data"] as! NSDictionary
            let urlString = data["url"] as! String
            profilePictureUrl = NSURL(string: urlString)
        } else {
            profilePictureUrl = facebookProfilePictureFromId(id, large: false)
        }
        let profilePictureLargeUrl = facebookProfilePictureFromId(id, large: true)
        var location: String?
        if let l = json["location"] as? NSDictionary {
            if let name = l["name"] as? String {
                location = name
            }
        }
        var likes: [FacebookPage]?
        if let l = json["likes"] as? NSDictionary {
            likes = facebookLikesFromDictionary(l)
        }
        let user = FacebookUser(id: id, name: name, profilePictureUrl: profilePictureUrl, verified: verified, location: location, likes: likes)
        user.profilePictureLargeUrl = profilePictureLargeUrl
        return user
    }
    
    class func facebookLikesFromDictionary(likes: NSDictionary) -> [FacebookPage]? {
        let data = likes["data"] as! NSArray
        var likes = [FacebookPage]()
        for like in data {
            let l = like as! NSDictionary
            let id = l["id"] as! String
            let name = l["name"] as! String
            let page = FacebookPage(id: id, name: name, profilePictureUrl: facebookProfilePictureFromId(id, large: false))
            likes.append(page)
        }
        return likes
    }
    
    class func facebookCheckIfUserLikes(likers: [FacebookUser], id: String) -> Bool {
        for liker in likers {
            if liker.id == id {
                return true
            }
        }
        return false
    }
    
    class func facebookPostsFromData(json: NSArray, type: String?, signedInUser: SignedInUser!) -> [FacebookPost] {
        var j = json
        var js = [AnyObject]()
        var posts = [FacebookPost]()
        var objectIds = [String : FacebookPost]()
        var postsToRemove = [FacebookPost]()
        for item in json {
            if let posts = (item as! NSDictionary)["posts"] as? NSDictionary {
                if let data = posts["data"] as? NSArray {
                    for i in data {
                        js.append(i)
                    }
                }
                j = js
            }
        }
        for item in j {
            var badPost = false
            var obj: String?
            let i = item as! NSDictionary
            let id = i["id"] as! String
            var date: NSDate!
            if let dateString = i["created_time"] as? String {
                date = facebookDateFromString(dateString)
            } else if let dateString = i["updated_time"] as? String {
                date = facebookDateFromString(dateString)
            }
            if i["from"] == nil {
                print(json)
            }
            let from = i["from"] as! NSDictionary
            let user = facebookUserFromDictionary(from, signedInUser: nil)
            var message: String?
            if let m = i["message"] as? String {
                message = m
            }
            var story: String?
            if let s = i["story"] as? String {
                story = s
            }
            var commentCount: Int!
            if let c = i["comments"] as? NSDictionary {
                if let s = c["summary"] as? NSDictionary {
                    let count = s["total_count"] as! Int
                    commentCount = count
                }
            }
            var caption: String?
            if let c = i["caption"] as? String {
                caption = c
            }
            var description: String?
            if let d = i["description"] as? String {
                description = d
            }
            var name: String?
            if let n = i["name"] as? String {
                name = n
            }
            var userLikes: Bool!
            var likeCount: Int!
            if let l = i["likes"] as? NSDictionary {
                let data = l["data"] as! NSArray
                let likes = facebookPostLikesFromArray(data)
                userLikes = facebookCheckIfUserLikes(likes, id: signedInUser.clientUser.id)
                if let s = l["summary"] as? NSDictionary {
                    let count = s["total_count"] as! Int
                    likeCount = count
                }
            } else {
                userLikes = false
            }
            /*let storyTags: [TextTag]?
            if let t = i["story_tags"] as? NSArray {
                storyTags = facebookStoryTagsFromArray(t)
            }
            let withTags: [FacebookUser]?
            if let t = i["with_tags"] as? NSDictionary {
                let data = t["data"] as! NSArray
                var tags = [FacebookUser]()
                for item in data {
                    let i = item as! NSDictionary
                    let user = facebookUserFromDictionary(i, signedInUser: nil)
                    tags.append(user)
                }
                withTags = tags
            }*/
            var media: Media?
            var photos: [Media]?
            var t: String!
            if let ty = i["type"] as? String {
                t = ty
            } else {
                t = type!
            }
            if t == "link" {
                if let linkString = i["link"] as? String {
                    let link = NSURL(string: linkString)
                    if let fullPicture = i["full_picture"] as? String {
                        if let pictureUrlString = getQueryStringParameter(fullPicture, param: "url") {
                            let pictureUrl = NSURL(string: pictureUrlString)
                            media = FacebookLink(url: pictureUrl, linkUrl: link)
                        }
                    }
                } else {
                    badPost = true
                }
            } else if t == "photo" {
                photos = [Media]()
                if let a = i["attachments"] as? NSDictionary {
                    let data = a["data"] as! NSArray
                    for dat in data {
                        let d = dat as! NSDictionary
                        if let subattachments = d["subattachments"] as? NSDictionary {
                            let data = subattachments["data"] as! NSArray
                            for dat in data {
                                let da = dat as! NSDictionary
                                let media = da["media"] as! NSDictionary
                                let image = media["image"] as! NSDictionary
                                photos!.append(facebookMediaFromDictionary(image, urlName: "src"))
                            }
                        } else {
                            if let m = d["media"] as? NSDictionary {
                                if let i = m["image"] as? NSDictionary {
                                    photos!.append(facebookMediaFromDictionary(i, urlName: "src"))
                                }
                            }
                            if let t = d["target"] as? NSDictionary {
                                if let objectId = t["id"] as? String {
                                    obj = objectId
                                }
                            }
                        }
                    }
                } else if let _ = i["width"] as? CGFloat {
                    if let _ = i["source"] as? String {
                        photos!.append(facebookMediaFromDictionary(i, urlName: "source"))
                    } else if let _ = i["full_picture"] as? String {
                        photos!.append(facebookMediaFromDictionary(i, urlName: "full_picture"))
                    }
                } else if let url = i["full_picture"] as? String {
                    let media = Media(type: .Image, url: NSURL(string: url)!)
                    media.scale = 9 / 16
                    photos?.append(media)
                }
            } else if t == "video" {
                var thumbnailUrl: NSURL!
                let urlString = i["source"] as! String
                let url = NSURL(string: urlString)
                var scale: CGFloat?
                if let format = i["format"] as? NSArray {
                    let f = format.lastObject as! NSDictionary
                    let h = f["height"] as! CGFloat
                    let w = f["width"] as! CGFloat
                    scale = h / w
                    let thumbnailUrlString = f["picture"] as! String
                    thumbnailUrl = NSURL(string: thumbnailUrlString)!
                } else if let a = i["attachments"] as? NSDictionary {
                    let data = a["data"] as! NSArray
                    let d = data[0] as! NSDictionary
                    if let m = d["media"] as? NSDictionary {
                        if let image = m["image"] as? NSDictionary {
                            let h = image["height"] as! CGFloat
                            let w = image["width"] as! CGFloat
                            scale = h / w
                            let thumbnailUrlString = image["src"] as! String
                            thumbnailUrl = NSURL(string: thumbnailUrlString)!
                        }
                    }
                    if let t = d["target"] as? NSDictionary {
                        if let objectId = t["id"] as? String {
                            obj = objectId
                        }
                    }
                } else {
                   badPost = true
                }
                if scale > 1 {
                    scale = 1
                }
                media = Media(type: .Video, url: url)
                media!.scale = scale
                media!.thumbnail = thumbnailUrl
            }
            if !badPost {
                let post = FacebookPost(id: id, from: user, date: date, signedInUser: signedInUser, message: message, story: story, storyTags: nil, withTags: nil, name: name, description: description, caption: caption, comments: nil, likes: nil, media: media, userLikes: userLikes, likeCount: likeCount, commentCount: commentCount, photos: photos)
                if type == nil {
                    if story != nil {
                        if obj == nil {
                            if let objectId = i["object_id"] as? String {
                                obj = objectId
                            }
                        }
                        if obj != nil {
                            objectIds[obj!] = post
                        }
                    }
                    if id.rangeOfString("_") != nil {
                        let objectId = id.componentsSeparatedByString("_")[1]
                        if objectIds.keys.contains(objectId) {
                            objectIds[objectId]!.embeddedPost = post
                            postsToRemove.append(post)
                        }
                    }
                }
                posts.append(post)
            } else {
                print(json)
            }
        }
        if type == "video" {
            print("VIDEO")
            print(posts)
        }
        let p = NSMutableArray(array: posts)
        if posts.count > 1 {
            p.removeObjectsInArray(postsToRemove)
        }
        let po = NSArray(array: p)
        
        return po as! [FacebookPost]
    }
    
    class func facebookMediaFromDictionary(dictionary: NSDictionary, urlName: String) -> Media {
        let w = dictionary["width"] as! CGFloat
        let h = dictionary["height"] as! CGFloat
        let scale = h / w
        let urlString = dictionary[urlName] as! String
        let url = NSURL(string: urlString)
        let media = Media(type: .Image, url: url)
        media.scale = scale
        return media
    }
    
    class func facebookCommentsFromArray(json: NSArray, signedInUser: SignedInUser) -> [FacebookComment] {
        var comments = [FacebookComment]()
        for item in json {
            let i = item as! NSDictionary
            let id = i["id"] as! String
            let message = i["message"] as! String
            let likeCount = i["like_count"] as! Int
            let from = i["from"] as! NSDictionary
            let user = facebookUserFromDictionary(from, signedInUser: nil)
            let dateString = i["created_time"] as! String
            let date = facebookDateFromString(dateString)
            var tags: [TextTag]?
            if let messageTags = i["message_tags"] as? NSArray {
                tags = facebookStoryTagsFromArray(messageTags)
            }
            let userLikes = i["user_likes"] as! Bool
            if let a = i["attachment"] as? NSDictionary {
                let comment = FacebookImageComment(id: id, from: user, message: message, date: date, likeCount: likeCount, tags: tags, signedInUser: signedInUser, userLikes: userLikes)
                if let t = a["target"] as? NSDictionary {
                    let urlString = t["url"] as! String
                    let url = NSURL(string: urlString)
                    comment.link = url
                }
                if let m = a["media"] as? NSDictionary {
                    if let im = m["image"] as? NSDictionary {
                        let h = im["height"] as! CGFloat
                        let w = im["width"] as! CGFloat
                        let scale = h / w
                        let urlString = im["src"] as! String
                        let url = NSURL(string: urlString)
                        let media = Media(type: .Image, url: url)
                        media.scale = scale
                        comment.media = media
                    }
                }
                comments.append(comment)
            } else {
                let comment = FacebookComment(id: id, from: user, message: message, date: date, likeCount: likeCount, tags: tags, signedInUser: signedInUser, userLikes: userLikes)
                comments.append(comment)
            }
        }
        return comments
    }
    
    class func facebookPostLikesFromArray(json: NSArray) -> [FacebookUser] {
        var users = [FacebookUser]()
        for item in json {
            let i = item as! NSDictionary
            let user = facebookUserFromDictionary(i, signedInUser: nil)
            users.append(user)
        }
        return users
    }
    
    class func facebookDateFromString(string: String) -> NSDate {
        let date = dateFromStringAndFormat(string, format: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")
        return date
    }
    
    class func facebookStoryTagsFromArray(json: NSArray) -> [TextTag] {
        var tags = [TextTag]()
        for item in json {
            if item.isKindOfClass(NSMutableArray.classForCoder()) {
                let i = item as! NSArray
                for item in i {
                    let i = item as! NSDictionary
                    let user = facebookUserFromDictionary(i, signedInUser: nil)
                    let length = i["length"] as! Int
                    let offset = i["offset"] as! Int
                    let range = NSRange(location: offset, length: length)
                    let textTag = TextTag(user: user, range: range)
                    tags.append(textTag)
                }
            } else {
                let i = item as! NSDictionary
                let user = facebookUserFromDictionary(i, signedInUser: nil)
                let length = i["length"] as! Int
                let offset = i["offset"] as! Int
                let range = NSRange(location: offset, length: length)
                let textTag = TextTag(user: user, range: range)
                tags.append(textTag)
            }
        }
        return tags
    }
    
    class func facebookPhotoTagsFromArray(json: NSArray) -> [PhotoTag] {
        var tags: [PhotoTag]!
        for item in json {
            let i = item as! NSDictionary
            let user = facebookUserFromDictionary(i, signedInUser: nil)
            let x = i["x"] as! CGFloat
            let y = i["y"] as! CGFloat
            let tag = PhotoTag(user: user, x: x, y: y)
            tags.append(tag)
        }
        return tags
    }
    
    class func facebookUserFromSavedDictionary(dictionary: NSDictionary) -> SignedInUser {
        let id = dictionary["id"]! as! String
        let name = dictionary["name"]! as! String
        let profilePictureUrl = facebookProfilePictureFromId(id, large: false)
        let profilePictureLargeUrl = facebookProfilePictureFromId(id, large: true)
        let access_token = dictionary["access_token"] as! String
        let u = FacebookUser(id: id, name: name, profilePictureUrl: profilePictureUrl)
        u.profilePictureLargeUrl = profilePictureLargeUrl
        let key = Facebook["key"]!
        let secret = Facebook["secret"]!
        let client = OAuthSwiftClient(consumerKey: key, consumerSecret: secret, accessToken: access_token, accessTokenSecret: "")
        client.credential.oauth2 = true
        let user = SignedInUser(client: client, user: u, clientUser: u)
        return user
    }
    
    class func facebookPagesFromDictionary(json: NSArray) -> [FacebookPage] {
        var pages = [FacebookPage]()
        for item in json {
            let i = item as! NSDictionary
            let id = i["id"] as! String
            let name = i["name"] as! String
            let page = FacebookPage(id: id, name: name, profilePictureUrl: facebookProfilePictureFromId(id, large: false))
            if let c = i["category"] as? String {
                page.category = c
            }
            pages.append(page)
        }
        return pages
    }
    
    class func facebookProfilePictureFromId(id: String, large: Bool) -> NSURL {
        if large {
            return NSURL(string: Facebook["base_url"]! + id + "/picture?width=600&height=600")!
        } else {
            return NSURL(string: Facebook["base_url"]! + id + "/picture?width=100&height=100")!
        }
    }
    
    class func facebookCaptionFromPost(p: FacebookPost) -> String? {
        var caption: String?
        if p.name != nil {
            caption = p.name!
        }
        if p.description != nil {
            if p.description != "" {
                if caption == nil {
                    caption = p.description!
                } else {
                    caption! += "\r" + p.description!
                }
            }
        }
        if p.caption != nil {
            if p.caption != "" {
                if caption == nil {
                    caption = p.caption!
                } else {
                    caption! += "\r" + p.caption!
                }
            }
        }
        return caption
    }
    
    class func facebookNotificationsFromArray(array: NSArray, signedInUser: SignedInUser) -> [FacebookNotification] {
        var notifications = [FacebookNotification]()
        for item in array {
            let i = item as! NSDictionary
            let id = i["id"] as! String
            let fromDictionary = i["from"] as! NSDictionary
            let from = facebookUserFromDictionary(fromDictionary, signedInUser: signedInUser)
            let dateString = i["created_time"] as! String
            let date = facebookDateFromString(dateString)
            let title = i["title"] as! String
            var objectId: String?
            if let object = i["object"] as? NSDictionary {
                objectId = object["id"] as? String
            }
            let notification = FacebookNotification(id: id, from: from, date: date, signedInUser: signedInUser, title: title, objectId: objectId)
            notifications.append(notification)
        }
        return notifications
    }
    
    class func twitterUserFromSavedDictionary(dictionary: NSDictionary) -> SignedInUser {
        let id = dictionary["id"]! as! String
        let name = dictionary["name"]! as! String
        let username = dictionary["username"] as! String
        let profilePictureUrlString = dictionary["profilePictureUrl"]! as! String
        let profilePictureUrl = NSURL(string: profilePictureUrlString.stringByReplacingOccurrencesOfString("_normal", withString: "_bigger"))
        let profilePictureLargeUrl = twitterLargeProfilePictureUrlFromUrl(profilePictureUrl!)
        let access_token = dictionary["access_token"] as! String
        let access_token_secret = dictionary["access_token_secret"] as! String
        let u = TwitterUser(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl)
        u.profilePictureLargeUrl = profilePictureLargeUrl
        if dictionary["verified"] == nil {
            u.verified = false
        } else {
            if dictionary["verified"]! as! String == "false" {
                u.verified = false
            } else {
                u.verified = true
            }
        }
        let key = Twitter["key"]!
        let secret = Twitter["secret"]!
        let client = OAuthSwiftClient(consumerKey: key, consumerSecret: secret, accessToken: access_token, accessTokenSecret: access_token_secret)
        let user = SignedInUser(client: client, user: u, clientUser: u)
        return user
    }
    
    class func twitterUserFromDictionary(i: NSDictionary) -> TwitterUser {
        let id = i["id_str"] as! String
        let name = i["name"] as! String
        let username = i["screen_name"] as! String
        var profilePictureUrl: NSURL?
        if let ppUrlString = i["profile_image_url_https"] as? String {
            profilePictureUrl = NSURL(string: ppUrlString.stringByReplacingOccurrencesOfString("_normal", withString: "_bigger"))
        } else {
            let user = TwitterUser(id: id, name: name, username: username, profilePictureUrl: nil)
            return user
        }
        let favouriteCount = i["favourites_count"] as! Int
        let followersCount = i["followers_count"] as! Int
        let followingCount = i["friends_count"] as! Int
        let verified = i["verified"] as! Bool
        let following: Bool!
        if let f = i["following"] as? Bool {
            following = f
        } else {
            following = false
        }
        let tweetCount = i["statuses_count"] as! Int
        var description: String?
        let d = i["description"] as! String
        if d != "" {
            description = d
        }
        var location: String?
        let l = i["location"] as! String
        if l != "" {
            location = l
        }
        var url: NSURL?
        if let u = i["url"] as? String {
            url = NSURL(string: u)
        }
        let user = TwitterUser(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, favouriteCount: favouriteCount, followersCount: followersCount, followingCount: followingCount, verified: verified, description: description, location: location, url: url, tweetCount: tweetCount, following: following)
        user.profilePictureLargeUrl = twitterLargeProfilePictureUrlFromUrl(profilePictureUrl!)
        return user
    }
    
    class func twitterPostsFromArray(data: NSArray, signedInUser: SignedInUser) -> [TwitterPost] {
        var posts = [TwitterPost]()
        for item in data {
            var badPost = false
            var i = item as! NSDictionary
            var retweeted = false
            var retweetUser: TwitterUser?
            if i["retweeted_status"] != nil {
                retweeted = true
                let userDictionary = i["user"] as! NSDictionary
                retweetUser = twitterUserFromDictionary(userDictionary)
                i = i["retweeted_status"] as! NSDictionary
            }
            var media: [Media]?
            var mediArray: NSArray?
            if let extendedEntities = i["extended_entities"] as? NSDictionary {
                if let arr = extendedEntities["media"] as? NSArray {
                    mediArray = arr
                }
            } else if let extendedEntities = i["entities"] as? NSDictionary {
                if let arr = extendedEntities["media"] as? NSArray {
                    mediArray = arr
                }
            }
            var quotedStatus: TwitterPost?
            if let quote = i["quoted_status"] as? NSDictionary {
                let quotes = twitterPostsFromArray([quote], signedInUser: signedInUser)
                if !quotes.isEmpty {
                    quotedStatus = quotes[0]
                }
            }
            var location: TwitterLocation?
            if let p = i["place"] as? NSDictionary {
                let id = p["id"] as! String
                let fullName = p["full_name"] as! String
                let country = p["country"] as! String
                let countryCode = p["country_code"] as! String
                if let bb = p["bounding_box"] as? NSDictionary {
                    let coordinates = (bb["coordinates"] as! NSArray)[0] as! NSArray
                    var lng: CGFloat = 0
                    var lat: CGFloat = 0
                    for coord in coordinates {
                        let c = coord as! NSArray
                        lng += CGFloat(c[0].floatValue)
                        lat += CGFloat(c[1].floatValue)
                    }
                    lng = lng / CGFloat(coordinates.count)
                    lat = lat / CGFloat(coordinates.count)
                    let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(lat), CLLocationDegrees(lng))
                    location = TwitterLocation(id: id, name: fullName, country: country, countryCode: countryCode, coordinate: coordinate)
                }
            }
            if mediArray != nil {
                var medi = [Media]()
                for med in mediArray! {
                    let m = med as! NSDictionary
                    let type = m["type"] as! String
                    let sizesDictionary = m["sizes"] as! NSDictionary
                    let largeDictionary = sizesDictionary["large"] as! NSDictionary
                    let height = largeDictionary["h"] as! CGFloat
                    let width = largeDictionary["w"] as! CGFloat
                    var scale = height / width
                    if type == "photo" {
                        let pictureUrlString = m["media_url_https"] as! String
                        let pictureUrl = NSURL(string: pictureUrlString)!
                        let image = Media(type: .Image, url: pictureUrl)
                        image.scale = scale
                        medi.append(image)
                    } else {
                        let videoInfoDictionary = m["video_info"] as! NSDictionary
                        let variantsArray = videoInfoDictionary["variants"] as! NSArray
                        var currentBitrate = 0
                        var currentVariant: NSDictionary?
                        for variant in variantsArray {
                            let v = variant as! NSDictionary
                            let type = v["content_type"] as! String
                            if type == "video/mp4" {
                                if let bitrate = v["bitrate"] as? Int {
                                    if bitrate > currentBitrate {
                                        currentBitrate = bitrate
                                        currentVariant = v
                                    }
                                }
                            }
                        }
                        if currentVariant != nil {
                            let videoUrlString = currentVariant!["url"] as! String
                            let videoUrl = NSURL(string: videoUrlString)!
                            let video = Media(type: .Video, url: videoUrl)
                            if scale > 1 {
                                scale = 1
                            }
                            video.scale = scale
                            let thumbnailUrlString = m["media_url_https"] as! String
                            let thumbnailUrl = NSURL(string: thumbnailUrlString)
                            video.thumbnail = thumbnailUrl
                            medi.append(video)
                        }
                    }
                }
                media = medi
            }
            let id = i["id_str"] as! String
            if let userDictionary = i["user"] as? NSDictionary {
                let from = twitterUserFromDictionary(userDictionary)
                let dateString = i["created_at"] as! String
                let date = twitterDateFromString(dateString)
                let userLikes = i["favorited"] as! Bool
                let likeCount = i["favorite_count"] as! Int
                var inReplyToUserId: String?
                if i["in_reply_to_user_id"] != nil {
                    inReplyToUserId = i["in_reply_to_user_id"] as? String
                }
                var inReplyToStatusId: String?
                if i["in_reply_to_status_id_str"] != nil {
                    inReplyToStatusId = i["in_reply_to_status_id_str"] as? String
                }
                var userMentions: [TextTag]?
                let entitiesDictionary = i["entities"] as! NSDictionary
                if let userMentionsDictionary = entitiesDictionary["user_mentions"] as? NSArray {
                    var tags = [TextTag]()
                    for dict in userMentionsDictionary {
                        let d = dict as! NSDictionary
                        let user = Utility.twitterUserFromDictionary(d)
                        let indicesArray = d["indices"] as! NSArray
                        let location = indicesArray[0] as! Int
                        let length  = indicesArray[1] as! Int - location
                        let range = NSRange(location: location, length: length)
                        let tag = TextTag(user: user, range: range)
                        tags.append(tag)
                    }
                    userMentions = tags
                }
                var text = i["text"] as! String
                text = text.stringByReplacingOccurrencesOfString("&amp;", withString: "&")
                text = text.stringByReplacingOccurrencesOfString("&lt;", withString: "<")
                text = text.stringByReplacingOccurrencesOfString("&gt;", withString: ">")
                let retweetCount = i["retweet_count"] as! Int
                let userRetweeted = i["retweeted"] as! Bool
                let post = TwitterPost(id: id, from: from, date: date, signedInUser: signedInUser, mediaArray: media, userLikes: userLikes, likeCount: likeCount, text: text, retweeted: retweeted, retweetCount: retweetCount, userRetweeted: userRetweeted, retweetUser: retweetUser, inReplyToUserId: inReplyToUserId, inReplyToStatusId: inReplyToStatusId, userMentions: userMentions, quotedStatus: quotedStatus, location: location)
                for p in posts {
                    if p.id == post.id {
                        badPost = true
                    }
                    if from.id == p.from!.id {
                        post.from = p.from
                    }
                }
                if !badPost {
                    posts.append(post)
                }
            }
        }
        return posts
    }
    
    class func twitterListsFromArray(array: NSArray) -> [TwitterList] {
        var lists = [TwitterList]()
        for item in array {
            let i = item as! NSDictionary
            let id = i["id_str"] as! String
            let name = i["name"] as! String
            let userDictionary = i["user"] as! NSDictionary
            let user = twitterUserFromDictionary(userDictionary)
            let memberCount = i["member_count"] as! Int
            let subscribercount = i["subscriber_count"] as! Int
            let description = i["description"] as? String
            let list = TwitterList(id: id, name: name, owner: user, memberCount: memberCount, subscriberCount: subscribercount, description: description)
            lists.append(list)
        }
        return lists
    }
    
    class func twitterDateFromString(string: String) -> NSDate {
        return Utility.dateFromStringAndFormat(string, format: "EEE MMM dd HH:mm:ss Z yyyy")
    }
    
    class func twitterLargeProfilePictureUrlFromUrl(url: NSURL) -> NSURL {
        let string = url.absoluteString.stringByReplacingOccurrencesOfString("_bigger", withString: "")
        let u = NSURL(string: string)
        return u!
    }
    
    class func instagramUserFromDictionary(i: NSDictionary) -> InstagramUser {
        let id = i["id"] as! String
        var name: String?
        if i["full_name"] != nil {
            name = i["full_name"] as? String
        }
        let username = i["username"] as! String!
        let profilePictureUrlString = i["profile_picture"] as! String
        let profilePictureUrl = NSURL(string: profilePictureUrlString)!
        var followersCount: Int?
        var followingCount: Int?
        var postsCount: Int?
        if let c = i["counts"] as? NSDictionary {
            followersCount = c["followed_by"] as? Int
            followingCount = c["follows"] as? Int
            postsCount = c["media"] as? Int
        }
        var bio: String?
        if let b = i["bio"] as? String {
            bio = b
        }
        var website: NSURL?
        if let u = i["website"] as? String {
            website = NSURL(string: u)
        }
        let user = InstagramUser(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, followersCount: followersCount, followingCount: followingCount, postCount: postsCount, bio: bio, website: website)
        return user
    }
    
    class func instagramPostsFromArray(data: NSArray, signedInUser: SignedInUser) -> [InstagramPost] {
        var posts = [InstagramPost]()
        for item in data {
            let i = item as! NSDictionary
            let id = i["id"] as! String
            let fromDictionary = i["user"] as! NSDictionary
            let from = Utility.instagramUserFromDictionary(fromDictionary)
            let timeInterval = (i["created_time"] as! NSString).floatValue
            let date = NSDate(timeIntervalSince1970: NSTimeInterval(timeInterval))
            let commentDictionary = i["comments"] as! NSDictionary
            let commentCount = commentDictionary["count"] as! Int
            var caption: Comment?
            if let c = i["caption"] as? NSDictionary {
                caption = instagramCommentFromDictionary(c, signedInUser: signedInUser)
            }
            let userLikes = i["user_has_liked"] as! Bool
            let likesDictionary = i["likes"] as! NSDictionary
            let likeCount = likesDictionary["count"] as! Int
            var location: Location?
            if let l = i["location"] as? NSDictionary {
                if let lat = l["latitude"] as? CLLocationDegrees {
                    let long = l["longitude"] as! CLLocationDegrees
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    var name: String?
                    if let n = l["name"] as? String {
                        name = n
                    }
                    location = Location(coordinate: coordinate, name: name)
                }
            }
            let type = i["type"] as! String
            var media: Media!
            let dictionary = i["\(type)s"] as! NSDictionary
            let standardResolutionImageDictionary = dictionary["standard_resolution"] as! NSDictionary
            let urlString = standardResolutionImageDictionary["url"] as! String
            let url = NSURL(string: urlString)
            if type == "image" {
                media = Media(type: .Image, url: url)
                let h = standardResolutionImageDictionary["height"] as! CGFloat
                let w = standardResolutionImageDictionary["width"] as! CGFloat
                let scale = h / w
                media.scale = scale
            } else {
                let imagesDictionary = i["images"] as! NSDictionary
                let standardResolutionVideoDictionary = imagesDictionary["standard_resolution"] as! NSDictionary
                let thumbnailUrlString = standardResolutionVideoDictionary["url"] as! String
                let thumbnailUrl = NSURL(string: thumbnailUrlString)
                media = Media(type: .Video, url: url)
                media.thumbnail = thumbnailUrl
                media.scale = 1
            }
            var tags: [String]?
            if let tagsArray = i["tags"] as? NSArray {
                var t = [String]()
                for tag in tagsArray {
                    let tg = tag as! String
                    t.append(tg)
                }
                tags = t
            }
            var photoTags: [PhotoTag]?
            if let uip = i["users_in_photo"] as? NSArray {
                var tags = [PhotoTag]()
                for tag in uip {
                    let t = tag as! NSDictionary
                    let positionDictionary = t["position"] as! NSDictionary
                    let x = positionDictionary["x"] as! CGFloat
                    let y = positionDictionary["y"] as! CGFloat
                    let userDictionary = t["user"] as! NSDictionary
                    let user = instagramUserFromDictionary(userDictionary)
                    let ta = PhotoTag(user: user, x: x, y: y)
                    tags.append(ta)
                }
                photoTags = tags
            }
            let link = i["link"] as! String
            let post = InstagramPost(id: id, from: from, date: date, signedInUser: signedInUser, media: media, userLikes: userLikes, likeCount: likeCount, commentCount: commentCount, caption: caption, location: location, tags: tags, photoTags: photoTags, link: link)
            posts.append(post)
        }
        return posts
    }
    
    class func instagramCommentFromDictionary(i: NSDictionary, signedInUser: SignedInUser) -> Comment {
        let id = i["id"] as! String
        let fromDictionary = i["from"] as! NSDictionary
        let from = instagramUserFromDictionary(fromDictionary)
        let timeInterval = (i["created_time"] as! NSString).floatValue
        let date = NSDate(timeIntervalSince1970: NSTimeInterval(timeInterval))
        let text = i["text"] as! String
        let comment = Comment(id: id, message: text, from: from, date: date, type: .Instagram, signedInUser: signedInUser)
        return comment
    }
    
    class func instagramUserFromSavedDictionary(dictionary: NSDictionary) -> SignedInUser {
        let id = dictionary["id"]! as! String
        let username = dictionary["username"]! as! String
        var name: String?
        if dictionary["name"] != nil {
            name = dictionary["name"] as? String
        }
        let profilePictureUrl = NSURL(string: dictionary["profilePictureUrl"]! as! String)
        let access_token = dictionary["access_token"] as! String
        let u = InstagramUser(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl)
        let key = Instagram["key"]!
        let secret = Instagram["secret"]!
        let client = OAuthSwiftClient(consumerKey: key, consumerSecret: secret, accessToken: access_token, accessTokenSecret: "")
        client.credential.oauth2 = true
        let user = SignedInUser(client: client, user: u, clientUser: u)
        return user
    }
    
    class func tumblrUserFromSavedDictionary(dictionary: NSDictionary) -> SignedInUser {
        let id = dictionary["id"]! as! String
        let profilePictureUrl = tumblrProfilePictureUrlFromId(id)
        let profilePictureLargeUrl = tumblrProfilePictureLargeUrlFromUrl(profilePictureUrl)
        let access_token = dictionary["access_token"] as! String
        let access_token_secret = dictionary["access_token_secret"] as! String
        let u = TumblrUser(id: id, name: id, username: nil, profilePictureUrl: profilePictureUrl)
        u.profilePictureLargeUrl = profilePictureLargeUrl
        let key = Tumblr["key"]!
        let secret = Tumblr["secret"]!
        let client = OAuthSwiftClient(consumerKey: key, consumerSecret: secret, accessToken: access_token, accessTokenSecret: access_token_secret)
        let user = SignedInUser(client: client, user: u, clientUser: u)
        return user
    }
    
    class func tumblrUserFromDictionary(i: NSDictionary, nameString: String) -> TumblrUser {
        let id = i[nameString] as! String
        let profilePictureUrl = tumblrProfilePictureUrlFromId(id)
        let profilePictureLargeUrl = tumblrProfilePictureLargeUrlFromUrl(profilePictureUrl)
        if nameString == "name" {
            if i["title"] != nil {
                let title = i["title"] as! String
                let description = i["description"] as! String
                var postCount: Int?
                if let pCount = i["posts"] as? Int {
                    postCount = pCount
                }
                var canAsk: Bool?
                if let cAsk = i["ask"] as? Bool {
                    canAsk = cAsk
                }
                var canAskAnon: Bool?
                if let anon = i["ask_anon"] as? Bool {
                    canAskAnon = anon
                }
                var askPageTitle: String?
                if let pTitle = i["ask_page_title"] as? String {
                    askPageTitle = pTitle
                }
                let user = TumblrUser(id: id, name: id, username: title, profilePictureUrl: profilePictureUrl, description: description, postCount: postCount, canAsk: canAsk, canAskAnon: canAskAnon, askPageTitle: askPageTitle)
                user.profilePictureLargeUrl = profilePictureLargeUrl
                return user
            }
        }
        let user = TumblrUser(id: id, name: id, username: nil, profilePictureUrl: profilePictureUrl)
        user.profilePictureLargeUrl = profilePictureLargeUrl
        return user
    }
    
    class func tumblrProfilePictureUrlFromId(id: String) -> NSURL {
        let profilePictureUrlString = "http://api.tumblr.com/v2/blog/\(id).tumblr.com/avatar/96"
        let profilePictureUrl = NSURL(string: profilePictureUrlString)!
        return profilePictureUrl
    }
    
    class func tumblrProfilePictureLargeUrlFromUrl(url: NSURL) -> NSURL {
        let string = url.absoluteString.stringByReplacingOccurrencesOfString("/avatar/96", withString: "/avatar/512")
        let profilePictureLargeUrl = NSURL(string: string)!
        return profilePictureLargeUrl
    }
    
    class func tumblrPostsFromArray(data: NSArray, signedInUser: SignedInUser) -> [TumblrPost] {
        var posts = [TumblrPost]()
        for item in data {
            var badPost = false
            var post: TumblrPost!
            let i = item as! NSDictionary
            let id = String(i["id"] as! Int)
            let user = tumblrUserFromDictionary(i, nameString: "blog_name")
            let dateString = i["date"] as! String
            let date = tumblrDateFromString(dateString)
            let reblogKey = i["reblog_key"] as! String
            let liked = i["liked"] as! Bool
            let likeCount = i["note_count"] as! Int
            let t = i["type"] as! String
            var tags: [String]?
            if let t = i["tags"] as? NSArray {
                var ts = [String]()
                for tag in t {
                    let tg = tag as! String
                    ts.append(tg)
                }
                tags = ts
            }
            var reblogUser: TumblrUser?
            if let n = i["reblogged_from_name"] as? String{
                var title: String?
                if let t = i["reblogged_from_name"] as? String {
                    title = t
                }
                let profilePictureUrl = Utility.tumblrProfilePictureUrlFromId(n)
                let profilePictureLargeUrl = Utility.tumblrProfilePictureLargeUrlFromUrl(profilePictureUrl)
                let rUser = TumblrUser(id: n, name: n, username: title, profilePictureUrl: profilePictureUrl)
                rUser.profilePictureLargeUrl = profilePictureLargeUrl
                reblogUser = rUser
            }
            if !badPost {
                switch t {
                case "text":
                    let title = i["title"] as! String
                    let body = i["body"] as! String
                    post = TumblrTextPost(id: id, from: user, date: date, signedInUser: signedInUser, postType: .Text, reblogKey: reblogKey, liked: liked, title: title, body: body, tags: tags, reblogUser: reblogUser)
                case "photo":
                    var caption: String?
                    if let c = i["caption"] as? String {
                        caption = c
                    }
                    let photosArray = i["photos"] as! NSArray
                    let photos = Utility.tumblrPhotosFromArray(photosArray)
                    post = TumblrImagePost(id: id, from: user, date: date, signedInUser: signedInUser, postType: .Image, reblogKey: reblogKey, liked: liked, mediaArray: photos, caption: caption, tags: tags, reblogUser: reblogUser)
                case "quote":
                    let text = i["text"] as! String
                    if let sourceTitle = i["source"] as? String {
                        if let sourceUrlString = i["source_url"] as? String {
                            let sourceUrl = NSURL(string: sourceUrlString)!
                            post = TumblrQuotePost(id: id, from: user, date: date, signedInUser: signedInUser, postType: .Quote, reblogKey: reblogKey, liked: liked, text: text, sourceUrl: sourceUrl, sourceTitle: sourceTitle, tags: tags, reblogUser: reblogUser)
                        } else {
                            badPost = true
                        }
                    } else {
                        badPost = true
                    }
                case "link":
                    let title = i["title"] as! String
                    var author: String?
                    if let a = i["author"] as? String {
                        author = a
                    }
                    let urlString = i["url"] as! String
                    if let url = NSURL(string: urlString) {
                        let publisher = i["publisher"] as! String
                        let description = i["description"] as! String
                        var media: [TumblrMedia]?
                        if let p = i["photos"] as? NSArray {
                            media = tumblrPhotosFromArray(p)
                        }
                        post = TumblrLinkPost(id: id, from: user, date: date, signedInUser: signedInUser, postType: .Link, reblogKey: reblogKey, liked: liked, title: title, author: author, url: url, publisher: publisher, photos: media, description: description, tags: tags, reblogUser: reblogUser)
                    } else {
                        badPost = true
                    }
                case "chat":
                    var title: String?
                    if let t = i["title"] as? String {
                        title = t
                    }
                    let dialogue = i["body"] as! String
                    post = TumblrTextPost(id: id, from: user, date: date, signedInUser: signedInUser, postType: .Text, reblogKey: reblogKey, liked: liked, title: title, body: dialogue, tags: tags, reblogUser: reblogUser)
                case "answer":
                    badPost = true
                    let question = i["question"] as! String
                    let answer = i["answer"] as! String
                    let askingName = i["asking_name"] as! String
                    post = TumblrAnswerPost(id: id, from: user, date: date, signedInUser: signedInUser, postType: .Link, reblogKey: reblogKey, liked: liked, question: question, answer: answer, askingName: askingName, tags: tags, reblogUser: reblogUser)
                default:
                    badPost = true
                }
                if !badPost {
                    post.likeCount = likeCount
                    posts.append(post)
                }
            }
        }
        return posts
    }
    
    class func tumblrDialogueFromArray(data: NSArray) -> [TumblrDialogue] {
        var dialogue = [TumblrDialogue]()
        for item in data {
            let i = item as! NSDictionary
            let name = i["name"] as! String
            let text = i["phrase"] as! String
            let dia = TumblrDialogue(name: name, text: text)
            dialogue.append(dia)
        }
        return dialogue
    }
    
    class func tumblrPhotosFromArray(data: NSArray) -> [TumblrMedia] {
        var photos = [TumblrMedia]()
        for item in data {
            let i = item as! NSDictionary
            var caption: String?
            if let c = i["caption"] as? String {
                caption = c
            }
            let altSizes = i["alt_sizes"] as! NSArray
            var url: NSURL!
            var currentSize: CGFloat = 0
            var currentHeight: CGFloat = 0
            var scale: CGFloat!
            for size in altSizes {
                let s = size as! NSDictionary
                let width = s["width"] as! CGFloat
                let height = s["height"] as! CGFloat
                if width <= w + 180 {
                    if width > currentSize {
                        currentSize = width
                        currentHeight = height
                        let urlString = s["url"] as! String
                        url = NSURL(string: urlString)
                        scale = currentHeight / currentSize
                    }
                }
            }
            let media = TumblrMedia(type: .Image, url: url, caption: caption)
            media.scale = scale
            photos.append(media)
        }
        return photos
    }
    
    class func tumblrDateFromString(string: String) -> NSDate {
        let date = dateFromStringAndFormat(string, format: "yyyy-MM-dd HH:mm:ssZZZZZ")
        return date
    }
    
    class func soundCloudUserFromSavedDictionary(dictionary: NSDictionary) -> SignedInUser {
        let id = dictionary["id"]! as! String
        let profilePictureUrlString = dictionary["profilePictureUrl"] as! String
        let profilePictureUrl = NSURL(string: profilePictureUrlString)!
        let profilePictureLargeUrl = soundCloudProfilePictureUrlLargeFromUrl(profilePictureUrl)
        let access_token = dictionary["access_token"] as! String
        let name = dictionary["name"] as? String
        let username = dictionary["username"] as! String
        let u = SoundCloudUser(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, description: nil, followersCount: nil, followingCount: nil, favouritesCount: nil, trackCount: nil, playlistCount: nil)
        u.profilePictureLargeUrl = profilePictureLargeUrl
        let key = SoundCloud["key"]!
        let secret = SoundCloud["secret"]!
        let client = OAuthSwiftClient(consumerKey: key, consumerSecret: secret, accessToken: access_token, accessTokenSecret: "")
        client.credential.oauth2 = true
        let user = SignedInUser(client: client, user: u, clientUser: u)
        return user
    }
    
    class func soundCloudUserFromDictionary(json: NSDictionary) -> SoundCloudUser {
        let id = String(json["id"] as! Int)
        let name = json["full_name"] as? String
        let username = json["username"] as! String
        let profilePictureUrlString = json["avatar_url"] as! String
        let profilePictureUrl = NSURL(string: profilePictureUrlString)!
        let profilePictureLargeUrl = soundCloudProfilePictureUrlLargeFromUrl(profilePictureUrl)
        let description = json["description"] as? String
        let followersCount = json["followers_count"] as? Int
        let followingCount = json["followings_count"] as? Int
        let favouritesCount = json["public_favorites_count"] as? Int
        let trackCount = json["track_count"] as? Int
        let playlistCount = json["playlist_count"] as? Int
        let user = SoundCloudUser(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, description: description, followersCount: followersCount, followingCount: followingCount, favouritesCount: favouritesCount, trackCount: trackCount, playlistCount: playlistCount)
        user.profilePictureLargeUrl = profilePictureLargeUrl
        return user
    }
    
    class func soundCloudPostsFromArray(array: NSArray, signedInUser: SignedInUser) -> [SoundCloudPost] {
        var posts = [SoundCloudPost]()
        for item in array {
            let i = item as! NSDictionary
            if i["streamable"] != nil {
                if i["streamable"] as? NSNull != nil {} else {
                    if i["streamable"] as! Bool {
                        if let artworkUrlString = i["artwork_url"] as? String {
                            let artworkUrl = NSURL(string: artworkUrlString.stringByReplacingOccurrencesOfString("large", withString: "t500x500"))
                            let artwork = Media(type: .Image, url: artworkUrl)
                            artwork.scale = 1
                            let id = String(i["id"] as! Int)
                            let userDictionary = i["user"] as! NSDictionary
                            let user = soundCloudUserFromDictionary(userDictionary)
                            let dateString = i["created_at"] as! String
                            let date = soundCloudDateFromString(dateString)
                            let title = i["title"] as! String
                            let client_id = SoundCloud["key"]!
                            let audioUrlString = (i["stream_url"] as! String) + "?client_id=\(client_id)"
                            let audioUrl = NSURL(string: audioUrlString)
                            let audio = SoundCloudAudio(type: .Audio, url: audioUrl)
                            audio.duration = i["duration"] as! Int
                            let description = i["description"] as? String
                            let license = i["license"] as! String
                            let canComment = i["commentable"] as! Bool
                            let playsCount = i["playback_count"] as? Int
                            let commentCount = i["comment_count"] as? Int
                            let likeCount = i["likes_count"] as? Int
                            let post = SoundCloudPost(id: id, from: user, date: date, signedInUser: signedInUser, title: title, audio: audio, description: description, license: license, canComment: canComment, playsCount: playsCount, commentCount: commentCount, likeCount: likeCount, artwork: artwork)
                            posts.append(post)
                        }
                    }
                }
            }
        }
        return posts
    }
    
    class func soundCloudPlaylistsFromArray(array: NSArray, signedInUser: SignedInUser) -> [SoundCloudPlaylist] {
        var playlists = [SoundCloudPlaylist]()
        for item in array {
            let i = item as! NSDictionary
            if i["streamable"] != nil {
                if i["streamable"] as? NSNull != nil {} else {
                    if i["streamable"] as! Bool {
                        let id = String(i["id"])
                        let title = i["title"] as! String
                        let dateString = i["created_at"] as! String
                        let date = soundCloudDateFromString(dateString)
                        let description = i["description"] as? String
                        let trackCount = i["track_count"] as! Int
                        let tracksArray = i["tracks"] as! NSArray
                        let tracks = soundCloudPostsFromArray(tracksArray, signedInUser: signedInUser)
                        let userDictionary = i["user"] as! NSDictionary
                        let user = soundCloudUserFromDictionary(userDictionary)
                        let playlist = SoundCloudPlaylist(title: title, description: description, trackCount: trackCount, tracks: tracks, id: id, from: user, date: date, signedInUser: signedInUser)
                        playlists.append(playlist)
                    }
                }
            }
        }
        return playlists
    }
    
    class func soundCloudDateFromString(string: String) -> NSDate {
        let format = "yyyy/MM/dd HH:mm:ss ZZZ"
        return dateFromStringAndFormat(string, format: format)
    }
    
    class func soundCloudProfilePictureUrlLargeFromUrl(url: NSURL) -> NSURL {
        var string = url.relativeString!
        string = string.stringByReplacingOccurrencesOfString("large", withString: "t500x500")
        return NSURL(string: string)!
    }
    
    class func soundCloudCommentsFromArray(array: NSArray, signedInUser: SignedInUser) -> [Comment] {
        var comments = [Comment]()
        for item in array {
            let i = item as! NSDictionary
            let id = String(i["id"])
            let userDictionary = i["user"] as! NSDictionary
            let user = soundCloudUserFromDictionary(userDictionary)
            let text = i["body"] as! String
            let dateString = i["created_at"] as! String
            let date = soundCloudDateFromString(dateString)
            let comment = Comment(id: id, message: text, from: user, date: date, type: .SoundCloud, signedInUser: signedInUser)
            comments.append(comment)
        }
        return comments
    }
    
    class func tableViewCellFromPost(post: Post, tableView: UITableView, indexPath: NSIndexPath, signedInUser: SignedInUser) -> PostTableViewCell? {
        var cell: PostTableViewCell!
        switch post.type {
        case .Facebook:
            let p = post as! FacebookPost
            if p.embeddedPost != nil {
                cell = tableView.dequeueReusableCellWithIdentifier("FacebookEmbeddedPostCell", forIndexPath: indexPath) as! FacebookEmbeddedPostTableViewCell
            } else {
                if post.media == nil {
                    cell = tableView.dequeueReusableCellWithIdentifier("FacebookCell", forIndexPath: indexPath) as! FacebookTableViewCell
                } else {
                    if post.media?.type == .Image {
                        cell = tableView.dequeueReusableCellWithIdentifier("FacebookImageCell", forIndexPath: indexPath) as! FacebookImageTableViewCell
                    } else if post.media?.type == .Video {
                        cell = tableView.dequeueReusableCellWithIdentifier("FacebookVideoCell", forIndexPath: indexPath) as! FacebookImageTableViewCell
                    } else {
                        cell = tableView.dequeueReusableCellWithIdentifier("FacebookLinkCell", forIndexPath: indexPath) as! FacebookLinkTableViewCell
                    }
                }
            }
        case .Twitter:
            let p = post as! TwitterPost
            if post.media == nil {
                if p.quotedStatus == nil {
                    cell = tableView.dequeueReusableCellWithIdentifier("TwitterCell", forIndexPath: indexPath) as! TwitterTableViewCell
                } else {
                    cell = tableView.dequeueReusableCellWithIdentifier("TwitterQuoteCell", forIndexPath: indexPath) as! TwitterQuoteTableViewCell
                }
            } else {
                if post.media?.type == .Image {
                    cell = tableView.dequeueReusableCellWithIdentifier("TwitterImageCell", forIndexPath: indexPath) as! TwitterImageTableViewCell
                } else {
                    cell = tableView.dequeueReusableCellWithIdentifier("TwitterVideoCell", forIndexPath: indexPath) as! TwitterVideoTableViewCell
                }
            }
        case .Instagram:
            if post.media!.type == MediaType.Image {
                cell = tableView.dequeueReusableCellWithIdentifier("InstagramImageCell", forIndexPath: indexPath) as! InstagramTableViewCell
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier("InstagramVideoCell", forIndexPath: indexPath) as! InstagramTableViewCell
            }
        case .Tumblr:
            let p = post as! TumblrPost
            switch p.postType! {
            case .Text:
                cell = tableView.dequeueReusableCellWithIdentifier("TumblrTextCell", forIndexPath: indexPath) as! TumblrTextTableViewCell
            case .Image:
                cell = tableView.dequeueReusableCellWithIdentifier("TumblrImageCell", forIndexPath: indexPath) as! TumblrImageTableViewCell
            case .Link:
                cell = tableView.dequeueReusableCellWithIdentifier("TumblrLinkCell", forIndexPath: indexPath) as! TumblrLinkTableViewCell
            case .Quote:
                cell = tableView.dequeueReusableCellWithIdentifier("TumblrQuoteCell", forIndexPath: indexPath) as! TumblrQuoteTableViewCell
            default:
                print("okidoki")
            }
        case .SoundCloud:
            if let _ = post as? Comment {
                cell = tableView.dequeueReusableCellWithIdentifier("SoundCloudCommentCell", forIndexPath: indexPath) as! SoundCloudCommentTableViewCell
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier("SoundCloudTrackCell", forIndexPath: indexPath) as! SoundCloudTrackTableViewCell
            }
        default:
            return nil
        }
        cell.setPost(post, signedInUser: signedInUser)
        if post.media == nil {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: w, bottom: 0, right: 0)
            if let facebookPost = post as? FacebookPost {
                if facebookPost.media!.type == .Link {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0)
                }
            }
        }
        return cell
    }
    
    class func formatNumber(int: Int) -> String {
        var string: String!
        let i = Float(int)
        if i >= 1000 && i < 100000 {
            let formatted = i / 1000
            string = String(format: "%.1f", formatted) + "k"
        } else if i >= 100000 && i < 1000000 {
            let formatted = int / 1000
            string = "\(formatted)k"
        } else if i >= 1000000 {
            let formatted = i / 1000000
            var format = "%.2f"
            if i >= 10000000 {
                format = "%.1f"
            }
            string = String(format: format, formatted) + "M"
        } else {
            string = "\(int)"
        }
        string = string.stringByReplacingOccurrencesOfString(".0k", withString: "k")
        string = string.stringByReplacingOccurrencesOfString(".0M", withString: "M")
        return string
    }
    
    class func registerCells(tableView: UITableView) {
        tableView.registerNib(UINib(nibName: "FacebookTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "FacebookCell")
        tableView.registerNib(UINib(nibName: "FacebookImageTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "FacebookImageCell")
        tableView.registerNib(UINib(nibName: "FacebookVideoTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "FacebookVideoCell")
        tableView.registerNib(UINib(nibName: "FacebookLinkTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "FacebookLinkCell")
        tableView.registerNib(UINib(nibName: "FacebookCommentTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "FacebookCommentCell")
        tableView.registerNib(UINib(nibName: "FacebookImageCommentTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "FacebookImageCommentCell")
        tableView.registerNib(UINib(nibName: "FacebookEmbeddedPostTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "FacebookEmbeddedPostCell")
        tableView.registerNib(UINib(nibName: "FacebookActionsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "FacebookActionsCell")
        tableView.registerNib(UINib(nibName: "TwitterTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TwitterCell")
        tableView.registerNib(UINib(nibName: "TwitterImageTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TwitterImageCell")
        tableView.registerNib(UINib(nibName: "TwitterVideoTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TwitterVideoCell")
        tableView.registerNib(UINib(nibName: "TwitterQuoteTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TwitterQuoteCell")
        tableView.registerNib(UINib(nibName: "TwitterActionsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TwitterActionsCell")
        tableView.registerNib(UINib(nibName: "InstagramImageTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "InstagramImageCell")
        tableView.registerNib(UINib(nibName: "InstagramVideoTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "InstagramVideoCell")
        tableView.registerNib(UINib(nibName: "InstagramCommentTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "InstagramCommentCell")
        tableView.registerNib(UINib(nibName: "InstagramActionsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "InstagramActionsCell")
        tableView.registerNib(UINib(nibName: "InstagramCountsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "InstagramCountsCell")
        tableView.registerNib(UINib(nibName: "InstagramPopularTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "InstagramPopularCell")
        tableView.registerNib(UINib(nibName: "TumblrTextTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TumblrTextCell")
        tableView.registerNib(UINib(nibName: "TumblrImageTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TumblrImageCell")
        tableView.registerNib(UINib(nibName: "TumblrLinkTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TumblrLinkCell")
        tableView.registerNib(UINib(nibName: "TumblrQuoteTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TumblrQuoteCell")
        tableView.registerNib(UINib(nibName: "TumblrActionsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TumblrActionsCell")
        tableView.registerNib(UINib(nibName: "SoundCloudTrackTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "SoundCloudTrackCell")
        tableView.registerNib(UINib(nibName: "SoundCloudCommentTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "SoundCloudCommentCell")
        tableView.registerNib(UINib(nibName: "UserTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "UserCell")
        tableView.registerNib(UINib(nibName: "PostUserTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "PostUserCell")
        tableView.registerNib(UINib(nibName: "LoadingTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "LoadingCell")
        tableView.registerNib(UINib(nibName: "ViewAllTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "ViewAllCell")
        tableView.registerNib(UINib(nibName: "ImageVideoTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "ImageVideoCell")
        tableView.registerNib(UINib(nibName: "TallImageVideoTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TallImageVideoCell")
        tableView.registerNib(UINib(nibName: "TextTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TextCell")
        tableView.registerNib(UINib(nibName: "TallTextTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TallTextCell")
        tableView.registerNib(UINib(nibName: "RetweetedTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "RetweetedCell")
        tableView.registerNib(UINib(nibName: "DateTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "DateCell")
        tableView.registerNib(UINib(nibName: "TallDateTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TallDateCell")
        tableView.registerNib(UINib(nibName: "CountsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "CountsCell")
        tableView.registerNib(UINib(nibName: "MapTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "MapCell")
        tableView.registerNib(UINib(nibName: "TallMapTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TallMapCell")
        tableView.registerNib(UINib(nibName: "ComposeTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "ComposeCell")
        tableView.registerNib(UINib(nibName: "AudioTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "AudioCell")
        tableView.registerNib(UINib(nibName: "AddAccountTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "AddAccountCell")
        tableView.registerNib(UINib(nibName: "AccountTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "AccountCell")
    }
    
    class func activityIndicator(view: UIView?) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = .Gray
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        if view != nil {
            view!.insertSubview(activityIndicator, atIndex: 0)
            view!.bringSubviewToFront(activityIndicator)
            activityIndicator.center = view!.center
        }
        return activityIndicator
    }
    
    class func saveDictionary(dictionary: NSDictionary, s: String) {
        let d = NSMutableDictionary(dictionary: dictionary)
        d["primary"] = "true"
        /*if NSUserDefaults.standardUserDefaults().arrayForKey(s) == nil {
            d["primary"] = "true"
            let array = NSArray(object: d)
            NSUserDefaults.standardUserDefaults().setObject(array, forKey: s)
        } else {
            let a = NSMutableArray(array: NSUserDefaults.standardUserDefaults().arrayForKey(s)!)
            var index: Int?
            var foundOther = false
            for (ind, item) in a.enumerate() {
                let i = item as! NSDictionary
                if i["id"] as! String == d["id"] as! String {
                    a.removeObjectAtIndex(ind)
                    index = ind
                    if d["primary"] == nil {
                        if i["primary"] as! String == "true" {
                            foundOther = true
                        }
                    } else {
                        if d["primary"]! as! String == "true" {
                            foundOther = true
                        } else {
                            foundOther = false
                        }
                    }
                }
            }
            if foundOther || a.count == 0 {
                d["primary"] = "true"
            } else {
                d["primary"] = "false"
            }
            if index != nil {
                a.insertObject(d, atIndex: index!)
            } else {
                a.addObject(d)
            }
            let array: NSArray = NSArray(array: a)
            NSUserDefaults.standardUserDefaults().setObject(array, forKey: s)
        }*/
        NSUserDefaults.standardUserDefaults().setObject([d], forKey: s)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func handleError(error: NSError?, message: String) {
        let invalidErrorDescriptions = ["The request timed out.", "The Internet connection appears to be offline."]
        if error != nil {
            print(error!.localizedDescription)
            if invalidErrorDescriptions.contains(error!.localizedDescription) {
                return
            }
        }
        let notification = CWStatusBarNotification()
        notification.notificationAnimationInStyle = .Top
        notification.notificationAnimationOutStyle = .Top
        notification.notificationLabelBackgroundColor = tintColour
        notification.displayNotificationWithMessage(message, forDuration: 1)
    }
    
    class func replyComment(post: Post, delegate: CellDelegate) {
        switch post.type {
        case .Facebook:
            let url = Facebook["base_url"]! + "\(post.id)/comments"
            let futurePost = FuturePost(signedInUser: post.signedInUser, type: .Comment, destinationUrl: url, maxImages: 1, location: true, inReplyToPost: post)
            let composeViewController = ComposeTableViewController(futurePosts: [futurePost], postCell: post)
            delegate.pushViewController(composeViewController)
        case .Twitter:
            let url = Twitter["base_url"]! + "statuses/update.json"
            let futurePost = FuturePost(signedInUser: post.signedInUser, type: .Comment, destinationUrl: url, maxImages: 4, location: true, inReplyToPost: post)
            let composeViewController = ComposeTableViewController(futurePosts: [futurePost], postCell: post)
            delegate.pushViewController(composeViewController)
        default:
            print("okidoki")
        }
    }
    
    class func retweet(post: Post, delegate: CellDelegate) {
        if post.type == .Twitter {
            let url = Twitter["base_url"]! + "statuses/update.json"
            let futurePost = FuturePost(signedInUser: post.signedInUser, type: .Post, destinationUrl: url, maxImages: 4, location: true, inReplyToPost: nil)
            futurePost.retweetUrl = "https://twitter.com/\(post.from!.username!)/status/\(post.id)"
            let composeViewController = ComposeTableViewController(futurePosts: [futurePost], postCell: post)
            composeViewController.postCell = post
            delegate.pushViewController(composeViewController)
        } else if post.type == .Tumblr {
            let url = Tumblr["base_url"]! + "blog/\(post.signedInUser.clientUser.name!).tumblr.com/post/reblog"
            let futurePost = FuturePost(signedInUser: post.signedInUser, type: .Comment, destinationUrl: url, maxImages: 0, location: false, inReplyToPost: post)
            let composeViewController = ComposeTableViewController(futurePosts: [futurePost], postCell: post)
            composeViewController.postCell = post
            delegate.pushViewController(composeViewController)
        }
    }
    
    class func getQueryStringParameter(url: String, param: String) -> String? {
        let url = NSURLComponents(string: url)!
        return url.queryItems!.filter({ (item) in item.name == param }).first!.value!
    }
    
    class func estimatedCellHeightForPost(post: Post, tableView: UITableView) -> CGFloat {
        if post.estimatedHeight == nil {
            let cell = tableViewCellFromPost(post, tableView: tableView, indexPath: NSIndexPath(), signedInUser: post.signedInUser)
            let h = cell!.frame.height
            post.estimatedHeight = h
            cell!.post.estimatedHeight = h
            return h
        } else {
            return post.estimatedHeight!
        }
        /*var h: CGFloat = 36
        let wi = w - 80 as CGFloat
        let atts = [NSFontAttributeName : UIFont.systemFontOfSize(16)]
        let ops = NSStringDrawingOptions.UsesFontLeading
        switch post.type {
        case .Facebook:
            let p = post as! FacebookPost
            if p.story != nil {
                let t = p.story! as NSString
                h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
            }
            if post.media != nil {
                switch post.media!.type! {
                case .Image:
                    let scale = post.media!.scale!
                    h += w * scale
                case .Video:
                    let scale = post.media!.scale!
                    h += w * scale
                case .Link:
                    if p.name != nil {
                        let t = p.name! as NSString
                        h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
                    }
                    if p.description != nil {
                        let t = p.description! as NSString
                        h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
                    }
                    if p.caption != nil {
                        let t = p.caption! as NSString
                        h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
                    }
                default:
                    print("okidoki")
                }
                if p.message != nil {
                    let t = p.message! as NSString
                    h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
                }
            }
        case .Twitter:
            var p = post as! TwitterPost
            if p.quotedStatus != nil {
                h += p.text.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height + 8
                p = p.quotedStatus!
            }
            if p.mediaArray != nil {
                if !p.mediaArray!.isEmpty {
                    switch p.mediaArray!.count {
                    case 1:
                        let m = p.mediaArray![0]
                        let scale = m.scale! > 9 / 16 ? 9 / 16 : m.scale!
                        h += w * scale
                    case 2:
                        h += w / 2
                    case 3:
                        h += w / 3
                    case 4:
                        h += w
                    default:
                        print("okidoki")
                    }
                    h += 8
                }
            }
            let t = p.text as NSString
            h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
        case .Instagram:
            let p = post as! InstagramPost
            if p.caption != nil {
                let t = p.caption!.message as String
                h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
                h += 12
            }
            if h < 72 {
                h = 72
            }
            h += w * p.media!.scale!
            print(h)
        case .Tumblr:
            let p = post as! TumblrPost
            if p.tags != nil {
                if !p.tags!.isEmpty {
                    var tg = ""
                    for tag in p.tags! {
                        var t = tag.capitalizedString.stringByReplacingOccurrencesOfString(" ", withString: "")
                        t = t.stringByReplacingOccurrencesOfString(".", withString: "")
                        tg += "#" + t + " "
                    }
                    h += tg.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
                    h += 8
                }
            }
            if p.reblogUser != nil {
                h += 32
            }
            switch p.postType! {
            case .Text:
                let po = p as! TumblrTextPost
                let t = po.title! as NSString
                let b = po.body as NSString
                let att = [NSFontAttributeName : UIFont.systemFontOfSize(22)]
                h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: att, context: nil).height
                h += b.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
            case .Image:
                let po = p as! TumblrImagePost
                let t = po.caption as NSString
                h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
                h += constraintHeightForImageViewFromMediaArray(po.mediaArray, max: true)
            case .Link:
                let po = p as! TumblrLinkPost
                let t = po.description as NSString
                h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
                if po.photos != nil {
                    h += constraintHeightForImageViewFromMediaArray(po.photos!, max: true)
                }
            case .Quote:
                let po = post as! TumblrQuotePost
                let t = po.text as NSString
                let s = po.sourceTitle as NSString
                let att = [NSFontAttributeName : UIFont(name: "Georgia", size: 22)!]
                h += t.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: att, context: nil).height
                h += s.boundingRectWithSize(CGSizeMake(wi, CGFloat.max), options: ops, attributes: atts, context: nil).height
            default:
                print("okidoki")
            }
            h += 16
        case .SoundCloud:
            h = 100
        default:
            print("okidoki")
        }
        post.estimatedHeight = h
        return h*/
    }
    
    class func constraintHeightForImageViewFromMediaArray(array: [Media], max: Bool) -> CGFloat {
        var wi: CGFloat!
        if max {
            wi = w/* - 72*/
        } else {
            wi = w - 24
        }
        switch array.count {
        case 1:
            var scale: CGFloat = 9 / 16
            if let a = array[0].scale {
                scale = a
            }
            if max {
                if scale > 9 / 16 {
                    scale = 9 / 16
                }
            }
            return wi * scale
        case 2:
            return wi / 2
        case 3:
            return wi / 3
        case 4:
            return wi
        case 5:
            return wi * 0.83125
        case 6:
            return wi * 0.6625
        case 7:
            return wi * 1.3375
        case 8:
            return wi * 1.16875
        case 9:
            return wi
        case 10:
            return wi * 1.675
        default:
            print("okidoki")
        }
        return 0
    }
    
    class func dateFromStringAndFormat(string: String, format: String) -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        let date = dateFormatter.dateFromString(string)!
        return date
    }
    
    class func showImage(image: UIImage, view: UIView, viewController: UIViewController) {
        let imageInfo = JTSMediaInfo()
        imageInfo.image = image
        imageInfo.referenceRect = view.bounds
        imageInfo.referenceView = view
        let imageViewController = JTSImageViewController(imageInfo: imageInfo, mode: .Image, backgroundStyle: .Blurred)
        imageViewController.showFromViewController(viewController, transition: .FromOriginalPosition, completion: nil)
    }
    
    class func showVideo(url: NSURL, viewController: UIViewController) {
        let videoViewController = VideoViewController(url: url)
        videoViewController.modalTransitionStyle = .CoverVertical
        videoViewController.modalPresentationStyle = .OverFullScreen
        videoViewController.navigationItem.title = "Video"
        viewController.navigationController!.pushViewController(videoViewController, animated: true)
    }
    
    class func findUsers() {
        currentSignedInUsers = [SignedInUser]()
        primaryCurrentSignedInUsers = [SignedInUser]()
        for service in services {
            if NSUserDefaults.standardUserDefaults().arrayForKey(service) != nil {
                let array = NSUserDefaults.standardUserDefaults().arrayForKey(service)!
                for dictionary in array {
                    var u: SignedInUser!
                    let d = dictionary as! NSDictionary
                    switch service {
                    case "Facebook":
                        u = Utility.facebookUserFromSavedDictionary(d)
                    case "Twitter":
                        u = Utility.twitterUserFromSavedDictionary(d)
                    case "Instagram":
                        u = Utility.instagramUserFromSavedDictionary(d)
                    case "Tumblr":
                        u = Utility.tumblrUserFromSavedDictionary(d)
                    case "SoundCloud":
                        u = Utility.soundCloudUserFromSavedDictionary(d)
                    default:
                        print("okidoki")
                    }
                    let primary = d["primary"] as! String
                    if primary == "true" {
                        u.primary = true
                        primaryCurrentSignedInUsers.append(u)
                    } else {
                        u.primary = false
                    }
                   currentSignedInUsers.append(u)
                }
            }
        }
    }
    
    class func saveSignedInUser(user: SignedInUser) {
        let s = user.clientUser.type.rawValue
        let u = user.clientUser
        var dictionary = [
            "id" : u.id,
            "profilePictureUrl" : u.profilePictureUrl!.absoluteString,
            "access_token" : user.client.credential.oauth_token,
            "access_token_secret" : user.client.credential.oauth_token_secret,
        ]
        if user.primary != nil {
            if user.primary! {
                dictionary["primary"] = "true"
            }
        }
        if u.name != nil {
            dictionary["name"] = u.name!
        }
        if u.username != nil {
            dictionary["username"] = u.username!
        }
        if let user = u as? TwitterUser {
            if user.verified! {
                dictionary["verified"] = "true"
            } else {
                dictionary["verified"] = "false"
            }
        }
        saveDictionary(dictionary, s: s)
    }
    
    class func getUrlsForHomeTableViewController(inout urls: [String], inout params: [Dictionary<String, AnyObject>]) {
        for u in currentSignedInUsers {
            switch u.clientUser.type {
            case .Facebook:
                let url = Facebook["base_url"]! + "me/likes"
                urls.append(url)
                let paramsString = FacebookPostParams["fields"]!
                params.append(["fields" : "posts.limit(3){\(paramsString)}", "limit" : "18"])
            case .Twitter:
                let url = Twitter["base_url"]! + "statuses/home_timeline.json"
                urls.append(url)
                params.append(["count" : "100", "include_entities" : "1", "exclude_replies" : "1", "user_id" : u.user.id])
            case .Instagram:
                let url = Instagram["base_url"]! + "users/self/feed"
                urls.append(url)
                params.append(["count" : "100"])
            case .Tumblr:
                let url = Tumblr["base_url"]! + "user/dashboard"
                urls.append(url)
                params.append(["filter" : "text", "reblog_info" : "true", "notes_info" : "true"])
            default:
                print("okidoki")
            }
        }
    }
    
    class func getUrlsForNotificationsTableViewController(inout urls: [String], inout params: [Dictionary<String, AnyObject>], inout signedInUsers: [SignedInUser]) {
        for u in currentSignedInUsers {
            switch u.clientUser.type {
            case .Facebook:
                let url = Facebook["base_url"]! + u.user.id + "/notifications"
                urls.append(url)
                params.append(["fields":"id,from,title,created_time,object"])
                signedInUsers.append(u)
            case .Twitter:
                let url = Twitter["base_url"]! + "statuses/mentions_timeline.json"
                urls.append(url)
                params.append(["count" : "100", "include_entities" : "1", "exclude_replies" : "1", "user_id" : u.user.id])
                signedInUsers.append(u)
            default:
                print("okidoki")
            }
        }
    }
    
    class func getUrlForProfileTableViewController(user: SignedInUser, inout urls: [String], inout params: [Dictionary<String, AnyObject>]) {
        switch user.user.type {
        case .Facebook:
            if let _ = user.user as? FacebookPage {
                urls.append(Facebook["base_url"]! + user.user.id + "/posts")
            } else {
                urls.append(Facebook["base_url"]! + user.user.id + "/feed")
            }
            params.append(FacebookPostParams)
        case .Twitter:
            urls.append(Twitter["base_url"]! + "statuses/user_timeline.json")
            params.append(["count" : "200", "include_entities" : "1", "exclude_replies" : "1", "user_id" : user.user.id])
        case .Instagram:
            urls.append(Instagram["base_url"]! + "users/" + user.user.id + "/media/recent")
            params.append(["count" : "200"])
        case .Tumblr:
            urls.append(Tumblr["base_url"]! + "blog/\(user.user.id!).tumblr.com/posts")
            params.append(["filter" : "text", "limit" : "20", "notes_info" : "true"])
        case .SoundCloud:
            urls.append(SoundCloud["base_url"]! + "users/\(user.user.id)/tracks")
            params.append(Dictionary<String, AnyObject>())
        default:
            print("okidoki")
        }
    }
    
    class func getStringForNibFromMediaArrayCount(count: Int) -> String {
        if count == 1 {
            return "OneImageView"
        } else if count == 2 {
            return"TwoImageView"
        } else if count == 3 {
            return "ThreeImageView"
        } else if count == 4 {
            return "FourImageView"
        } else if count == 5 {
            return "FiveImageView"
        } else if count == 6 {
            return "SixImageView"
        } else if count == 7 {
            return "SevenImageView"
        } else if count == 8 {
            return "EightImageView"
        } else if count == 9 {
            return "NineImageView"
        } else {
            return "TenImageView"
        }
    }
    
    class func backButtonForTarget(target: AnyObject) -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage(named: "Back 24px"), style: .Plain, target: target, action: "back")
    }
    
    class func like(post: Post, button: UIButton?, cell: UITableViewCell, callback: () -> Void) {
        var url: String!
        var params = ["":""]
        switch post.type {
        case .Facebook:
            url = Facebook["base_url"]! + post.id + "/likes"
        case .Twitter:
            if !post.userLikes! {
                url = Twitter["base_url"]! + "favorites/create.json"
            } else {
                url = Twitter["base_url"]! + "favorites/destroy.json"
            }
            params = ["id" : post.id]
        case .Instagram:
            url = Instagram["base_url"]! + "media/\(post.id)/likes"
        case .Tumblr:
            if post.userLikes! {
                url = Tumblr["base_url"]! + "user/unlike"
            } else {
                url = Tumblr["base_url"]! + "user/like"
            }
            let p = post as! TumblrPost
            params = ["id" : post.id, "reblog_key" : p.reblogKey]
        default: print("okidoki")
        }
        if !post.userLikes! {
            if button != nil {
                button!.selected = true
            }
            post.userLikes = true
            post.likeCount!++
            post.signedInUser.client.post(url, parameters: params, success: {
                (data, response) -> Void in
                callback()
            }, failure: {
                (error) -> Void in
                self.handleError(error, message: "Error Liking Post")
            })
        } else {
            if button != nil {
                button!.selected = false
            }
            post.userLikes = false
            post.likeCount!--
            post.signedInUser.client.delete(url, parameters: params, success: {
                (data, response) -> Void in
                callback()
            }, failure: {
                (error) -> Void in
                self.handleError(error, message: "Error Disliking Post")
            })
        }
    }
    
    class func setMapLocation(location: Location, map: MKMapView) {
        map.removeAnnotations(map.annotations)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(location.coordinate, span)
        map.setRegion(region, animated: false)
        let annotation = MKPointAnnotation()
        if location.name != nil {
            annotation.title = location.name!
        }
        annotation.coordinate = location.coordinate
        map.addAnnotation(annotation)
        map.selectAnnotation(annotation, animated: true)
    }
    
    class func getPostsFromUrls(urls: [String], params: [Dictionary<String, AnyObject>], signedInUsers: [SignedInUser], callback: (posts: [Post]?) -> Void, title: String, subcallback: ((posts: [Post], index: Int) -> Void)?) {
        var posts = [Post]()
        var count = urls.count
        var numberDone = 0
        for (index, url) in urls.enumerate() {
            var p = [Post]()
            signedInUsers[index].client.get(url, parameters: params[index], success: {
                (data, response) -> Void in
                switch signedInUsers[index].clientUser.type {
                case .Facebook:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let data = json["data"] as! NSArray
                    var s = title
                    if title.hasSuffix("Videos") {
                        s = "video"
                    } else if title.hasSuffix("Photos") {
                        s = "photo"
                    }
                    p = Utility.facebookPostsFromData(data, type: s, signedInUser: signedInUsers[index])
                case .Twitter:
                    var json: NSArray!
                    if !url.hasSuffix("search/tweets.json") {
                        json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSArray
                    } else {
                        let j = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                        json = j["statuses"] as! NSArray
                    }
                    p = Utility.twitterPostsFromArray(json, signedInUser: signedInUsers[index])
                case .Instagram:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSDictionary
                    let data = json["data"] as! NSArray
                    p = Utility.instagramPostsFromArray(data, signedInUser: signedInUsers[index])
                case .Tumblr:
                    if let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as? NSDictionary {
                        if let response = json["response"] as? NSDictionary {
                            if let posts = response["liked_posts"] as? NSArray {
                                p = Utility.tumblrPostsFromArray(posts, signedInUser: signedInUsers[index])
                            } else {
                                let posts = response["posts"] as! NSArray
                                p = Utility.tumblrPostsFromArray(posts, signedInUser: signedInUsers[index])
                            }
                        } else if let response = json["response"] as? NSArray {
                            p = Utility.tumblrPostsFromArray(response, signedInUser: signedInUsers[index])
                        }
                    }
                case .SoundCloud:
                    let json = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)) as! NSArray
                    p = Utility.soundCloudPostsFromArray(json, signedInUser: signedInUsers[index])
                default:
                    print("okidoki", terminator: "")
                }
                numberDone++
                var po = [Post]()
                for post in p {
                    var add = true
                    for po in posts {
                        let array = NSUserDefaults.standardUserDefaults().arrayForKey("Blocked\(po.type.rawValue)")
                        if array != nil {
                            let a = array as! [String]
                            if a.contains(post.from!.id) {
                                add = false
                            }
                        }
                        if po.type == post.type {
                            if po.id == post.id {
                                add = false
                            }
                        }
                    }
                    if add {
                        po.append(post)
                        posts.append(post)
                    }
                }
                if subcallback != nil {
                    subcallback!(posts: po, index: index)
                }
                if numberDone == count {
                    callback(posts: posts)
                }
            }, failure: {
                (error) -> Void in
                Utility.handleError(error, message: "Error Getting \(signedInUsers[index].clientUser.type.rawValue) Posts")
                if subcallback != nil {
                    subcallback!(posts: [Post](), index: index)
                }
                count--
                if numberDone == count {
                    callback(posts: posts)
                }
            })
        }
    }
    
    class func getUrlsForListGroupedTableViewController(inout urls: [String], inout params: [Dictionary<String, AnyObject>], user: User) {
        urls.append(Twitter["base_url"]! + "lists/ownerships.json")
        urls.append(Twitter["base_url"]! + "lists/subscriptions.json")
        urls.append(Twitter["base_url"]! + "lists/memberships.json")
        params.append(["user_id" : user.id, "count" : "200"])
        params.append(["user_id" : user.id, "count" : "200"])
        params.append(["user_id" : user.id, "count" : "500"])
    }

    class func getUrlsForSearchTableViewController(q: String, inout urls: [String], inout params: [Dictionary<String, AnyObject>], inout signedInUsers: [SignedInUser], inout userUrls: [String], inout userParams: [Dictionary<String, AnyObject>], inout userSignedInUsers: [SignedInUser], inout sections: [String]) {
        var searchForPosts = false
        for user in primaryCurrentSignedInUsers {
            switch user.clientUser.type {
            case .Facebook:
                userSignedInUsers.append(user)
                userSignedInUsers.append(user)
                let url = Facebook["base_url"]! + "search"
                userUrls.append(url)
                userUrls.append(url)
                userParams.append(["q" : q, "type" : "user"])
                userParams.append(["q" : q, "type" : "page"])
                sections.append("Facebook Users")
                sections.append("Facebook Pages")
            case .Twitter:
                searchForPosts = true
                userSignedInUsers.append(user)
                signedInUsers.append(user)
                userUrls.append(Twitter["base_url"]! + "users/search.json")
                urls.append(Twitter["base_url"]! + "search/tweets.json")
                userParams.append(["q" : q, "count" : "100"])
                params.append(["q" : "\(q)", "count" : "100"])
                sections.append("Twitter Users")
            case .Instagram:
                userSignedInUsers.append(user)
                let qNoSpace = q.stringByReplacingOccurrencesOfString(" ", withString: "")
                if qNoSpace.rangeOfCharacterFromSet(NSCharacterSet.symbolCharacterSet()) == nil {
                    searchForPosts = true
                    signedInUsers.append(user)
                    urls.append(Instagram["base_url"]! + "tags/\(qNoSpace)/media/recent")
                    params.append(["count" : "30"])
                }
                userUrls.append(Instagram["base_url"]! + "users/search.json")
                userParams.append(["q" : q, "count" : "30"])
                sections.append("Instagram Users")
            case .Tumblr:
                searchForPosts = true
                signedInUsers.append(user)
                urls.append(Tumblr["base_url"]! + "tagged")
                params.append(["tag" : q, "api_key" : Tumblr["key"]!, "filter" : "text", "notes_info" : "true"])
            case .SoundCloud:
                userSignedInUsers.append(user)
                userSignedInUsers.append(user)
                userUrls.append(SoundCloud["base_url"]! + "users")
                userUrls.append(SoundCloud["base_url"]! + "tracks")
                userParams.append(["q" : q])
                userParams.append(["q" : q])
                sections.append("SoundCloud Users")
                sections.append("SoundCloud Tracks")
            default:
                print("okidoki")
            }
        }
        if searchForPosts {
            sections.append("Posts with \"\(q)\"")
        }
    }
    
    class func openUrl(url: NSURL, del: CellDelegate) {
        let webViewController = WebViewController(url: url)
        webViewController.excludedActivityTypes = [UIActivityTypePostToFacebook, UIActivityTypePostToTwitter]
        del.pushViewController(webViewController)
        /*let webViewController = DZNWebViewController(URL: url)
        webViewController.allowHistory = true
        webViewController.showLoadingProgress = true
        webViewController.hideBarsWithGestures = true
        webViewController.supportedWebActions = .DZNWebActionAll
        webViewController.supportedWebNavigationTools = .All
        let navigationController = UINavigationController(rootViewController: webViewController)
        del.presentViewController(navigationController)
        */
    }

    class func formatTime(interval: NSTimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    class func contentInsetsFromAudioPlayer() -> CGFloat {
        if audioPlayerView != nil {
            if !audioPlayerView!.hidden && audioPlayerView!.superview != nil {
                return 63.5
            }
        }
        return 0
    }
    
}