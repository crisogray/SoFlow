//
//  VideoViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 21/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class VideoViewController: AVPlayerViewController {

    var playerViewWasShown = false
    
    convenience init(url: NSURL) {
        self.init()
        self.navigationItem.hidesBackButton = true
        self.view.backgroundColor = UIColor.whiteColor()
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        self.player = AVPlayer(URL: url)
        if currentAudioUrl.relativeString != nil {
            if audioPlayer.playing {
                audioPlayer.pause()
            }
            if audioPlayerView != nil {
                if audioPlayerView!.superview != nil {
                    self.playerViewWasShown = true
                }
                audioPlayerView!.hidden = true
            }
        }
        self.player!.play()
    }
    
    convenience init(asset: AVAsset) {
        self.init()
        self.navigationItem.hidesBackButton = true
        self.view.backgroundColor = UIColor.whiteColor()
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        if currentAudioUrl.relativeString != nil {
            if audioPlayer.playing {
                audioPlayer.pause()
            }
            if audioPlayerView?.superview != nil {
                self.playerViewWasShown = true
            }
            audioPlayerView!.hidden = true
        }
        self.player!.play()
    }
    
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
        if self.playerViewWasShown {
            audioPlayerView!.hidden = false
        }
    }
    
}
