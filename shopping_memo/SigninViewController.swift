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
        setUpDataAndDelegate()
        UISetUp()
        menu()
        checkAppVer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        email = userDefaults.string(forKey: "email")
        if email != nil { emailTextField.text = email }
        auth = Auth.auth()
        if auth.currentUser != nil {
            let userId = auth.currentUser?.uid
            let email = auth.currentUser?.email
            ref.child("users").child(userId!).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
                let verified = (snapshot.childSnapshot(forPath: "verified").value as? Bool) ?? false
                if !verified {
                    self.userDefaults.set(email, forKey: "email")
                    self.performSegue(withIdentifier: "toMCVC", sender: nil)
                } else {
                    self.userDefaults.set(password, forKey: "password")
                    ref.child("users").child(userId!).child("metadata").observeSingleEvent(of: .value, with: { snapshot in
                        guard let userEmail = snapshot.childSnapshot(forPath: "email").value as? String else {
                            self.ref.child("users").child(userId!).child("metadata").updateChildValues(["email": email!])
                            self.performSegue(withIdentifier: "toRVC", sender: self.auth.currentUser)
                            return
                        }
                    })
                    performSegue(withIdentifier: "toRVC", sender: auth.currentUser)
                }
            })
        }
    }
    
    func UISetUp() {
        title = "ログイン"
        signInButton.layer.cornerRadius = 18.0
        signUpButton.layer.cornerRadius = 18.0
        
        appIconImage.layer.cornerRadius = 30.0
        appIconImage.layer.cornerCurve = .continuous
        appIconImage.layer.borderColor = UIColor.clear.cgColor
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:  "戻る", style:  .plain, target: nil, action: nil)
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(半角英数字)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
    }
    
    func setUpDataAndDelegate() {
        ref = Database.database().reference()
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {self.connect = true}
            else {self.connect = false}
        })
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    func checkAppVer() {
        let AppVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        appVersionLabel.text = "Version: " + AppVer!
        Task {
            let result = await AppVersionCheck.appVersionCheck()
            if result {
                DispatchQueue.main.async {
                    let url = URL(string: "https://itunes.apple.com/jp/app/apple-store/id6448711012")!
                    let alert: UIAlertController = UIAlertController(title: "古いバージョンです", message: "AppStoreから更新してください。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "更新する", style: .default, handler: { action in
                        UIApplication.shared.open(url, options: [:]) { success in
                            if success {print("成功!")}}}))
                    alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                    self.present(alert, animated: true, completion: nil)
                }
            }
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
        self.performSegue(withIdentifier: "toResetVC", sender: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        signIn()
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
            GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "signIn")
            auth.signIn(withEmail: email, password: password) { (authResult, error) in
                if error == nil, let result = authResult {
                    let userId = Auth.auth().currentUser?.uid
//                    self.ref.child("users").child(userId!).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
//                        let verified = (snapshot.childSnapshot(forPath: "verified").value as? Bool) ?? false
//                        if !verified {
//                            self.userDefaults.set(email, forKey: "email")
//                            self.performSegue(withIdentifier: "toMCVC", sender: result.user)
//                        } else {
                            self.userDefaults.set(email, forKey: "email")
                            self.userDefaults.set(password, forKey: "password")
                            GeneralPurpose.AIV(VC: self, view: self.view, status: "stop", session: "signIn")
                            self.performSegue(withIdentifier: "toRVC", sender: result.user)
                            self.passwordTextField.text = ""
//                        }
//                    })
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
        menuBarButtonItem.tintColor = .label
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
    }
}
