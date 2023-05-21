//
//  ResetViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/12/13.
//

import UIKit
import FirebaseAuth

class ResetViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var sendResetPasswordButton: UIButton!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var noteTextView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendResetPasswordButton.layer.cornerRadius = 10.0
        sendResetPasswordButton.layer.borderColor = UIColor.black.cgColor
        sendResetPasswordButton.layer.borderWidth = 2.0
        
        emailTextField.layer.cornerRadius = 6.0
        emailTextField.layer.borderColor = UIColor.label.cgColor
        emailTextField.layer.borderWidth = 2.0
        emailTextField.backgroundColor = UIColor.systemGray5
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])

        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        // Do any additional setup after loading the view.
        
        emailTextField.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func reset() {
        let email = emailTextField.text!
        if email.contains("@") {
            // @が含まれている時
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                
                if error == nil{
                    let alert: UIAlertController = UIAlertController(title: "送信完了", message: "再設定メールが送れました。", preferredStyle: .alert)
                    alert.addAction(
                        UIAlertAction(
                            title: "OK",
                            style: .default,
                            handler: { action in
                                // OK押した時の処理
                                self.dismiss(animated: true, completion: nil)
                            }
                        )
                    )
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
            func back() {
                self.dismiss(animated: true, completion: nil)
            }
            
        } else {
            if emailTextField.text == "" {
                let alert: UIAlertController = UIAlertController(title: "送信できません。", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
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
                // @が含まれていない時
                let alert: UIAlertController = UIAlertController(title: "エラー", message: "@が含まれていません。", preferredStyle: .alert)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let email = emailTextField.text!
        if email.contains("@") {
            // @が含まれている時
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                
                if error == nil{
                    let alert: UIAlertController = UIAlertController(title: "送信完了", message: "再設定メールが送れました。", preferredStyle: .alert)
                    alert.addAction(
                        UIAlertAction(
                            title: "OK",
                            style: .default,
                            handler: { action in
                                // OK押した時の処理
                                self.dismiss(animated: true, completion: nil)
                            }
                        )
                    )
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
            func back() {
                self.dismiss(animated: true, completion: nil)
            }
            
        } else {
            if emailTextField.text == "" {
                let alert: UIAlertController = UIAlertController(title: "送信できません。", message: "メールアドレスが入力されていません。", preferredStyle: .alert)
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
                // @が含まれていない時
                let alert: UIAlertController = UIAlertController(title: "エラー", message: "@が含まれていません。", preferredStyle: .alert)
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
        return true
    }
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

