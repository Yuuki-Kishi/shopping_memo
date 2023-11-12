//
//  CameraViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/11/08.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var reTakeButton: UIButton!
    
    var userId: String!
    var roomIdString: String!
    var listIdString: String!
    var memoIdString: String!
    var shoppingMemoName: String!
    var imageRef: StorageReference!
    var ref: DatabaseReference!
    let df = DateFormatter()
    let storage = Storage.storage()
    var connect = false
    var uploadBarButtonItem: UIBarButtonItem!
    var reTakeBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "画像を撮影"
        
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        setUpUI()
        
        uploadBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "icloud.and.arrow.up"), style: .done, target: self, action: #selector(uploadBarButtonItem(_:)))
        uploadBarButtonItem.tintColor = .label
        navigationItem.rightBarButtonItem = uploadBarButtonItem
        
        openCamera()
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }})
    }
    
    func setUpUI() {
        imageView.contentMode = .center
        imageView.image = UIImage(systemName: "photo")
        imageView.preferredSymbolConfiguration = .init(pointSize: 100)
        imageView.tintColor = UIColor.label
        
        reTakeButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        reTakeButton.layer.cornerRadius = 35.0
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.contentMode = .scaleAspectFit
        imageView.image = info[.originalImage] as? UIImage
        dismiss(animated: true, completion: nil)
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            present(imagePicker, animated: true)
        }
    }
    
    @objc func uploadBarButtonItem(_ sender: UIBarButtonItem) {
        if connect {
            guard let image = imageView.image else { return }
            if image == UIImage(systemName: "photo") {
                let alert: UIAlertController = UIAlertController(title: "アップロードできません", message: "アップロードする画像を撮影してください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            } else {
                GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "post")
                guard let imageData = image.jpegData(compressionQuality: 0.3) else { return }
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
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
    
    @IBAction func reTake() {
        openCamera()
    }
}
