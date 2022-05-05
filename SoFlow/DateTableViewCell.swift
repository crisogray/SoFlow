//
//  DateTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 31/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class DateTableViewCell: UITableViewCell {

    @IBOutlet var dateLabel: UILabel!
    
    func setDate(date: NSDate) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "hh:mm a - dd MMM yyyy"
        self.dateLabel.text = dateFormatter.stringFromDate(date)
    }

}
