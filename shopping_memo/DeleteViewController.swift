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

    var email: String!
    var password: String!
    var auth: Auth!
    var ref: DatabaseReference!
    var deleteAccount = false

    let userDefaults: UserDefaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        email = userDefaults.string(forKey: "email")
        password = userDefaults.string(forKey: "password")
        
        emailLabel.layer.cornerRadius = 6.0
        emailLabel.layer.borderColor = UIColor.label.cgColor
        emailLabel.layer.borderWidth = 2.0
        emailLabel.text = email
        
        passwordLabel.layer.cornerRadius = 6.0
        passwordLabel.layer.borderColor = UIColor.label.cgColor
        passwordLabel.layer.borderWidth = 2.0
        passwordLabel.text = password
        
        deleteButton.layer.cornerRadius = 10.0
        deleteButton.layer.borderColor = UIColor.systemRed.cgColor
        deleteButton.layer.borderWidth = 2.0
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        ref = Database.database().reference()
    }

    @IBAction func delete() {
        let alert: UIAlertController = UIAlertController(title: "アカウントを削除してもよろしいですか？", message: "この操作は取り消すことはできません。", preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: "削除する",
                style: .destructive,
                handler: { action in
                    let user = Auth.auth().currentUser
                    user?.delete { error in
                        if let error = error {
                            print("error")
                        } else {
                            self.userDefaults.set(self.deleteAccount, forKey: "deleteAccount")
//                            self.performSegue(withIdentifier: "toSigninVC", sender: nil)
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
