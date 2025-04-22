//
//  CommentTableViewCell.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 12/1/22.
//

import UIKit

class CommentTableViewCell: UITableViewCell {

    @IBOutlet weak var profileName: UILabel!
    @IBOutlet weak var comment: UILabel!
    @IBOutlet weak var postedDateTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
