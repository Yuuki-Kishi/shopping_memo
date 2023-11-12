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
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UISetUp()
        sendMail()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    func UISetUp() {
        title = "メール確認"
        iconImageView.layer.cornerRadius = 30.0
        iconImageView.layer.cornerCurve = .continuous
        sendButton.layer.cornerRadius = 18.0
    }
    
    @IBAction func send() {
        sendMail()
    }
    
    func sendMail() {
        GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "send")
        let email = userDefaults.string(forKey: "email")
        let actionCodeSettings = ActionCodeSettings() //メールリンクの作成方法をFirebaseに伝えるオブジェクト
        actionCodeSettings.handleCodeInApp = true //ログインをアプリ内で完結させる必要があります
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!) //iOSデバイス内でログインリンクを開くアプリのBundle ID
        //リンクURL
        var components = URLComponents()
        components.scheme = "https"
        components.host = "shoppingmemo.page.link" //Firebaseコンソールで作成したダイナミックリンクURLドメイン
        let queryItemEmailName = "email" //URLにemail情報(パラメータ)を追加する
        let emailTypeQueryItem = URLQueryItem(name: queryItemEmailName, value: email)
        components.queryItems = [emailTypeQueryItem]
        guard let linkParameter = components.url else { return }
        actionCodeSettings.url = linkParameter
        
        Auth.auth().sendSignInLink(toEmail: email!, actionCodeSettings: actionCodeSettings) { (err) in
            GeneralPurpose.AIV(VC: self, view: self.view, status: "stop", session: "send")
            if let err = err { print("送信失敗", err, email!); return }
            let alert = UIAlertController(title: "確認メールを送信しました", message: "確認メールのリンクをタップして確認してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
