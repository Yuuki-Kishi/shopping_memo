//
//  ReLogInViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/05/21.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ReLogInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    
    var userDefaults: UserDefaults = UserDefaults.standard
    var auth: Auth!
    var ref: DatabaseReference!
    var connect = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "再度ログイン"
        UISetUp()
        
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
          }})
    }
    override func viewDidAppear(_ animated: Bool) {
        auth = Auth.auth()
    }
    
    func UISetUp() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:  "戻る", style:  .plain, target: nil, action: nil)
        signInButton.layer.cornerRadius = 18.0
        signInButton.layer.cornerCurve = .continuous
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(半角英数字)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func signInBut() {
        if connect {
            signIn()
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturnが呼ばれました。")
        textField.resignFirstResponder()
        if connect {
            signIn()
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
        return true
    }
    
    func signIn() {
        let email = emailTextField.text!
        let password = passwordTextField.text!
        if emailTextField.text == "" {
            let alert: UIAlertController = UIAlertController(title: "ログインできません。", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                    }
                )
            )
            self.present(alert, animated: true, completion: nil)
        } else if !connect {
            let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "インターネット未接続です。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                    }))
            self.present(alert, animated: true, completion: nil)
        } else {
            auth.signIn(withEmail: email, password: password) { (authResult, error) in
                if error == nil, let result = authResult {
                    self.userDefaults.set(email, forKey: "email")
                    self.userDefaults.set(password, forKey: "password")
                    self.performSegue(withIdentifier: "toDVC", sender: result.user)
                    self.passwordTextField.text = ""
                } else {
                    print("error: \(error!)")
                    let errorCode = (error as? NSError)?.code
                    
                    if errorCode == 17008 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません。", message: "メールアドレスが正しくありません。", preferredStyle: .alert)
                        alert.addAction(
                            UIAlertAction(
                                title: "OK",
                                style: .default,
                                handler: { action in
                                }
                            )
                        )
                        self.present(alert, animated: true, completion: nil)
                    } else if errorCode == 17009 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません。", message: "パスワードが正しくありません。", preferredStyle: .alert)
                        alert.addAction(
                            UIAlertAction(
                                title: "OK",
                                style: .default,
                                handler: { action in
                                }
                            )
                        )
                        self.present(alert, animated: true, completion: nil)
                        
                    } else if errorCode == 17011 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません。", message: "アカウントが存在しません。", preferredStyle: .alert)
                        alert.addAction(
                            UIAlertAction(
                                title: "OK",
                                style: .default,
                                handler: { action in
                                    
                                }
                            )
                        )
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }
}
