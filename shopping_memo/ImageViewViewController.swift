//
//  ImageViewViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2022/12/05.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ImageViewViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var memoNameLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var plusButton: UIButton!
    @IBOutlet var memoLabel: UILabel!
    
    var shoppingMemoName: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        memoLabel.text = shoppingMemoName
        
        let image = UIImage(systemName: "plus")
        plusButton.setImage(image, for: .normal)
        plusButton.tintColor = .black
        
        plusButton.layer.cornerRadius = 10.0
        plusButton.layer.borderWidth = 1.5
        plusButton.layer.borderColor = UIColor.black.cgColor
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //.originalImageにするとトリミングなしになる
        imageView.image = info[.originalImage] as? UIImage
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func openAlbum() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }

}
