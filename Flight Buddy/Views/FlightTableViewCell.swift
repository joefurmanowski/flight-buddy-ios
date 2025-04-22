//
//  FlightTableViewCell.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/14/22.
//

import UIKit

class FlightTableViewCell: UITableViewCell {

    @IBOutlet weak var flightNumber: UILabel!
    @IBOutlet weak var departureAndArrival: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var flightImage: UIImageView!
    @IBOutlet weak var airline: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
