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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        emailTextField.layer.cornerRadius = 6.0
        emailTextField.layer.borderColor = UIColor.label.cgColor
        emailTextField.layer.borderWidth = 2.0
        emailTextField.backgroundColor = .systemGray5
        emailTextField.text = userDefaults.string(forKey: "email")
        
        passwordTextField.layer.cornerRadius = 6.0
        passwordTextField.layer.borderColor = UIColor.label.cgColor
        passwordTextField.layer.borderWidth = 2.0
        passwordTextField.backgroundColor = .systemGray5
        
        signInButton.layer.cornerRadius = 10.0
        signInButton.layer.borderColor = UIColor.black.cgColor
        signInButton.layer.borderWidth = 2.0
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))

        ref = Database.database().reference()
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(半角英数字)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        
    }
    override func viewDidAppear(_ animated: Bool) {
        auth = Auth.auth()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func signIn() {
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
        } else {
            auth.signIn(withEmail: email, password: password) { (authResult, error) in
                if error == nil, let result = authResult {
                    self.userDefaults.set(email, forKey: "email")
                    self.userDefaults.set(password, forKey: "password")
                    self.performSegue(withIdentifier: "toDeleteVC", sender: result.user)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturnが呼ばれました。")
        textField.resignFirstResponder()
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
        } else {
            auth.signIn(withEmail: email, password: password) { (authResult, error) in
                if error == nil, let result = authResult {
                    self.userDefaults.set(email, forKey: "email")
                    self.userDefaults.set(password, forKey: "password")
                    self.performSegue(withIdentifier: "toDeleteVC", sender: result.user)
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
        return true
    }
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }
}
