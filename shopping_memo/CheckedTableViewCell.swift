//
//  CheckedTableViewCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/04/08.
//

import UIKit

protocol checkedMarkDelegete: AnyObject {
    func buttonPressed(indexPath: IndexPath)
}

class CheckedTableViewCell: UITableViewCell {
    
    var checkedDalegate: checkedMarkDelegete?
    
    var memoImageView: UIImageView!
    @IBOutlet var whiteView: UIView!
    @IBOutlet var checkMarkImageButton: UIButton!
    @IBOutlet var memoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        whiteView.layer.borderColor = UIColor.black.cgColor
        whiteView.layer.borderWidth = 1.0
        whiteView.layer.cornerRadius = 10.0
        
        let image = UIImage(systemName: "checkmark.square")
        checkMarkImageButton.setImage(image, for: .normal)
        checkMarkImageButton.tintColor = .black
    }
    
    var indexPath: IndexPath!
    
    @IBAction func check(_ sender:Any) {
        let image = UIImage(systemName: "square")
        checkMarkImageButton.setImage(image, for: .normal)
        checkMarkImageButton.tintColor = .black
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("check!")
            self.checkedDalegate?.buttonPressed(indexPath: self.indexPath)
            print("finish")
        }
        
    }
    
}
