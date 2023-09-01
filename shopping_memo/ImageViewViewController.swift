//
//  ImageViewViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2022/12/05.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class ImageViewViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var noImageLabel: UILabel!
    @IBOutlet var upDateLabel: UILabel!
    
    var shoppingMemoName: String!
    var memoIdString: String!
    var imageUrlString: String!
    var userId: String!
    var list: String!
    var imageRef: StorageReference!
    let memo = "memo"
    var ref: DatabaseReference!
    let df = DateFormatter()
    let storage = Storage.storage()
    let activityIndicatorView = UIActivityIndicatorView()
    var connect = false
    var menuBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = shoppingMemoName

        noImageLabel.isHidden = true
        
        upDateLabel.layer.cornerRadius = 5.0
        upDateLabel.clipsToBounds = true
        upDateLabel.layer.cornerCurve = .continuous
        
        upDateLabel.adjustsFontSizeToFitWidth = true
                
        userId = Auth.auth().currentUser?.uid
        ref = Database.database().reference()
        
        guard let uid = userId else { return }
        guard let list = list else { return }
        guard let memoId = memoIdString else { return }
        
        activityIndicatorView.center = view.center
        activityIndicatorView.style = .large
        activityIndicatorView.color = .label
        
        print(imageView.center)
        print(activityIndicatorView.center)
        
        imageView.addSubview(activityIndicatorView)
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
          }})
        
        ref.child("users").child(uid).child(list).child(memo).child(memoId).child("imageUrl").observeSingleEvent(of: .value, with:  { [self] snapshot in
            if snapshot.value == nil {
                return
            }
            guard let url = snapshot.value as? String else { return }
            menu(url: url)
            if url == "" {
                imageView.contentMode = .center
                imageView.preferredSymbolConfiguration = .init(pointSize: 100)
                imageView.image = UIImage(systemName: "photo")
                imageView.tintColor = UIColor.label
                noImageLabel.isHidden = false
                upDateLabel.text = " 最終更新日時:"
            } else {
                activityIndicatorView.startAnimating()
                imageRef = storage.reference(forURL: url)
                imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        let image = UIImage(data: data!)
                        self.imageView.contentMode = .scaleAspectFit
                        self.activityIndicatorView.stopAnimating()
                        self.imageView.image = image
                        self.noImageLabel.isHidden = true
                    }
                }
                imageRef.getMetadata { [self] metadata, error in
                    if let error = error {
                        print(error)
                    } else {
                        let date = metadata?.timeCreated
                        df.locale = Locale(identifier: "ja_JP")
                        df.dateStyle = .medium
                        df.timeStyle = .medium
                        upDateLabel.text = " 最終更新日時:" + df.string(from: date!) + " "
                    }
                }
            }
        }) { error in
            print(error.localizedDescription)
        }
        
        ref.child("users").child(uid).child(list).child(memo).observe(.childChanged, with: { [self] snapshot in
            activityIndicatorView.startAnimating()
            guard let url = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
            menu(url: url)
            if url == "" {
                imageView.contentMode = .center
                imageView.preferredSymbolConfiguration = .init(pointSize: 100)
                activityIndicatorView.stopAnimating()
                imageView.image = UIImage(systemName: "photo")
                imageView.tintColor = UIColor.label
                noImageLabel.isHidden = false
                upDateLabel.text = " 最終更新日時:"
            } else {
                imageRef = storage.reference(forURL: url)
                imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        let image = UIImage(data: data!)
                        self.imageView.contentMode = .scaleAspectFit
                        self.activityIndicatorView.stopAnimating()
                        self.imageView.image = image
                        self.noImageLabel.isHidden = true
                    }
                }
                imageRef.getMetadata { [self] metadata, error in
                    if let error = error {
                        print(error)
                    } else {
                        let date = metadata?.timeCreated
                        df.locale = Locale(identifier: "ja_JP")
                        df.dateStyle = .medium
                        df.timeStyle = .medium
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
//        upDateLabel.text = ""
        dismiss(animated: true, completion: nil)
    }
    
    func openAlbum() {
        if connect {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                present(picker, animated: true, completion: nil)
            }
        } else {
            let alert: UIAlertController = UIAlertController(title: "インターネット未接続", message: "ネットワークの接続状態を確認してください。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                    }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func deleteImage() {
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
                if connect {
                    let alert: UIAlertController = UIAlertController(title: "画像を削除", message: "画像を削除してもよろしいですか。", preferredStyle: .alert)
                    alert.addAction(
                        UIAlertAction(
                            title: "削除",
                            style: .destructive,
                            handler: { action in
                                self.activityIndicatorView.startAnimating()
                                imageRef.delete { error in
                                    if let error = error {
                                        print(error)
                                    } else {
                                        self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["imageUrl": ""])
                                        self.imageView.contentMode = .center
                                        self.imageView.preferredSymbolConfiguration = .init(pointSize: 100)
                                        self.imageView.image = UIImage(systemName: "photo")
                                        self.imageView.tintColor = UIColor.label
                                        self.noImageLabel.isHidden = false
                                        self.upDateLabel.text = " 最終更新日時:"
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
                } else {
                    let alert: UIAlertController = UIAlertController(title: "インターネット未接続", message: "ネットワークの接続状態を確認してください。", preferredStyle: .alert)
                    alert.addAction(
                        UIAlertAction(
                            title: "OK",
                            style: .default
                        ))
                    self.present(alert, animated: true, completion: nil)
                }
            }
    }
    
    func menu(url: String) {
        if url == "" {
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .done, target: self, action: #selector(menuBarButtonItem(_:)))
            menuBarButtonItem.tintColor = .label
        } else {
            let Items = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "画像の変更", image: UIImage(systemName: "photo.on.rectangle.angled"), handler: { _ in self.openAlbum()}),
            ])
            let delete = UIAction(title: "画像を削除", attributes: .destructive, handler: { _ in self.deleteImage()})
            let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), options: .displayInline, children: [Items, delete])
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
            menuBarButtonItem.tintColor = .label
        }
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
    }
    
    @objc func menuBarButtonItem(_ sender: UIBarButtonItem) {
        openAlbum()
    }
}
