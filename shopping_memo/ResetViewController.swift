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
        UISetUp()
        setUpDataAndDelegate()
    }
    
    func UISetUp() {
        title = "パスワード再設定"
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
        sendResetPasswordButton.layer.cornerRadius = 18.0
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
    }
    
    func setUpDataAndDelegate() {
        emailTextField.text = ud.string(forKey: "email")
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }
        })
        emailTextField.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func PWReset() {
        let email = emailTextField.text!
        if connect {
            if email.contains("@") {
                GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "send")
                // @が含まれている時
                Auth.auth().sendPasswordReset(withEmail: email) { error in
                    GeneralPurpose.AIV(VC: self, view: self.view, status: "stop", session: "send")
                    if error == nil{
                        let alert: UIAlertController = UIAlertController(title: "送信完了", message: "再設定メールが送れました。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            // OK押した時の処理
                            self.navigationController?.popViewController(animated: true)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        let alert: UIAlertController = UIAlertController(title: "エラー", message: "再設定メールを送信できませんでした。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                if emailTextField.text == "" {
                    let alert: UIAlertController = UIAlertController(title: "送信できません", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    // @が含まれていない時
                    let alert: UIAlertController = UIAlertController(title: "送信できません", message: "@が含まれていません。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction( title: "OK", style: .default))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        PWReset()
        return true
    }
    
    @IBAction func reset() {
        PWReset()
    }
}

