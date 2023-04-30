//
//  SigninViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/12/13.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class SigninViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var listSelectButton: UIButton!
    var auth: Auth!
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    var imageCountInt: Int!
    
    var email: String!
    var userId: String!
    
    var listNumber: Int!
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.layer.cornerRadius = 6.0
        emailTextField.layer.borderColor = UIColor.black.cgColor
        emailTextField.layer.borderWidth = 2.0
        
        passwordTextField.layer.cornerRadius = 6.0
        passwordTextField.layer.borderColor = UIColor.black.cgColor
        passwordTextField.layer.borderWidth = 2.0
        
        signInButton.layer.cornerRadius = 10.0
        signInButton.layer.borderColor = UIColor.black.cgColor
        signInButton.layer.borderWidth = 2.0
        
        signUpButton.layer.cornerRadius = 10.0
        signUpButton.layer.borderColor = UIColor.black.cgColor
        signUpButton.layer.borderWidth = 1.0
        
//        listSelectButton.imageView?.contentMode = .scaleAspectFit
//        listSelectButton.contentHorizontalAlignment = .fill
//        listSelectButton.contentVerticalAlignment = .fill
        imageCountInt = 1
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(半角英数字)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        
        imageCountInt = userDefaults.integer(forKey: "imageCount")
        
        ref = Database.database().reference()
        
//        if imageCountInt == 0 {
//            let image = UIImage(systemName: "square.grid.2x2")
//            self.listSelectButton.setImage(image, for: .normal)
//            listSelectButton.tintColor = .black
//        } else {
//            let image = UIImage(systemName: "list.bullet")
//            self.listSelectButton.setImage(image, for: .normal)
//            listSelectButton.tintColor = .black
//
//        }
        
        print("imageCount:", imageCountInt!)
        
        email = userDefaults.string(forKey: "email")
        
        if email != nil {
            emailTextField.text = email
        }
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        auth = Auth.auth()
        if auth.currentUser != nil {
            performSegue(withIdentifier: "toHomevc1", sender: auth.currentUser)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    @IBAction func listSelect(_ sender: Any) {
        print("listSelectがtapされました")
        imageCountInt = userDefaults.integer(forKey: "imageCount")
        if imageCountInt == 0 {
            let image = UIImage(systemName: "list.bullet")
            listSelectButton.setImage(image, for: .normal)
            imageCountInt = 1
            print("imageCount:", imageCountInt!)
            userDefaults.set(imageCountInt, forKey: "imageCount")
        } else {
            let image = UIImage(systemName: "square.grid.2x2")
            listSelectButton.setImage(image, for: .normal)
            imageCountInt = 0
            print("imageCount:", imageCountInt!)
            userDefaults.set(imageCountInt, forKey: "imageCount")
        }
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
                    self.performSegue(withIdentifier: "toHomevc1", sender: result.user)
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
                    
                    if self.imageCountInt == 0 {
                        if self.auth.currentUser != nil {
                            self.performSegue(withIdentifier: "toHomevc0", sender: result.user)
                        }
                    } else {
                        if self.auth.currentUser != nil {
                            self.performSegue(withIdentifier: "toHomevc1", sender: result.user)
                        }
                    }
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
        return true
    }
    
}
