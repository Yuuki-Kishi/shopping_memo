//
//  MailCheckViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/24.
//

import UIKit
import FirebaseAuth

class MailCheckViewController: UIViewController {
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "メール確認"
        
        iconImageView.layer.cornerRadius = 30.0
        iconImageView.layer.cornerCurve = .continuous
        
        sendButton.layer.cornerRadius = 18.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(foreground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        sendMail()
    }
    
    @objc func foreground(notification: Notification) {
        Auth.auth().currentUser?.reload()
        let isEmailVerified = Auth.auth().currentUser?.isEmailVerified
        if isEmailVerified! {
            self.performSegue(withIdentifier: "toRVC", sender: nil)
        } else {
            let alert = UIAlertController(title: "メールが確認されていません。", message: "再送してやり直してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func send() {
        sendMail()
    }
    
    func sendMail() {
        Auth.auth().currentUser?.sendEmailVerification() { error in
            let alert = UIAlertController(title: "今確認メールを送信しました。", message: "メールのURLをタップしてメールアドレスを認証してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
