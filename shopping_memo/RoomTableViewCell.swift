//
//  RoomTableViewCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/11.
//

import UIKit

class RoomTableViewCell: UITableViewCell {

    @IBOutlet var roomNameLabel: UILabel!
    @IBOutlet var lastEditTimeLabel: UILabel!
    @IBOutlet var editorLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        roomNameLabel.adjustsFontSizeToFitWidth = true
        lastEditTimeLabel.adjustsFontSizeToFitWidth = true
        editorLabel.adjustsFontSizeToFitWidth = true
    }
    
}
