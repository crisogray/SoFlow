//
//  Objects.swift
//  SoFlow
//
//  Created by Ben Gray on 03/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import CoreLocation
import OAuthSwift
import AVFoundation

let red: CGFloat = 114
let green: CGFloat = 183
let blue: CGFloat = 79
//let tintColour = UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
let tintColour = UIColor(red: 30 / 255, green: 180 / 255, blue: 220 / 255, alpha: 1)

let tableViewGroupedBackgroundColour = UIColor(red: 0.937255, green: 0.937255, blue: 0.956863, alpha: 1)

let services = ["Facebook", "Twitter", "Instagram", "Tumblr", "SoundCloud"]

let tabs = ["Home", /*"Notifications",*/ "Search", "User"]

let animationDuration = 0.3

var didChangePrimaryUser = false

var currentSignedInUsers = [SignedInUser]()
var primaryCurrentSignedInUsers = [SignedInUser]()

var changingViewController = false

let w = UIScreen.mainScreen().bounds.width

var audioPlayer = AVAudioPlayer()

var audioPlayerView: AudioPlayerView?

var currentAudioUrl = NSURL()

let Facebook = [
    "key" : "778085632284419",
    "secret" : "1f50d645328f0f294288dac16a232248",
    "base_url" : "https://graph.facebook.com/"
]

let FacebookColour = UIColor(red: 0.22, green: 0.34, blue: 0.6, alpha: 1)

let FacebookPostParams = [
    "fields" : "full_picture,from,message,story,name,caption,description,comments.summary(true),likes.summary(true),link,source,type,height,width,attachments,object_id",
    "limit" : "15"
]

let FacebookVideoParams = FacebookPostParams

let Twitter = [
    "key" : "AoUaEd37ZzdQOhxKAjXbsS8dB",
    "secret" : "Gi3diPIfeGMs3vqCm3T6kRv7y5wuBWQKqAQzX9X0H0UJ2tFxEz",
    "base_url" : "https://api.twitter.com/1.1/"
]

let TwitterColour = UIColor(red: 85 / 255, green: 172 / 255, blue: 238 / 255, alpha: 1)

let Instagram = [
    "key" : "2e40ab2dedaa4fb7a9e94f6c9cd9ea21",
    "secret" : "595a9be6e81544488050e215f22c449d",
    "base_url" : "https://api.instagram.com/v1/"
]

let InstagramColour = UIColor(red: 0.24, green: 0.44, blue: 0.62, alpha: 1)

let Tumblr = [
    "key" : "eXThw1MeXC46q02ZXdINRop7Xpk5NKaPBKZecYLLwGjLsDYoL7",
    "secret" : "SoK6VVFu5SibohhQba4zJoEojJcQQ67UiSw6E1CFZVw8iCyxKQ",
    "base_url" : "https://api.tumblr.com/v2/"
]

let TumblrColour = UIColor(red: 0.2, green: 0.27, blue: 0.36, alpha: 1)

let SoundCloud = [
    "key" : "19f528f66efa00c3ff6eabea30d5b0e2",
    "secret" : "ff809685ba176c51b3f1be86cca124d0",
    "base_url" : "https://api.soundcloud.com/"
]

let SoundCloudColour = UIColor(red: 1, green: 0.33, blue: 0, alpha: 1)

let colours = [
    Service.Facebook : FacebookColour,
    Service.Twitter : TwitterColour,
    Service.Instagram : InstagramColour,
    Service.Tumblr : TumblrColour,
    Service.SoundCloud : SoundCloudColour
]

enum Service: String {
    case Facebook = "Facebook"
    case Twitter = "Twitter"
    case Instagram = "Instagram"
    case Tumblr = "Tumblr"
    case SoundCloud = "SoundCloud"
    case None = "Name"
    case All = "All"
}

let founderIds: [Service : [String]] = [
    Service.Facebook : ["100003952981439", "100004929570075"],
    Service.Twitter : ["562201813", "356651832"],
    Service.Instagram : ["530970182", "26097036"]
]

enum Section {
    case Lists
}

enum MediaType {
    case Image, Video, Audio, Link
}

enum GroupedType {
    case List, Playlist
}

enum TumblrType {
    case Text, Quote, Link, Answer, Image
}

enum FuturePostType {
    case Comment, Post
}

class User {
    var id: String!
    var name: String?
    var username: String?
    var profilePictureUrl: NSURL?
    var profilePictureLargeUrl: NSURL?
    var type = Service.None
    var image: UIImage?
    var largeImage: UIImage?
    var timeline: [Post]?
    var followers: [User]?
    var friends: [User]?
    var following: Bool?
    
    init (id: String!, name: String?, username: String?, profilePictureUrl: NSURL?, type: Service!) {
        self.id = id
        self.name = name
        self.username = username
        self.profilePictureUrl = profilePictureUrl
        self.type = type
    }
}

class SignedInUser {
    var user: User
    var clientUser: User
    var client: OAuthSwiftClient!
    var refreshToken: String?
    var primary: Bool?
    
    init (client: OAuthSwiftClient, user: User, clientUser: User) {
        self.client = client
        self.user = user
        self.clientUser = clientUser
    }
}

class TextTag {
    var user: User!
    var range: NSRange!
    
    init (user: User!, range: NSRange!) {
        self.user = user
        self.range = range
    }
}

class PhotoTag {
    var user: User!
    var x: CGFloat!
    var y: CGFloat!
    
    init(user: User!, x: CGFloat!, y: CGFloat!) {
        self.user = user
        self.x = x
        self.y = y
    }
}

class Post {
    var id: String!
    var from: User?
    var date: NSDate!
    var signedInUser: SignedInUser!
    var type = Service.None
    var estimatedHeight: CGFloat?
    var cell: PostTableViewCell?
    
    init(id: String, from: User?, date: NSDate!, signedInUser: SignedInUser, type: Service) {
        self.id = id
        self.from = from
        self.date = date
        self.signedInUser = signedInUser
        self.type = type
    }
    
    var comments: [Comment]?
    var likes: [User]?
    var media: Media?
    var likeCount: Int?
    var commentCount: Int?
    var userLikes: Bool?
    
    init (id: String!, from: User!, date: NSDate!, signedInUser: SignedInUser!, type: Service!, comments: [Comment]?, likes: [User]?, media: Media?, userLikes: Bool?, likeCount: Int?, commentCount: Int?) {
        self.id = id
        self.from = from
        self.date = date
        self.signedInUser = signedInUser
        self.type = type
        self.comments = comments
        self.likes = likes
        self.media = media
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.userLikes = userLikes
    }
}


class FuturePost {
    var signedInUser: SignedInUser!
    var type: FuturePostType!
    var destinationUrl: String!
    var maxImages: Int!
    var location: Bool!
    var inReplyToPost: Post?
    var retweetUrl: String?
    
    init(signedInUser: SignedInUser!, type: FuturePostType!, destinationUrl: String!, maxImages: Int!, location: Bool!, inReplyToPost: Post?) {
        self.signedInUser = signedInUser
        self.type = type
        self.destinationUrl = destinationUrl
        self.maxImages = maxImages
        self.location = location
        self.inReplyToPost = inReplyToPost
    }
    
}

class Comment: Post {
    var message: String!
    
    init(id: String!, message: String!, from: User!, date: NSDate!, type: Service!, signedInUser: SignedInUser) {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, type: type)
        self.message = message
    }
}

class Media {
    var type: MediaType!
    var url: NSURL!
    var thumbnail: NSURL?
    var scale: CGFloat?
    
    init (type: MediaType!, url: NSURL!) {
        self.type = type
        self.url = url
    }
}

class LibraryPhoto: Media {
    var image: UIImage!
    var asset: AVAsset?
    
    init(image: UIImage!, asset: AVAsset?) {
        super.init(type: asset != nil ? .Video : .Image, url: NSURL())
        self.image = image
        self.asset = asset
    }
    
}

class Location {
    var coordinate: CLLocationCoordinate2D!
    var name: String?
    
    init(coordinate: CLLocationCoordinate2D, name: String?) {
        self.coordinate = coordinate
        self.name = name
    }
    
}

class FacebookUser: User {
    var verified: Bool?
    var location: String?
    var likes: [FacebookPage]?
    
    init(id: String!, name: String!, profilePictureUrl: NSURL?) {
        super.init(id: id, name: name, username: nil, profilePictureUrl: profilePictureUrl, type: .Facebook)
    }
    
    init (id: String!, name: String!, profilePictureUrl: NSURL?,
        verified: Bool?,
        location: String?,
        likes: [FacebookPage]?)
    {
        super.init(id: id, name: name, username: nil, profilePictureUrl: profilePictureUrl, type: .Facebook)
        self.location = location
        self.likes = likes
    }
}

class FacebookPage: FacebookUser {
    var category: String?
}

class FacebookLink: Media {
    var linkUrl: NSURL!

    init(url: NSURL!, linkUrl: NSURL!) {
        super.init(type: .Link, url: url)
        self.linkUrl = linkUrl
    }
}

class FacebookPost: Post {
    
    init(id: String!, from: User!, date: NSDate!, signedInUser: SignedInUser!) {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, type: .Facebook)
    }
    
    var message: String?
    var story: String?
    var storyTags: [TextTag]?
    var withTags: [FacebookUser]?
    var name: String?
    var description: String?
    var caption: String?
    var photos: [Media]?
    var embeddedPost: FacebookPost?
    
    init (id: String!, from: FacebookUser!, date: NSDate!, signedInUser: SignedInUser,
        message: String?,
        story: String?,
        storyTags: [TextTag]?,
        withTags: [FacebookUser]?,
        name: String?,
        description: String?,
        caption: String?,
        comments: [FacebookComment]?,
        likes: [FacebookUser]?,
        media: Media?,
        userLikes: Bool!,
        likeCount: Int!,
        commentCount: Int!,
        photos: [Media]?)
    {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, type: .Facebook, comments: comments, likes: likes, media: media, userLikes: userLikes, likeCount: likeCount, commentCount: commentCount)
        self.message = message
        self.story = story
        self.storyTags = storyTags
        self.withTags = withTags
        self.name = name
        self.description = description
        self.caption = caption
        self.likes = likes
        self.media = media
        self.userLikes = userLikes
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.photos = photos
        if self.photos != nil && self.media == nil {
            if !self.photos!.isEmpty {
                self.media = self.photos![0]
            }
        }
    }
    
}

class FacebookComment: Comment {
    var tags: [TextTag]?
    
    init (id: String, from: FacebookUser!, message: String!, date: NSDate!, likeCount: Int!, tags: [TextTag]?, signedInUser: SignedInUser, userLikes: Bool) {
        super.init(id: id, message: message, from: from, date: date, type: .Facebook, signedInUser: signedInUser)
        self.likeCount = likeCount
        self.tags = tags
        self.userLikes = userLikes
    }
}

class FacebookImageComment: FacebookComment {
    var link: NSURL?
}

class FacebookNotification: FacebookPost {
    var objectId: String?
    
    init(id: String, from: User?, date: NSDate!, signedInUser: SignedInUser, title: String, objectId: String?) {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser)
        self.message = title
        self.objectId = objectId
    }
    
}

class TwitterUser: User {
    var favouriteCount: Int!
    var followersCount: Int!
    var followingCount: Int!
    var verified: Bool!
    var description: String?
    var location: String?
    var url: NSURL?
    var tweetCount: Int!
    
    init(id: String!, name: String!, username: String!, profilePictureUrl: NSURL?) {
        super.init(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, type: .Twitter)
    }
    
    init(id: String!, name: String!, username: String!, profilePictureUrl: NSURL!,
        favouriteCount: Int!,
        followersCount: Int!,
        followingCount: Int!,
        verified: Bool!,
        description: String?,
        location: String?,
        url: NSURL?,
        tweetCount: Int!,
        following: Bool!)
    {
        super.init(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, type: .Twitter)
        self.favouriteCount = favouriteCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.verified = verified
        self.description = description
        self.location = location
        self.url = url
        self.tweetCount = tweetCount
        self.following = following
    }
    
}

class TwitterPost: Post {
    var mediaArray: [Media]?
    var text: String!
    var retweeted: Bool!
    var retweetCount: Int!
    var userRetweeted: Bool!
    var retweetUser: TwitterUser?
    var inReplyToUserId: String?
    var inReplyToStatusId: String?
    var userMentions: [TextTag]?
    var quotedStatus: TwitterPost?
    var location: TwitterLocation?
    
    init(id: String!, from: User!, date: NSDate!, signedInUser: SignedInUser!, mediaArray: [Media]?, userLikes: Bool?, likeCount: Int?,
        text: String!,
        retweeted: Bool!,
        retweetCount: Int!,
        userRetweeted: Bool!,
        retweetUser: TwitterUser?,
        inReplyToUserId: String?,
        inReplyToStatusId: String?,
        userMentions: [TextTag]?,
        quotedStatus: TwitterPost?,
        location: TwitterLocation?)
    {
        var media: Media?
        var video: Media?
        if mediaArray != nil {
            if !mediaArray!.isEmpty {
                for med in mediaArray! {
                    if med.type == .Video {
                        video = med
                    }
                }
                if video != nil {
                    media = video!
                } else {
                    media = mediaArray![0]
                }
            }
        }
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, type: .Twitter, comments: nil, likes: nil, media: media, userLikes: userLikes, likeCount: likeCount, commentCount: nil)
        self.text = text
        self.retweeted = retweeted
        self.retweetCount = retweetCount
        self.userRetweeted = userRetweeted
        self.retweetUser = retweetUser
        self.inReplyToUserId = inReplyToUserId
        self.inReplyToStatusId = inReplyToStatusId
        self.mediaArray = mediaArray
        self.userMentions = userMentions
        self.quotedStatus = quotedStatus
        self.location = location
    }
    
}

class TwitterLocation: Location {
    var id: String
    var country: String
    var countryCode: String
    
    init(id: String,
        name: String,
        country: String,
        countryCode: String,
        coordinate: CLLocationCoordinate2D)
    {
        self.id = id
        self.country = country
        self.countryCode = countryCode
        super.init(coordinate: coordinate, name: name)
    }
    
}

class TwitterList: User {
    var owner: TwitterUser!
    var memberCount: Int!
    var subscriberCount: Int!
    var description: String?
    
    init(id: String, name: String, owner: TwitterUser, memberCount: Int, subscriberCount: Int, description: String?) {
        super.init(id: id, name: name, username: nil, profilePictureUrl: owner.profilePictureUrl, type: .Twitter)
        self.owner = owner
        self.memberCount = memberCount
        self.subscriberCount = subscriberCount
        self.description = description
    }
}

class InstagramUser: User {
    var followersCount: Int?
    var followingCount: Int?
    var postCount: Int?
    var bio: String?
    var website: NSURL?
    
    init(id: String!, name: String?, username: String!, profilePictureUrl: NSURL!) {
        super.init(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, type: .Instagram)
    }
    
    init(id: String!, name: String?, username: String?, profilePictureUrl: NSURL?,
        followersCount: Int?,
        followingCount: Int?,
        postCount: Int?,
        bio: String?,
        website: NSURL?)
    {
        super.init(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, type: .Instagram)
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.postCount = postCount
        self.bio = bio
        self.website = website
    }
}

class InstagramPost: Post {
    var caption: Comment?
    var location: Location?
    var tags: [String]?
    var photoTags: [PhotoTag]?
    var link: String!
    
    init(id: String!, from: User!, date: NSDate!, signedInUser: SignedInUser!, media: Media!, userLikes: Bool!, likeCount: Int?, commentCount: Int?,
        caption: Comment?,
        location: Location?,
        tags: [String]?,
        photoTags: [PhotoTag]?,
        link: String!)
    {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, type: .Instagram, comments: nil, likes: nil, media: media, userLikes: userLikes, likeCount: likeCount, commentCount: commentCount)
        self.caption = caption
        self.location = location
        self.tags = tags
        self.userLikes = userLikes
        self.photoTags = photoTags
        self.link = link
    }
    
}

class TumblrUser: User {
    var description: String?
    var postCount: Int?
    var canAsk: Bool?
    var canAskAnon: Bool?
    var askPageTitle: String?
    
    init(id: String!, name: String?, username: String?, profilePictureUrl: NSURL?) {
        super.init(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, type: .Tumblr)
    }
    
    init(id: String!, name: String?, username: String?, profilePictureUrl: NSURL?,
        description: String?,
        postCount: Int?,
        canAsk: Bool?,
        canAskAnon: Bool?,
        askPageTitle: String?)
    {
        super.init(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, type: .Tumblr)
        self.description = description
        self.postCount = postCount
        self.canAsk = canAsk
        self.canAskAnon = canAskAnon
        self.askPageTitle = askPageTitle
    }
}

class TumblrMedia: Media {
    var caption: String?
    
    init(type: MediaType!, url: NSURL!, caption: String?) {
        super.init(type: type, url: url)
        self.caption = caption
    }
}

class TumblrPost: Post {
    var postType: TumblrType!
    var reblogKey: String!
    var tags: [String]?
    var reblogUser: TumblrUser?
    
    init(id: String, from: User?, date: NSDate, signedInUser: SignedInUser,
        postType: TumblrType, reblogKey: String, liked: Bool, tags: [String]?, reblogUser: TumblrUser?)
    {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, type: .Tumblr)
        self.postType = postType
        self.reblogKey = reblogKey
        self.userLikes = liked
        self.tags = tags
        self.reblogUser = reblogUser
    }
}

class TumblrTextPost: TumblrPost {
    var title: String?
    var body: String!
    
    init(id: String, from: User?, date: NSDate, signedInUser: SignedInUser, postType: TumblrType, reblogKey: String, liked: Bool, title: String?,
        body: String, tags: [String]?, reblogUser: TumblrUser?)
    {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, postType: .Text, reblogKey: reblogKey, liked: liked, tags: tags, reblogUser: reblogUser)
        self.title = title
        self.body = body
    }
}

class TumblrImagePost: TumblrPost {
    var mediaArray: [TumblrMedia]!
    var caption: String!
    
    init(id: String, from: User?, date: NSDate, signedInUser: SignedInUser, postType: TumblrType, reblogKey: String, liked: Bool,
        mediaArray: [TumblrMedia],
        caption: String?,
        tags: [String]?,
        reblogUser: TumblrUser?)
    {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, postType: postType, reblogKey: reblogKey, liked: liked, tags: tags, reblogUser: reblogUser)
        self.mediaArray = mediaArray
        self.caption = caption
    }
}

class TumblrQuotePost: TumblrPost {
    var text: String!
    var sourceUrl: NSURL!
    var sourceTitle: String!
    
    init(id: String, from: User?, date: NSDate, signedInUser: SignedInUser, postType: TumblrType, reblogKey: String, liked: Bool,
        text: String,
        sourceUrl: NSURL,
        sourceTitle: String,
        tags: [String]?,
        reblogUser: TumblrUser?)
    {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, postType: postType, reblogKey: reblogKey, liked: liked, tags: tags, reblogUser: reblogUser)
        self.text = text
        self.sourceUrl = sourceUrl
        self.sourceTitle = sourceTitle
    }
}

class TumblrLinkPost: TumblrPost {
    var title: String!
    var author: String?
    var url: NSURL!
    var publisher: String!
    var photos: [TumblrMedia]?
    var description: String!
    
    init(id: String, from: User?, date: NSDate, signedInUser: SignedInUser, postType: TumblrType, reblogKey: String, liked: Bool,
        title: String,
        author: String?,
        url: NSURL,
        publisher: String,
        photos: [TumblrMedia]?,
        description: String!,
        tags: [String]?,
        reblogUser: TumblrUser?)
    {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, postType: postType, reblogKey: reblogKey, liked: liked, tags: tags, reblogUser: reblogUser)
        self.title = title
        self.author = author
        self.url = url
        self.publisher = publisher
        self.photos = photos
        self.description = description
    }
}

class TumblrChatPost: TumblrPost {
    var title: String?
    var dialogue: [TumblrDialogue]!
    
    init(id: String, from: User?, date: NSDate, signedInUser: SignedInUser, postType: TumblrType, reblogKey: String, liked: Bool,
        title: String?,
        dialogue: [TumblrDialogue]!,
        tags: [String]?,
        reblogUser: TumblrUser?)
    {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, postType: postType, reblogKey: reblogKey, liked: liked, tags: tags, reblogUser: reblogUser)
        self.title = title
        self.dialogue = dialogue
    }
}

class TumblrDialogue {
    var name: String!
    var text: String!
    
    init(name: String, text: String) {
        self.name = name
        self.text = text
    }
}

class TumblrAnswerPost: TumblrPost {
    var question: String!
    var answer: String!
    var askingName: String!
    
    init(id: String, from: User?, date: NSDate, signedInUser: SignedInUser, postType: TumblrType, reblogKey: String, liked: Bool,
        question: String,
        answer: String,
        askingName: String,
        tags: [String]?,
        reblogUser: TumblrUser?)
    {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, postType: postType, reblogKey: reblogKey, liked: liked, tags: tags, reblogUser: reblogUser)
        self.question = question
        self.answer = answer
        self.askingName = askingName
    }
}

class SoundCloudUser: User {
    var description: String?
    var followersCount: Int?
    var followingCount: Int?
    var favouritesCount: Int?
    var trackCount: Int?
    var playlistCount: Int?
    
    init(id: String!, name: String?, username: String?, profilePictureUrl: NSURL?, description: String?, followersCount: Int?, followingCount: Int?, favouritesCount: Int?, trackCount: Int?, playlistCount: Int?) {
        super.init(id: id, name: name, username: username, profilePictureUrl: profilePictureUrl, type: .SoundCloud)
        self.description = description
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.favouritesCount = favouritesCount
        self.trackCount = trackCount
        self.playlistCount = playlistCount
    }
}

class SoundCloudPost: Post {
    var title: String!
    var audio: SoundCloudAudio!
    var description: String?
    var license: String!
    var canComment: Bool!
    var playsCount: Int?
    var soundData: NSData?
    
    init(id: String!, from: User!, date: NSDate!, signedInUser: SignedInUser!, title: String!, audio: SoundCloudAudio!, description: String?, license: String!, canComment: Bool!, playsCount: Int?, commentCount: Int?, likeCount: Int?, artwork: Media!) {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, type: .SoundCloud)
        self.title = title
        self.audio = audio
        self.description = description
        self.license = license
        self.canComment = canComment
        self.playsCount = playsCount
        self.commentCount = commentCount
        self.likeCount = likeCount
        self.media = artwork
    }
}

class SoundCloudAudio: Media {
    var duration: Int!
}

class SoundCloudPlaylist: Post {
    var title: String!
    var description: String?
    var trackCount: Int!
    var tracks: [SoundCloudPost]!
    
    init(title: String!, description: String?, trackCount: Int!, tracks: [SoundCloudPost]!, id: String, from: User?, date: NSDate, signedInUser: SignedInUser) {
        super.init(id: id, from: from, date: date, signedInUser: signedInUser, type: .SoundCloud)
        self.title = title
        self.description = description
        self.trackCount = trackCount
        self.tracks = tracks
    }
    
}