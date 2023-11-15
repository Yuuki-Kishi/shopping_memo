//
//  ImageTableViewCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/13.
//

import UIKit

class ImageTableViewCell: UITableViewCell {
    
    @IBOutlet var ItemLabel: UILabel!
    @IBOutlet var DataLabel: UILabel!
    
    @IBOutlet var qrImageView: UIImageView!

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
