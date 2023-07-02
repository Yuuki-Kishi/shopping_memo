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
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var nonSignInButton: UIButton!
    @IBOutlet weak var appVersionLabel: UILabel!
    var auth: Auth!
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    var imageCountInt: Int!
    
    var email: String!
    var password: String!
    var userId: String!
    
    var listNumber: Int!
    var ref: DatabaseReference!
    
    var deleteAccount = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.layer.cornerRadius = 6.0
        emailTextField.layer.borderColor = UIColor.label.cgColor
        emailTextField.layer.borderWidth = 2.0
        emailTextField.backgroundColor = UIColor.systemGray5
        
        passwordTextField.layer.cornerRadius = 6.0
        passwordTextField.layer.borderColor = UIColor.label.cgColor
        passwordTextField.layer.borderWidth = 2.0
        passwordTextField.backgroundColor = UIColor.systemGray5
        
        signInButton.layer.cornerRadius = 10.0
        signInButton.layer.borderColor = UIColor.black.cgColor
        signInButton.layer.borderWidth = 2.0
        
        signUpButton.layer.cornerRadius = 10.0
        signUpButton.layer.borderColor = UIColor.black.cgColor
        signUpButton.layer.borderWidth = 1.0
        
        nonSignInButton.layer.cornerRadius = 10.0
        nonSignInButton.layer.borderColor = UIColor.black.cgColor
        nonSignInButton.layer.borderWidth = 1.0
        
        deleteButton.layer.cornerRadius = 10.0
        deleteButton.layer.borderColor = UIColor.systemRed.cgColor
        deleteButton.layer.borderWidth = 1.0
        
        //        listSelectButton.imageView?.contentMode = .scaleAspectFit
        //        listSelectButton.contentHorizontalAlignment = .fill
        //        listSelectButton.contentVerticalAlignment = .fill
        imageCountInt = 1
        
        let AppVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        appVersionLabel.text = "Version: " + AppVer!
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(半角英数字)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        imageCountInt = userDefaults.integer(forKey: "imageCount")
        
        ref = Database.database().reference()
        
        Task {
            let result = await AppVersionCheck.appVersionCheck()
            
            print("result:", AppVersionCheck.result)
            if result {
                DispatchQueue.main.async {
                    let url = URL(string: "https://itunes.apple.com/jp/app/apple-store/id6448711012")!
                    let alert: UIAlertController = UIAlertController(title: "最新バージョンではありません。", message: "AppStoreから更新してください。", preferredStyle: .alert)
                    alert.addAction(
                        UIAlertAction(
                            title: "更新する",
                            style: .default,
                            handler: { action in
                                UIApplication.shared.open(url, options: [:]) { success in
                                    if success {
                                        print("成功!")
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
            }
            print("result2:", AppVersionCheck.result)
        }
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
            performSegue(withIdentifier: "toHomevc", sender: auth.currentUser)
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
                    self.userDefaults.set(password, forKey: "password")
                    self.performSegue(withIdentifier: "toHomevc", sender: result.user)
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
                    self.performSegue(withIdentifier: "toHomevc", sender: result.user)
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


extension UIColor {
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { (traitCollection:UITraitCollection) -> UIColor in
            if traitCollection.userInterfaceStyle == .dark {
                return dark
            } else {
                return light
            }
        }
    }
}
