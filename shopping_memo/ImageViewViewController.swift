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
    @IBOutlet var upDateLabel: UILabel!
    
    var userId: String!
    var roomIdString: String!
    var listIdString: String!
    var memoIdString: String!
    var shoppingMemoName: String!
    var imageUrlString: String!
    var imageRef: StorageReference!
    var ref: DatabaseReference!
    let df = DateFormatter()
    let storage = Storage.storage()
    var connect = false
    var menuBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UISetUp()
        setUpData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observeRealtimeDatabase()
    }
    
    func UISetUp() {
        title = shoppingMemoName
        upDateLabel.layer.cornerRadius = 5.0
        upDateLabel.clipsToBounds = true
        upDateLabel.layer.cornerCurve = .continuous
        upDateLabel.adjustsFontSizeToFitWidth = true
    }
    
    func setUpData() {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }
        })
    }
    
    func observeRealtimeDatabase() {
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").child(memoIdString).child("imageUrl").observeSingleEvent(of: .value, with:  { [self] snapshot in
            GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "get")
            if snapshot.value == nil {
                return
            }
            guard let url = snapshot.value as? String else { return }
            menu(url: url)
            if url == "" {
                imageView.contentMode = .center
                imageView.image = UIImage(systemName: "photo")
                imageView.preferredSymbolConfiguration = .init(pointSize: 100)
                imageView.tintColor = UIColor.label
                upDateLabel.text = " 最終更新日時:"
            } else {
                imageRef = storage.reference(forURL: url)
                imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        let image = UIImage(data: data!)
                        self.imageView.contentMode = .scaleAspectFit
                        GeneralPurpose.AIV(VC: self, view: self.view, status: "stop", session: "get")
                        self.imageView.image = image
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
        
        ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").observe(.childChanged, with: { [self] snapshot in
            GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "get")
            guard let url = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
            menu(url: url)
            if url == "" {
                imageView.contentMode = .center
                imageView.preferredSymbolConfiguration = .init(pointSize: 100)
                GeneralPurpose.AIV(VC: self, view: view, status: "stop", session: "get")
                imageView.image = UIImage(systemName: "photo")
                imageView.tintColor = UIColor.label
                upDateLabel.text = " 最終更新日時:"
            } else {
                imageRef = storage.reference(forURL: url)
                imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        let image = UIImage(data: data!)
                        self.imageView.contentMode = .scaleAspectFit
                        GeneralPurpose.AIV(VC: self, view: self.view, status: "stop", session: "get")
                        self.imageView.image = image
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
        
        ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").observe(.childRemoved, with: { snapshot in
            let memoId = snapshot.key
            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return }
            if memoId == self.memoIdString { self.title = shoppingMemo }
        })
        
        ref.child("rooms").observe(.childRemoved, with:  { [self] snapshot in
            let roomId = snapshot.key
            if roomId == roomIdString {
                let alert: UIAlertController = UIAlertController(title: "ルームが削除されました", message: "詳しくはルームの管理者にお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    let viewControllers = self.navigationController?.viewControllers
                    self.navigationController?.popToViewController(viewControllers![viewControllers!.count - 4], animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
        
        ref.child("rooms").child(roomIdString).child("lists").observe(.childRemoved, with: { snapshot in
            let listId = snapshot.key
            if listId == self.listIdString {
                let alert: UIAlertController = UIAlertController(title: "リストが削除されました", message: "詳しくはリストを削除したメンバーにお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    let viewControllers = self.navigationController?.viewControllers
                    self.navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
        
        ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").observe(.childRemoved, with: { [self] snapshot in
            let memoId = snapshot.key
            if memoId == memoIdString {
                let alert: UIAlertController = UIAlertController(title: "「" + self.shoppingMemoName + "」が削除されました", message: "詳しくは削除したメンバーにお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
        
        ref.child("rooms").child(roomIdString).child("members").observe(.childRemoved, with: { snapshot in
            let userId = snapshot.key
            if userId == self.userId {
                let alert: UIAlertController = UIAlertController(title: "ルームを追放されました", message: "詳しくはルームの管理者にお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    let viewControllers = self.navigationController?.viewControllers
                    self.navigationController?.popToViewController(viewControllers![viewControllers!.count - 4], animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //.originalImageにするとトリミングなしになる
        guard let image = info[.originalImage] as? UIImage else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.3) /*as? UIImage*/ else { return }
        guard let uid = userId else { return }
        guard let roomId = roomIdString else { return }
        guard let listId = listIdString else { return }
        guard let memoId = memoIdString else { return }
        let imageRef = Storage.storage().reference().child("/\(uid)/\(roomId)/\(listId)/\(memoId).jpg")
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print(error)
            } else {
                imageRef.downloadURL { (url, error) in
                    guard let downloadURL = url else { return }
                    let imageUrl = downloadURL.absoluteString
                    self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).updateChildValues(["imageUrl": imageUrl])
                    GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
                }
            }
        }
        imageView.image = nil
        dismiss(animated: true, completion: nil)
    }
    
    func openAlbum() {
        if connect {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "other")
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                GeneralPurpose.AIV(VC: self, view: view, status: "stop", session: "other")
                present(picker, animated: true, completion: nil)
            }
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
    
    func deleteImage() {
        guard let uid = userId else { return }
        guard let roomId = roomIdString else { return }
        guard let listId = listIdString else { return }
        guard let memoId = memoIdString else { return }
        let imageRef = Storage.storage().reference().child("/\(uid)/\(roomId)/\(listId)/\(memoId).jpg")
        if imageView.image == UIImage(systemName: "photo") {
            let alert: UIAlertController = UIAlertController(title: "削除できません", message: "削除できる画像がありません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        } else {
            if connect {
                let alert: UIAlertController = UIAlertController(title: "画像を削除", message: "画像を削除してもよろしいですか。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "削除", style: .destructive, handler: { action in
                    GeneralPurpose.AIV(VC: self, view: self.view, status: "start", session: "other")
                    imageRef.delete { error in
                        if let error = error {
                            print(error)
                        } else {
                            self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).updateChildValues(["imageUrl": ""])
                            GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
                            self.imageView.contentMode = .center
                            self.imageView.preferredSymbolConfiguration = .init(pointSize: 100)
                            self.imageView.image = UIImage(systemName: "photo")
                            self.imageView.tintColor = UIColor.label
                            self.upDateLabel.text = " 最終更新日時:"
                        }}}))
                alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                self.present(alert, animated: true, completion: nil)
            } else {
                GeneralPurpose.notConnectAlert(VC: self)
            }
        }
    }
    
    func menu(url: String) {
        let plus = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: "アルバムから追加", image: UIImage(systemName: "photo.stack"), handler: { _ in self.openAlbum()}),
            UIAction(title: "画像を撮影", image: UIImage(systemName: "camera"), handler: { _ in
                self.performSegue(withIdentifier: "toCVC", sender: nil)
            })
        ])
        let Items = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: "画像の変更", image: UIImage(systemName: "photo.on.rectangle.angled"), handler: { _ in self.openAlbum()}),
            UIAction(title: "画像を撮影", image: UIImage(systemName: "camera"), handler: { _ in
                self.performSegue(withIdentifier: "toCVC", sender: nil)
            }),
            UIAction(title: "画像をダウンロード", image: UIImage(systemName: "arrow.down.to.line.compact"), handler: { _ in
                UIImageWriteToSavedPhotosAlbum(self.imageView.image!, nil, nil, nil)
                let alert: UIAlertController = UIAlertController(title: "ダウンロード完了", message: "アルバムを確認してください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            })
        ])
        let delete = UIAction(title: "画像を削除", attributes: .destructive, handler: { _ in self.deleteImage()})
        
        if url == "" {
            let menu = UIMenu(title: "", image: UIImage(systemName: "plus.viewfinder"), children: [plus])
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.viewfinder"), menu: menu)
            menuBarButtonItem.tintColor = .label
        } else {
            let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), options: .displayInline, children: [Items, delete])
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
            menuBarButtonItem.tintColor = .label
        }
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCVC" {
            let next = segue.destination as? CameraViewController
            next?.roomIdString = roomIdString
            next?.listIdString = listIdString
            next?.memoIdString = memoIdString
            next?.shoppingMemoName = shoppingMemoName
        }
    }
}
