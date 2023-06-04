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
protocol checkedImageButtonDelegate: AnyObject {
    func buttonTapped(indexPath: IndexPath)
}

class CheckedTableViewCell: UITableViewCell {
    
    var checkedDalegate: checkedMarkDelegete?
    var imageDelegate: checkedImageButtonDelegate?

    var memoImageView: UIImageView!
    @IBOutlet var whiteView: UIView!
    @IBOutlet var checkMarkImageButton: UIButton!
    @IBOutlet var memoLabel: UILabel!
    @IBOutlet var imageButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        whiteView.layer.borderColor = UIColor.label.cgColor
        whiteView.layer.borderWidth = 1.0
        whiteView.layer.cornerRadius = 10.0
        
        let image = UIImage(systemName: "checkmark.square")
        checkMarkImageButton.setImage(image, for: .normal)
        checkMarkImageButton.tintColor = .label
    }
    
    var indexPath: IndexPath!
    
    @IBAction func check(_ sender:Any) {
        let image = UIImage(systemName: "square")
        checkMarkImageButton.setImage(image, for: .normal)
        checkMarkImageButton.tintColor = .label
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("check!")
            self.checkedDalegate?.buttonPressed(indexPath: self.indexPath)
            print("finish")
        }
        
    }
    
    @IBAction func image(_ sender: Any) {
        print("image!")
        self.imageDelegate?.buttonTapped(indexPath: self.indexPath)
        print("finish")
    }
}
