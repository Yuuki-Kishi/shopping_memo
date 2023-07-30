//
//  NotLogInTableViewCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/05/21.
//

import UIKit

class NotLogInTableViewCell: UITableViewCell {

    @IBOutlet var memoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        memoLabel.adjustsFontSizeToFitWidth = true
    }
    
}
