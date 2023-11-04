//
//  ResetViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/12/13.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ResetViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var sendResetPasswordButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    
    let ud: UserDefaults = UserDefaults.standard
    var connect = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "パスワード再設定"
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        sendResetPasswordButton.layer.cornerRadius = 18.0
        
        emailTextField.text = ud.string(forKey: "email")
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }})
        
        emailTextField.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func reset() {
        let email = emailTextField.text!
        if connect {
            if email.contains("@") {
                // @が含まれている時
                Auth.auth().sendPasswordReset(withEmail: email) { error in
                    if error == nil{
                        let alert: UIAlertController = UIAlertController(title: "送信完了", message: "再設定メールが送れました。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            // OK押した時の処理
                            self.navigationController?.popViewController(animated: true)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        let alert: UIAlertController = UIAlertController(title: "送信不可", message: "インターネット未接続です。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                if emailTextField.text == "" {
                    let alert: UIAlertController = UIAlertController(title: "送信できません。", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    // @が含まれていない時
                    let alert: UIAlertController = UIAlertController(title: "エラー", message: "@が含まれていません。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction( title: "OK", style: .default))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            let alert: UIAlertController = UIAlertController(title: "インターネット未接続", message: "ネットワークの接続状態を確認してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let email = emailTextField.text!
        if email.contains("@") {
            // @が含まれている時
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if error == nil{
                    let alert: UIAlertController = UIAlertController(title: "送信完了", message: "再設定メールが送れました。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        // OK押した時の処理
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            if emailTextField.text == "" {
                let alert: UIAlertController = UIAlertController(title: "送信できません。", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            } else {
                // @が含まれていない時
                let alert: UIAlertController = UIAlertController(title: "エラー", message: "@が含まれていません。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            }
        }
        return true
    }
}

