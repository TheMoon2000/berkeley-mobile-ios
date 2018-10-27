//
//  BarChartCell.swift
//  berkeleyMobileiOS
//
//  Created by Jia Rui Shan on 2018/10/23.
//  Copyright © 2018 org.berkeleyMobile. All rights reserved.
//

import UIKit

class BarChartCell: UITableViewCell {

    @IBOutlet weak var barChart: BarChart!
    @IBOutlet weak var loading: RPCircularProgress!
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var caption: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        barChart.dateString = "2018/10/04" // Sample, should be set to current date
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
