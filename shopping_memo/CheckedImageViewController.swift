//
//  ImageViewViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/05/23.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class CheckedImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var plusButton: UIButton!
    @IBOutlet var memoLabel: UILabel!
    @IBOutlet var noImageLabel: UILabel!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var upDateLabel: UILabel!
    
    var shoppingMemoName: String!
    var memoIdString: String!
    var imageUrlString: String!
    var userId: String!
    var list: String!
    var imageRef: StorageReference!
    let nonCheck = "未チェック"
    let memo = "memo"
    var ref: DatabaseReference!
    let df = DateFormatter()
    let storage = Storage.storage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        memoLabel.text = shoppingMemoName
        noImageLabel.isHidden = true
        
        let image = UIImage(systemName: "plus")
        plusButton.setImage(image, for: .normal)
        plusButton.tintColor = .black
        
        plusButton.layer.cornerRadius = 10.0
        plusButton.layer.borderWidth = 1.5
        plusButton.layer.borderColor = UIColor.black.cgColor
        
        upDateLabel.layer.cornerRadius = 5.0
        upDateLabel.layer.borderWidth = 1.5
        upDateLabel.layer.borderColor = UIColor.label.cgColor
        
        let image2 = UIImage(systemName: "multiply.circle")
        deleteButton.setImage(image2, for: .normal)
        deleteButton.tintColor = .label
        
        memoLabel.adjustsFontSizeToFitWidth = true
        upDateLabel.adjustsFontSizeToFitWidth = true
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        userId = Auth.auth().currentUser?.uid
        ref = Database.database().reference()
        
        guard let uid = userId else { return }
        guard let list = list else { return }
        guard let memoId = memoIdString else { return }
        
        ref.child("users").child(uid).child(list).child(memo).child(memoId).child("imageUrl").observeSingleEvent(of: .value, with:  { [self] snapshot in
            if snapshot.value == nil {
                return
            }
            
            guard let url = snapshot.value as? String else { return }
            if url == "" {
                imageView.contentMode = .center
                imageView.preferredSymbolConfiguration = .init(pointSize: 100)
                imageView.backgroundColor = UIColor.systemGray5
                imageView.image = UIImage(systemName: "photo")
                imageView.tintColor = UIColor.label
                noImageLabel.isHidden = false
                upDateLabel.text = "最終更新日時:"
            } else {
                imageRef = storage.reference(forURL: url)
                imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        let image = UIImage(data: data!)
                        self.imageView.contentMode = .scaleAspectFit
                        self.imageView.image = image
                        self.noImageLabel.isHidden = true
                    }
                }
                imageRef.getMetadata { [self] metadata, error in
                    if let error = error {
                        print(error)
                    } else {
                        let date = metadata?.timeCreated
                        df.dateStyle = .medium
                        df.timeStyle = .medium
                        df.timeZone = TimeZone(identifier: "Asia/Tokyo")
                        df.locale = Locale(identifier: "ja_JP")
                        upDateLabel.text = " 最終更新日時:" + df.string(from: date!) + " "
                    }
                }
            }
        }) { error in
            print(error.localizedDescription)
        }
        
        ref.child("users").child(uid).child(list).child(memo).observe(.childChanged, with: { [self] snapshot in
            guard let url = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
            if url == "" {
                imageView.contentMode = .center
                imageView.preferredSymbolConfiguration = .init(pointSize: 100)
                imageView.backgroundColor = UIColor.systemGray5
                imageView.image = UIImage(systemName: "photo")
                imageView.tintColor = UIColor.label
                noImageLabel.isHidden = false
                upDateLabel.text = "最終更新日時:"
            } else {
                imageRef = storage.reference(forURL: url)
                imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        let image = UIImage(data: data!)
                        self.imageView.contentMode = .scaleAspectFit
                        self.imageView.image = image
                        self.noImageLabel.isHidden = true
                    }
                }
                imageRef.getMetadata { [self] metadata, error in
                    if let error = error {
                        print(error)
                    } else {
                        let date = metadata?.timeCreated
                        df.dateStyle = .medium
                        df.timeStyle = .medium
                        df.timeZone = TimeZone(identifier: "Asia/Tokyo")
                        df.locale = Locale(identifier: "ja_JP")
                        upDateLabel.text = " 最終更新日時:" + df.string(from: date!) + " "
                    }
                }
            }
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.3) /*as? UIImage*/ else { return }
        guard let uid = userId else { return }
        guard let memoId = memoIdString else { return }
        let imageRef = Storage.storage().reference().child("/\(uid)/\(memoId).jpg")
        
        noImageLabel.isHidden = true
        imageView.backgroundColor = .clear
        
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print(error)
            } else {
                imageRef.downloadURL { (url, error) in
                    guard let downloadURL = url else { return }
                    let imageUrl = downloadURL.absoluteString
                    self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["imageUrl": imageUrl])
                }
            }
        }
        //.originalImageにするとトリミングなしになる
        //imageView.image = info[.originalImage] as? UIImage
        imageView.image = nil
        upDateLabel.text = ""
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
    
    @IBAction func deleteImage() {
        guard let uid = userId else { return }
        guard let memoId = memoIdString else { return }
        let imageRef = Storage.storage().reference().child("/\(uid)/\(memoId).jpg")
        
        if imageView.image == UIImage(systemName: "photo") {
            let alert: UIAlertController = UIAlertController(title: "削除できません。", message: "削除できる画像がありません。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default
                )
            )
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert: UIAlertController = UIAlertController(title: "画像を削除", message: "画像を削除してもよろしいですか。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        imageRef.delete { error in
                            if let error = error {
                                print(error)
                            } else {
                                self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["imageUrl": ""])
                                self.imageView.contentMode = .center
                                self.imageView.preferredSymbolConfiguration = .init(pointSize: 100)
                                self.imageView.backgroundColor = UIColor.systemGray5
                                self.imageView.image = UIImage(systemName: "photo")
                                self.imageView.tintColor = UIColor.label
                                self.noImageLabel.isHidden = false
                                self.upDateLabel.text = "最終更新日時:"
                            }
                        }
                    })
            )
            alert.addAction(
                UIAlertAction(
                    title: "キャンセル",
                    style: .cancel
                )
            )
            self.present(alert, animated: true, completion: nil)
        }
    }
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }
}
