//
//  ImageVideoTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 28/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ImageVideoTableViewCell: UITableViewCell {

    @IBOutlet var mainView: UIView!
    @IBOutlet var mainViewHeight: NSLayoutConstraint!
    var del: CellDelegate!
    var media: [Media]!
    
    override func awakeFromNib() {
        self.contentView.userInteractionEnabled = false
    }
    
    func setMediaArray(media: [Media]) {
        self.media = media
        let string = Utility.getStringForNibFromMediaArrayCount(self.media.count)
        let view = NSBundle.mainBundle().loadNibNamed(string, owner: self, options: nil)[0] as! ImageView
        view.frame.size = self.mainView.frame.size
        view.setMediaArray(self.media, cell: self, constraint: self.mainViewHeight, max: false)
        for s in self.mainView.subviews {
            let subView = s 
            subView.removeFromSuperview()
        }
        self.mainView.insertSubview(view, atIndex: 0)
    }
    
    func showImage(sender: UITapGestureRecognizer) {
        let iView = sender.view as! UIImageView
        if iView.image != nil {
            self.del.showImage(iView.image!, view: iView)
        }
    }
    
    func showVideo() {
        let m = media[0]
        if m.type == MediaType.Video {
            if let lp = m as? LibraryPhoto {
                let videoViewController = VideoViewController(asset: lp.asset!)
                self.del.pushViewController(videoViewController)
            } else {
                self.del.showVideo(m.url)
            }
            
        }
    }

}
