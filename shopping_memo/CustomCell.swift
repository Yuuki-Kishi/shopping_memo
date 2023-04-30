//
//  CustomCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2022/11/20.
//

import UIKit

class CustomCell: UICollectionViewCell {

    @IBOutlet var listLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 2.0
        layer.cornerRadius = 20.0
    }

}
