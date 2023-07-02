//
//  CustomListCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2022/12/03.
//

import UIKit

class CustomListCell: UITableViewCell {
    
    @IBOutlet var listLabel: UILabel!
    @IBOutlet var whiteView: UIView!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        whiteView.layer.borderColor = UIColor.label.cgColor
        whiteView.layer.borderWidth = 1.0
        whiteView.layer.cornerRadius = 10.0
        
        whiteView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        whiteView.layer.shadowColor = UIColor.label.cgColor
        whiteView.layer.shadowOpacity = 0.3
        whiteView.layer.shadowRadius = 4
        
    }
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
