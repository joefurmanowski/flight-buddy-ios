//
//  AirportTableViewCell.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/30/22.
//

import UIKit

class AirportTableViewCell: UITableViewCell {

    @IBOutlet weak var flag: UIImageView!
    @IBOutlet weak var airportName: UILabel!
    @IBOutlet weak var airportDetails: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
