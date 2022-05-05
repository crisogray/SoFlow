//
//  AudioPlayerView.swift
//  SoFlow
//
//  Created by Ben Gray on 05/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class AudioPlayerView: UIView {

    @IBOutlet var artworkImageView: UIImageView!
    @IBOutlet var titleView: UILabel!
    @IBOutlet var playButton: UIButton!
    var post: Post!
    var timer: NSTimer!
    
    override func awakeFromNib() {
        self.playButton.setImage(UIImage(named: "Pause 20px")!, forState: .Selected)
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "checkPlayButton", userInfo: nil, repeats: true)
    }
    
    func setPost(post: Post, media: Media!, title: String, artworkUrl: NSURL) {
        self.post = post
        self.titleView.text = title
        self.artworkImageView.sd_setImageWithURL(artworkUrl)
        self.playButton.addTarget(self, action: "playPause", forControlEvents: .TouchUpInside)
        self.addTap(self, action: "showPost")
    }
    
    func showPost() {
        let tabBarController = UIApplication.sharedApplication().keyWindow!.rootViewController as! UITabBarController
        var currentNav = tabBarController.selectedViewController! as! UINavigationController
        let postViewController = PostTableViewController(post: self.post)
        var shouldGo = true
        if let postVc = currentNav.visibleViewController! as? PostTableViewController {
            if postVc.post.type == self.post.type {
                if postVc.post.id == self.post.id {
                    shouldGo = false
                    postVc.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true)
                }
            }
        } else if let swipeViewController = currentNav.visibleViewController! as? HomeSwipeViewController {
            currentNav = swipeViewController.viewControllers[swipeViewController.index] as! UINavigationController
        }
        if shouldGo {
            currentNav.pushViewController(postViewController, animated: true)
        }
    }
    
    func checkPlayButton() {
        if audioPlayer.playing {
            self.playButton.selected = true
        } else {
            self.playButton.selected = false
        }
    }
    
    func playPause() {
        if audioPlayer.playing {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }
    
    @IBAction func close() {
        audioPlayer.pause()
        self.removeFromSuperview()
    }

}
