//
//  DeleteViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/05/21.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class DeleteViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var passwordLabel: UILabel!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var connection: UIImageView!
    
    var email: String!
    var password: String!
    var auth: Auth!
    var ref: DatabaseReference!
    var userId: String!
    let userDefaults: UserDefaults = UserDefaults.standard
    var connect = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        email = userDefaults.string(forKey: "email")
        password = userDefaults.string(forKey: "password")
        
        emailLabel.text = " " + email
        passwordLabel.text = " " + password
        
        emailLabel.layer.cornerRadius = 6.0
        emailLabel.clipsToBounds = true
        passwordLabel.layer.cornerRadius = 6.0
        passwordLabel.clipsToBounds = true
        
        deleteButton.layer.cornerRadius = 10.0
        deleteButton.layer.cornerCurve = .continuous
        
        deleteButton.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        ref = Database.database().reference()
        
        userId = Auth.auth().currentUser?.uid
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connection.image = UIImage(systemName: "wifi")
                self.connect = true
            } else {
                self.connection.image = UIImage(systemName: "wifi.slash")
                self.connect = false
            }})
    }
    
    @IBAction func delete() {
        if connect {
            let alert: UIAlertController = UIAlertController(title: "アカウントを削除してもよろしいですか？", message: "この操作は取り消すことはできません。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "削除する",
                    style: .destructive,
                    handler: { action in
                        self.ref.child("users").child(self.userId).removeValue()
                        let user = Auth.auth().currentUser
                        user?.delete { error in
                            if let error = error {
                                print("error")
                            } else {
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                )
            )
            alert.addAction(
                UIAlertAction(
                    title: "キャンセル",
                    style: .cancel,
                    handler: { action in
                    }
                )
            )
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert: UIAlertController = UIAlertController(title: "アカウント削除不可", message: "インターネット未接続です。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default
                ))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func back() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        self.dismiss(animated: true, completion: nil)
    }
}
