//
//  CustomListCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2022/12/03.
//

import UIKit

class CustomListCell: UITableViewCell {
    
    @IBOutlet var listLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        listLabel.adjustsFontSizeToFitWidth = true
    }
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
