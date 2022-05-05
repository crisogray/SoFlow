//
//  TitleView.swift
//  EZSwipeController
//
//  Created by Ben Gray on 19/11/2015.
//  Copyright © 2015 Goktug Yilmaz. All rights reserved.
//

import UIKit
import S4PageControl

class TitleView: UIView {

    @IBOutlet var label: UILabel!
    @IBOutlet var pageControl: S4PageControl!
    
    func setTitle(title: String, index: UInt, total: UInt, dark: Bool) {
        self.label.text = title
        self.pageControl.numberOfPages = total
        self.pageControl.currentPage = index
        self.pageControl.indicatorSize = CGSizeMake(5, 5)
        self.pageControl.indicatorSpace = 5
        if dark {
            self.pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
            self.label.textColor = UIColor.blackColor()
            self.pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        } else {
            self.pageControl.currentPageIndicatorTintColor = UIColor.whiteColor()
            self.label.textColor = UIColor.whiteColor()
            self.pageControl.pageIndicatorTintColor = UIColor.whiteColor().colorWithAlphaComponent(0.25)
        }
    }

}
