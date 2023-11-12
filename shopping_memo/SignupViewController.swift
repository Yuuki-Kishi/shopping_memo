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
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordCheckTextField: UITextField!
    @IBOutlet weak var appIconImage: UIImageView!
    private let minPasswordLength = 8
    var auth: Auth!
    var connect = false
    
    let userDefaults: UserDefaults = UserDefaults.standard
    var imageCountInt: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UISetUp()
        setUpDataAndDelegate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        auth = Auth.auth()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func UISetUp() {
        title = "新規登録"
        signUpButton.layer.cornerRadius = 18.0
        appIconImage.layer.cornerRadius = 30.0
        appIconImage.layer.cornerCurve = .continuous
                
        userNameTextField.attributedPlaceholder = NSAttributedString(string: "ユーザーネーム",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(半角英数字)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        passwordCheckTextField.attributedPlaceholder = NSAttributedString(string: "パスワード(確認)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
    }
    
    func setUpDataAndDelegate() {
        imageCountInt = userDefaults.integer(forKey: "imageCount")
        emailTextField.delegate = self
        passwordTextField.delegate = self
        passwordCheckTextField.delegate = self
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }
        })
    }
    
    @IBAction func signUp(_ sender: Any) {
        createAccount()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        createAccount()
        return true
    }
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createAccount() {
        let userName = userNameTextField.text!
        let email = emailTextField.text!
        let password = passwordTextField.text!
        if emailTextField.text == "" {
            let alert = UIAlertController(title: "新規登録できません", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        } else if passwordTextField.text == "" {
            let alert = UIAlertController(title: "新規登録できません", message: "パスワードが入力されていません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        } else if userNameTextField.text == "" {
            let alert = UIAlertController(title: "新規登録できません", message: "ユーザーネームが入力されいません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        } else if password.count < minPasswordLength || password.isAlphanumeric() == false {
            let alert = UIAlertController(title: "新規登録できません", message: "パスワードは英数字で8文字以上です。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        } else if !connect {
            GeneralPurpose.notConnectAlert(VC: self)
        } else {
            GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "signUp")
            auth.createUser(withEmail: email, password: password) { (authResult, error) in
                self.userDefaults.set(email, forKey: "email")
                let errorCode = (error as? NSError)?.code
                if error == nil {
                    self.userDefaults.set(userName, forKey: "userName")
                    GeneralPurpose.AIV(VC: self, view: self.view, status: "stop", session: "signUp")
                    self.performSegue(withIdentifier: "toMCVC", sender: nil)
                } else if errorCode == 17008{
                    let alert: UIAlertController = UIAlertController(title: "新規登録できません", message: "メールアドレスが正しくありません。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    print("error: \(error!)")
                    let errorCode = (error as? NSError)?.code
                    if errorCode == 17007 {
                        let alert: UIAlertController = UIAlertController(title: "そのメールアドレスは既に使われています", message: "別のメールアドレスをお使いください。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
extension String {
    // 半角数字とドットの判定
    func isAlphanumeric() -> Bool {
        return self.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil && self != ""
    }
}
