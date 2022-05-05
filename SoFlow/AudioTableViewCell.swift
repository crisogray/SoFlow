//
//  AudioTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 04/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import SDWebImage

class AudioTableViewCell: UITableViewCell, AVAudioPlayerDelegate {

    @IBOutlet var playButton: UIButton!
    @IBOutlet var slider: UISlider!
    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var currentTimeLabelWidth: NSLayoutConstraint!
    @IBOutlet var durationLabelWidth: NSLayoutConstraint!
    @IBOutlet var durationLabel: UILabel!
    var post: Post!
    var media: Media!
    var data: NSData!
    var playerIsAudioPlayer: Bool {
        get {
            return currentAudioUrl == self.media.url
        }
    }
    var firstPlay = true
    var setWidths = false
    var timer: NSTimer!
    var title: String!
    var artist: String!
    var artworkUrl: NSURL!
    var artworkImage: UIImage?
    var touchDownOnSlider = false
    var tabBarController: UITabBarController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.playButton.setImage(UIImage(named: "Pause 20px")!, forState: .Selected)
        self.slider.addTarget(self, action: "touchDown", forControlEvents: .TouchDown)
        self.slider.addTarget(self, action: "touchUp", forControlEvents: .TouchUpInside)
        self.slider.addTarget(self, action: "touchUp", forControlEvents: .TouchUpOutside)
        self.slider.addTarget(self, action: "sliderChanged", forControlEvents: .ValueChanged)

    }
    
    func setPost(post: Post!, media: Media!, data: NSData?) {
        self.post = post
        self.media = media
        if let p = self.post as? SoundCloudPost {
            self.title = p.title
            self.artist = p.from!.username!
            self.artworkUrl = p.media!.url
        }
        if !self.playerIsAudioPlayer {
            if data == nil {
                self.playButton.setImage(nil, forState: .Normal)
                let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
                self.playButton.addSubview(activityIndicator)
                activityIndicator.center = CGPointMake(20, 20)
                activityIndicator.startAnimating()
                self.playButton.bringSubviewToFront(activityIndicator)
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    () -> Void in
                    let d = NSData(contentsOfURL: self.media.url)
                    if d != nil {
                        self.data = d!
                        if let _ = self.post as? SoundCloudPost {
                            (post as! SoundCloudPost).soundData = self.data
                        }
                        dispatch_async(dispatch_get_main_queue(), {
                            () -> Void in
                            activityIndicator.removeFromSuperview()
                            self.initPlayer()
                        })
                    }
                }
            } else {
                self.data = data
                self.initPlayer()
            }
        } else {
            self.data = audioPlayer.data!
            self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "sliderUpdate", userInfo: nil, repeats: true)
            if audioPlayer.playing {
                self.playButton.selected = true
            }
            self.firstPlay = false
            self.initPlayer()
        }
    }
    
    func touchDown() {
        self.touchDownOnSlider = true
    }
    
    func touchUp() {
        self.seekToTime()
        self.touchDownOnSlider = false
    }
    
    func sliderChanged() {
        if self.playerIsAudioPlayer {
            var currentTimeText = Utility.formatTime(NSTimeInterval(self.slider.value))
            if currentTimeText.hasPrefix("00:") {
                currentTimeText.removeRange(Range<String.Index>(start: currentTimeText.startIndex, end: currentTimeText.startIndex.advancedBy(3)))
            }
            self.currentTimeLabel.text = currentTimeText
        }
    }
    
    func initPlayer() {
        self.playButton.setImage(UIImage(named: "Play 24px")!, forState: .Normal)
        self.playButton.addTarget(self, action: "playPause", forControlEvents: .TouchUpInside)
        if !self.playerIsAudioPlayer {
            self.setSlider()
        } else {
            self.sliderUpdate()
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        self.firstPlay = true
        self.timer.invalidate()
        self.playButton.selected = false
        audioPlayer.prepareToPlay()
        self.sliderUpdate()
    }
    
    func setSlider() {
        let p = (try! AVAudioPlayer(data: self.data))
        self.updateSlider(p.duration, currentTime: p.currentTime)
    }
    
    func seekToTime() {
        if self.data != nil {
            if !self.playerIsAudioPlayer {
                audioPlayer = (try! AVAudioPlayer(data: self.data))
                currentAudioUrl = self.media!.url
            }
            let playing = audioPlayer.playing
            audioPlayer.currentTime = NSTimeInterval(self.slider.value)
            if playing {
                audioPlayer.play()
            }
        }
    }
    
    func sliderUpdate() {
        self.updateSlider(audioPlayer.duration, currentTime: audioPlayer.currentTime)
        if self.playerIsAudioPlayer {
            if audioPlayer.playing {
                self.playButton.selected = true
            } else {
                self.playButton.selected = false
            }
        } else {
            self.playButton.selected = false
        }
    }
    
    func updateSlider(duration: NSTimeInterval, currentTime: NSTimeInterval) {
        if !self.touchDownOnSlider {
            var durationText = Utility.formatTime(duration)
            var currentTimeText = Utility.formatTime(currentTime)
            if durationText.hasPrefix("00:") {
                durationText.removeRange(Range<String.Index>(start: durationText.startIndex, end: durationText.startIndex.advancedBy(3)))
            }
            if currentTimeText.hasPrefix("00:") {
                currentTimeText.removeRange(Range<String.Index>(start: currentTimeText.startIndex, end: currentTimeText.startIndex.advancedBy(3)))
            }
            self.currentTimeLabel.text = currentTimeText
            self.durationLabel.text = durationText
            self.setLabelWidths()
        }
        if self.playerIsAudioPlayer {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                () -> Void in
                if self.artworkImage == nil {
                    self.artworkImage = UIImage(data: NSData(contentsOfURL: self.artworkUrl)!)!
                }
                dispatch_async(dispatch_get_main_queue(), {
                    () -> Void in
                    let artwork = MPMediaItemArtwork(image: self.artworkImage!)
                    MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [
                        MPMediaItemPropertyArtist : self.artist,
                        MPMediaItemPropertyTitle : self.title,
                        MPMediaItemPropertyArtwork : artwork,
                        MPMediaItemPropertyPlaybackDuration : audioPlayer.duration,
                        MPNowPlayingInfoPropertyElapsedPlaybackTime : audioPlayer.currentTime
                    ]
                })
            })
            self.slider.maximumValue = Float(duration)
            if !self.touchDownOnSlider {
                self.slider.value = Float(currentTime)
            }
        } else {
            self.slider.value = 0
        }
    }
    
    func setLabelWidths() {
        if !self.setWidths {
            self.setWidths = true
            self.durationLabel.sizeToFit()
            self.currentTimeLabel.sizeToFit()
            self.durationLabelWidth.constant = self.durationLabel.frame.width + 4
            self.currentTimeLabelWidth.constant = self.currentTimeLabel.frame.width + 4
        }
    }
    
    func playPause() {
        if !self.playerIsAudioPlayer {
            audioPlayer = (try! AVAudioPlayer(data: self.data))
            if NSTimeInterval(self.slider.value) != audioPlayer.currentTime {
                self.seekToTime()
            }
            currentAudioUrl = self.media!.url
            self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "sliderUpdate", userInfo: nil, repeats: true)
        }
        if !audioPlayer.playing {
            if audioPlayerView == nil && audioPlayerView?.superview == nil {
                audioPlayerView = NSBundle.mainBundle().loadNibNamed("AudioPlayerView", owner: self, options: nil)[0] as? AudioPlayerView
                audioPlayerView!.frame.size = CGSizeMake(w, 64)
                audioPlayerView!.frame.origin.y = UIScreen.mainScreen().bounds.height - 113
                audioPlayerView!.frame.origin.x = 0
                audioPlayerView!.layer.borderWidth = 0.5
                audioPlayerView!.layer.borderColor = separatorColour.CGColor
                audioPlayerView!.setPost(self.post, media: self.media, title: self.title, artworkUrl: self.artworkUrl)
                UIApplication.sharedApplication().keyWindow!.rootViewController!.view.addSubview(audioPlayerView!)
            } else {
                audioPlayerView!.setPost(self.post, media: self.media, title: self.title, artworkUrl: self.artworkUrl)
                let tabView = UIApplication.sharedApplication().keyWindow!.rootViewController!.view
                if !tabView.subviews.contains(audioPlayerView!) {
                    tabView.addSubview(audioPlayerView!)
                }
                if audioPlayerView!.hidden {
                    audioPlayerView!.hidden = false
                }
                
            }
            audioPlayer.play()
        } else {
            audioPlayer.pause()
        }
    }

}
