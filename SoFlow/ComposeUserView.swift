//
//  ComposeUserView.swift
//  SoFlow
//
//  Created by Ben Gray on 23/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class ComposeUserView: UIView {

    @IBOutlet var button: UIButton!
    @IBOutlet var serviceTypeImageView: UIImageView!
    var futurePost: FuturePost!
    var serviceTypeDisabledView = UIView(frame: CGRectMake(0, 0, 22, 22))
    var buttonDisabledView = UIView(frame: CGRectMake(0, 0, 48, 48))
    var disabledAlpha: CGFloat = 0.7
    var eligible = true {
        didSet {
            self.buttonDisabledView.hidden = self.eligible
            self.serviceTypeDisabledView.hidden = self.eligible
        }
    }
    var composeCell: ComposeTableViewCell!
    var ineligibilityMessage: String?
    
    override func awakeFromNib() {
        self.serviceTypeImageView.backgroundColor = UIColor.whiteColor()
        self.serviceTypeImageView.layer.cornerRadius = self.serviceTypeImageView.frame.height / 2
        self.button.layer.cornerRadius = 24
        self.button.backgroundColor = separatorColour
        self.serviceTypeDisabledView.backgroundColor = UIColor.blackColor()
        self.serviceTypeDisabledView.alpha = self.disabledAlpha
        self.serviceTypeImageView.addSubview(self.serviceTypeDisabledView)
        self.serviceTypeDisabledView.hidden = true
        self.buttonDisabledView.backgroundColor = UIColor.blackColor()
        self.buttonDisabledView.alpha = self.disabledAlpha
        self.button.addSubview(self.buttonDisabledView)
        self.buttonDisabledView.hidden = true
        self.button.addTarget(self, action: "sendPost", forControlEvents: .TouchUpInside)
        self.addTap(self, action: "showIneligibilityAlert")
    }
    
    func sendPost() {
        if self.eligible {
            self.composeCell.sendFuturePost(self.tag)
        }
    }
    
    func showIneligibilityAlert() {
        self.composeCell.textView.resignFirstResponder()
        let alert = UIAlertController(title: "Can't post to \(self.futurePost.signedInUser.clientUser.type.rawValue)", message: self.ineligibilityMessage!, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Okay", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        self.composeCell.tableViewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    func setFuturePost(futurePost: FuturePost) {
        self.futurePost = futurePost
        self.serviceTypeImageView.image = UIImage(named: "\(self.futurePost.signedInUser.clientUser.type.rawValue) 20px")
        self.button.sd_setImageWithURL(futurePost.signedInUser.clientUser.profilePictureUrl!, forState: .Normal)
    }
    

}
