//
//  RouteMidTableViewCell.swift
//  berkeleyMobileiOS
//
//  UITableViewCell that displays intermediate stops of bus route.
//  Used in RouteViewController.
//
//  Created by Akilesh Bapu on 11/16/17.
//  Copyright © 2017 org.berkeleyMobile. All rights reserved.
//

import UIKit

class RouteMidTableViewCell: UITableViewCell {

    @IBOutlet weak var stopName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
