//
//  CustomTableViewCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2022/12/02.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

protocol checkMarkDelegete: AnyObject {
    func buttonPressed(indexPath: IndexPath)
}
protocol imageButtonDelegate: AnyObject {
    func buttonTapped(indexPath: IndexPath)
}


class CustomTableViewCell: UITableViewCell {
    
    var checkDalegate: checkMarkDelegete?
    var imageDelegate: imageButtonDelegate?
    
    var memoImageView: UIImageView!
    @IBOutlet var whiteView: UIView!
    @IBOutlet var checkMarkImageButton: UIButton!
    @IBOutlet var memoLabel: UILabel!
    @IBOutlet var imageButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.layer.backgroundColor = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        whiteView.layer.borderColor = UIColor.label.cgColor
        whiteView.layer.borderWidth = 1.0
        whiteView.layer.cornerRadius = 10.0
        
        let image = UIImage(systemName: "square")
        checkMarkImageButton.setImage(image, for: .normal)
        checkMarkImageButton.tintColor = .black
        
        imageButton.layer.cornerRadius = 7.5
        
    }
    
    var indexPath: IndexPath!
    
    @IBAction func check(_ sender:Any) {
        let image = UIImage(systemName: "checkmark.square")
        checkMarkImageButton.setImage(image, for: .normal)
        checkMarkImageButton.tintColor = .black
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("check!")
            self.checkDalegate?.buttonPressed(indexPath: self.indexPath)
            print("finish")
        }
        
    }
    
    @IBAction func image(_ sender: Any) {
        print("image!")
        self.imageDelegate?.buttonTapped(indexPath: self.indexPath)
        print("finish")
    }
    
}
