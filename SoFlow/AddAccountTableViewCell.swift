//
//  AddAccountTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 27/11/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit

class AddAccountTableViewCell: UITableViewCell {
    
    @IBOutlet var serviceImageView: UIImageView!
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    
    func setAccountsViewController(accountsViewController: AccountsTableViewController, s: String) {
        self.serviceImageView.image = UIImage(named: s + " 64px")!
        self.heightConstraint.constant = 150
        self.contentView.backgroundColor = UIColor.clearColor()
        self.backgroundColor = UIColor.clearColor()
    }

}
