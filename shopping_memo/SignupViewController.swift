//
//  SignupViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/12/13.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class SignupViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    private let minPasswordLength = 8
    var auth: Auth!
    
    let userDefaults: UserDefaults = UserDefaults.standard
    var imageCountInt: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.layer.cornerRadius = 6.0
        emailTextField.layer.borderColor = UIColor.label.cgColor
        emailTextField.layer.borderWidth = 2.0
        emailTextField.backgroundColor = UIColor.systemGray5
        
        passwordTextField.layer.cornerRadius = 6.0
        passwordTextField.layer.borderColor = UIColor.label.cgColor
        passwordTextField.layer.borderWidth = 2.0
        
        signUpButton.layer.cornerRadius = 10.0
        signUpButton.layer.borderColor = UIColor.black.cgColor
        signUpButton.layer.borderWidth = 2.0
        passwordTextField.backgroundColor = UIColor.systemGray5
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(半角英数字)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        imageCountInt = userDefaults.integer(forKey: "imageCount")
        
        emailTextField.delegate = self
        passwordTextField.delegate = self

    }
    
    override func viewDidAppear(_ animated: Bool) {
        auth = Auth.auth()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func signUp(_ sender: Any) {
        let email = emailTextField.text!
        let password = passwordTextField.text!
        
        if emailTextField.text == "" {
            let alert = UIAlertController(title: "新規登録できません。", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            }
            alert.addAction(ok)
            
        } else if passwordTextField.text == "" {
            let alert = UIAlertController(title: "新規登録できません。", message: "パスワードが入力されていません。", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            }
            alert.addAction(ok)
        } else if password.count < minPasswordLength || password.isAlphanumeric() == false {
            let alert = UIAlertController(title: "新規登録できません。", message: "パスワードは英数字で8文字以上です。", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            }
            alert.addAction(ok)
        }
        
        auth.createUser(withEmail: email, password: password) { (authResult, error) in
            let errorCode = (error as? NSError)?.code
            if error == nil, let result = authResult {
                self.userDefaults.set(email, forKey: "email")
                self.dismiss(animated: true, completion: nil)
                self.performSegue(withIdentifier: "toHomevc", sender: result.user)
                
            } else if errorCode == 17008{
                let alert: UIAlertController = UIAlertController(title: "新規登録できません。", message: "メールアドレスが正しくありません。", preferredStyle: .alert)
                alert.addAction(
                    UIAlertAction(
                        title: "OK",
                        style: .default,
                        handler: {action in
                        }
                    )
                )
                self.present(alert, animated: true, completion: nil)
                
            } else {
                print("error: \(error!)")
                print("error: \(error!)")
                let errorCode = (error as? NSError)?.code
                
                if errorCode == 17007 {
                    let alert: UIAlertController = UIAlertController(title: "そのメールアドレスは既に使われています。", message: "別のメールアドレスをお使いください。", preferredStyle: .alert)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let email = emailTextField.text!
        let password = passwordTextField.text!
        
        if emailTextField.text == "" {
            let alert = UIAlertController(title: "新規登録できません。", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            }
            alert.addAction(ok)
            
        } else if passwordTextField.text == "" {
            let alert = UIAlertController(title: "新規登録できません。", message: "パスワードが入力されていません。", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            }
            alert.addAction(ok)
        } else if password.count < minPasswordLength || password.isAlphanumeric() == false {
            let alert = UIAlertController(title: "新規登録できません。", message: "パスワードは英数字で8文字以上です。", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            }
            alert.addAction(ok)
        }
        
        auth.createUser(withEmail: email, password: password) { (authResult, error) in
            self.userDefaults.set(email, forKey: "email")
            let errorCode = (error as? NSError)?.code
            if error == nil, let result = authResult {
                self.dismiss(animated: true, completion: nil)
                self.performSegue(withIdentifier: "toHomevc", sender: result.user)
            } else if errorCode == 17008{
                let alert: UIAlertController = UIAlertController(title: "新規登録できません。", message: "メールアドレスが正しくありません。", preferredStyle: .alert)
                alert.addAction(
                    UIAlertAction(
                        title: "OK",
                        style: .default,
                        handler: {action in
                        }
                    )
                )
                self.present(alert, animated: true, completion: nil)
                
            } else {
                print("error: \(error!)")
                print("error: \(error!)")
                let errorCode = (error as? NSError)?.code
                
                if errorCode == 17007 {
                    let alert: UIAlertController = UIAlertController(title: "そのメールアドレスは既に使われています。", message: "別のメールアドレスをお使いください。", preferredStyle: .alert)
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
        return true
    }
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
extension String {
    
    // 半角数字とドットの判定
    
    func isAlphanumeric() -> Bool {
        
        return self.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil && self != ""
        
    }
    
}
