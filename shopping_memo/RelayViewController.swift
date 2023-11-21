//
//  RelayViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/11/20.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class RelayViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    
    var userDefaults: UserDefaults = UserDefaults.standard
    var ref: DatabaseReference!
    var connect = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UISetUp()
        setUpDataAndDelegate()
    }
    
    func UISetUp() {
        title = "アカウント引き継ぎ"
        signInButton.layer.cornerRadius = 18.0
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(半角英数字)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
    }
    
    func setUpDataAndDelegate() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        emailTextField.text = userDefaults.string(forKey: "email")
        ref = Database.database().reference()
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func signInBut() {
        if connect {
            signIn()
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if connect {
            signIn()
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
        return true
    }
    
    func signIn() {
        let email = emailTextField.text!
        let password = passwordTextField.text!
        if emailTextField.text == "" {
            let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        } else if !connect {
            GeneralPurpose.notConnectAlert(VC: self)
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
                if error == nil, let result = authResult {
                    self.userDefaults.set(result.user.uid, forKey: "userId")
                    let alert: UIAlertController = UIAlertController(title: "引き継ぎ準備が完了しました", message: "即座に新しいアカウントでログインしてください。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        let firebaseAuth = Auth.auth()
                        firebaseAuth.currentUser?.delete { error in
                            if let error = error {
                                print("error")
                            } else {
                                print("succeed")
                            }
                        }
                        do {
                            try firebaseAuth.signOut()
                        } catch let signOutError as NSError {
                            print ("Error signing out: %@", signOutError)
                        }
                        self.navigationController?.popToRootViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    print("error: \(error!)")
                    let errorCode = (error as? NSError)?.code
                    if errorCode == 17008 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "メールアドレスが正しくありません。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    } else if errorCode == 17009 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "パスワードが正しくありません。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    } else if errorCode == 17011 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "アカウントが存在しません。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
