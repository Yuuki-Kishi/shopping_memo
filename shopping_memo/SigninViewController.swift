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
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var nonSignInButton: UIButton!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var appIconImage: UIImageView!
    
    var auth: Auth!
    let userDefaults: UserDefaults = UserDefaults.standard
    var email: String!
    var password: String!
    var userId: String!
    var ref: DatabaseReference!
    var connect = false
    var menuBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ログイン"
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]

        signInButton.layer.cornerRadius = 18.0
        signInButton.layer.cornerCurve = .continuous
        signUpButton.layer.cornerRadius = 10.0
        
        appIconImage.layer.cornerRadius = 30.0
        appIconImage.layer.cornerCurve = .continuous
        appIconImage.layer.borderColor = UIColor.clear.cgColor
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:  "戻る", style:  .plain, target: nil, action: nil)
                
        let AppVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        appVersionLabel.text = "Version: " + AppVer!
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(半角英数字)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
                        
        ref = Database.database().reference()
        
        menu()
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
          if snapshot.value as? Bool ?? false {
              self.connect = true
          } else {
              self.connect = false
          }})
        
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
                
        emailTextField.text = email

        email = userDefaults.string(forKey: "email")
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        auth = Auth.auth()
        if auth.currentUser != nil {
            performSegue(withIdentifier: "toHomeVC", sender: auth.currentUser)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func signInBut() {
        signIn()
    }
    
    @IBAction func signUp() {
        self.performSegue(withIdentifier: "toSUVC", sender: nil)
    }
    
    @IBAction func resetPassWord() {
        self.performSegue(withIdentifier: "toRVC", sender: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturnが呼ばれました。")
        textField.resignFirstResponder()
        signIn()
        return true
    }
    
    func signIn() {
        let email = emailTextField.text!
        let password = passwordTextField.text!
        if emailTextField.text == "" {
            let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default
                ))
            self.present(alert, animated: true, completion: nil)
        } else if !connect {
            let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "インターネット未接続です。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default
                ))
            self.present(alert, animated: true, completion: nil)
        } else {
            auth.signIn(withEmail: email, password: password) { (authResult, error) in
                if error == nil, let result = authResult {
                    self.userDefaults.set(email, forKey: "email")
                    self.userDefaults.set(password, forKey: "password")
                    self.performSegue(withIdentifier: "toHomeVC", sender: result.user)
                    self.passwordTextField.text = ""
                } else {
                    print("error: \(error!)")
                    let errorCode = (error as? NSError)?.code
                    
                    if errorCode == 17008 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "メールアドレスが正しくありません。", preferredStyle: .alert)
                        alert.addAction(
                            UIAlertAction(
                                title: "OK",
                                style: .default
                            ))
                        self.present(alert, animated: true, completion: nil)
                    } else if errorCode == 17009 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "パスワードが正しくありません。", preferredStyle: .alert)
                        alert.addAction(
                            UIAlertAction(
                                title: "OK",
                                style: .default
                            ))
                        self.present(alert, animated: true, completion: nil)
                    } else if errorCode == 17011 {
                        let alert: UIAlertController = UIAlertController(title: "ログインできません", message: "アカウントが存在しません。", preferredStyle: .alert)
                        alert.addAction(
                            UIAlertAction(
                                title: "OK",
                                style: .default
                            ))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func menu() {
        let Item = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: "ログインしないで使う", image: UIImage(systemName: "list.bullet"), handler: { _ in
                self.performSegue(withIdentifier: "toNSVC", sender: nil)
        })])
        let delete = UIAction(title: "アカウント削除", image: UIImage(systemName: "person.badge.minus"), attributes: .destructive, handler: { _ in
            self.performSegue(withIdentifier: "toRLIVC", sender: nil)
        })
        let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), options: .displayInline, children: [Item, delete])
        menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
        menuBarButtonItem.tintColor = .black
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
    }
}
