//
//  CheckedTableViewCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/04/08.
//

import UIKit


class SettingTableViewCell: UITableViewCell {
    
    @IBOutlet var ItemLabel: UILabel!
    @IBOutlet var DataLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        ItemLabel.adjustsFontSizeToFitWidth = true
        DataLabel.adjustsFontSizeToFitWidth = true
    }
    
}
