//
//  WebViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 09/05/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit
import PBWebViewController

class WebViewController: PBWebViewController {
    
    convenience init(url: NSURL) {
        self.init()
        self.URL = url
    }

    override func loadView() {
        super.loadView()
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = Utility.backButtonForTarget(self)
        self.view.backgroundColor = UIColor.whiteColor()
        self.navigationController!.toolbar.translucent = false
    }
    
    func back() {
        self.navigationController?.popViewControllerAnimated(true)
    }

}
