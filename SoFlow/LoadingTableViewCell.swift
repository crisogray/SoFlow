//
//  LoadingTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 18/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class LoadingTableViewCell: UITableViewCell {

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.activityIndicator.startAnimating()
    }

    override func prepareForReuse() {
        self.activityIndicator.startAnimating()
    }
    
}