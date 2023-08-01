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
    @IBOutlet var checkMarkImageButton: UIButton!
    @IBOutlet var memoLabel: UILabel!
    @IBOutlet var imageButton: UIButton!
    
    var indexPath: IndexPath!
    var activityIndicatorView = UIActivityIndicatorView()
    var isCheckedBool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.backgroundColor = UIColor.systemGray6.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        imageButton.layer.cornerRadius = 7.5
        memoLabel.adjustsFontSizeToFitWidth = true
        activityIndicatorView.frame = checkMarkImageButton.frame
        activityIndicatorView.center.x = 20
        activityIndicatorView.center.y = 20
        activityIndicatorView.layer.contentsCenter = checkMarkImageButton.frame
        activityIndicatorView.style = .medium
        activityIndicatorView.color = .label
        
        checkMarkImageButton.addSubview(activityIndicatorView)
    }
    
    
    @IBAction func check(_ sender:Any) {
        checkMarkImageButton.setImage(UIImage(), for: .normal)
        activityIndicatorView.startAnimating()
        self.checkDalegate?.buttonPressed(indexPath: self.indexPath)
    }
    
    @IBAction func image(_ sender: Any) {
        self.imageDelegate?.buttonTapped(indexPath: self.indexPath)
    }
}
