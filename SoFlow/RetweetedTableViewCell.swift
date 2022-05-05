//
//  RetweetedTableViewCell.swift
//  SoFlow
//
//  Created by Ben Gray on 30/08/2015.
//  Copyright (c) 2015 Graypfruit. All rights reserved.
//

import UIKit

class RetweetedTableViewCell: UITableViewCell {

    @IBOutlet var button: UIButton!
    var user: SignedInUser!
    var del: CellDelegate!

    func setRetweetUser(user: User, signedInUser: SignedInUser) {
        self.user = SignedInUser(client: signedInUser.client, user: user, clientUser: signedInUser.clientUser)
        if user.type == Service.Twitter {
            if user.id == signedInUser.clientUser.id {
                self.button.setTitle("You retweeted", forState: .Normal)
            } else {
                self.button.setTitle(user.name! + " retweeted", forState: .Normal)
            }
        } else {
            self.button.setTitle("Reblog: " + user.name!, forState: .Normal)
        }
    }
    
    @IBAction func showUser() {
        self.del.showUser(user)
    }
    
}
