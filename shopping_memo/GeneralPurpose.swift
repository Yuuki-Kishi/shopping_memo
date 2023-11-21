//
//  GeneralPurpose.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/18.
//

import UIKit
import Foundation
import FirebaseAuth
import FirebaseDatabase

class GeneralPurpose {
    
    static let dateFormatter = DateFormatter()
    static let ref = Database.database().reference()
    static let AIV = UIActivityIndicatorView()

    static func notConnectAlert(VC: UIViewController) {
        let alert: UIAlertController = UIAlertController(title: "インターネット未接続", message: "ネットワークの接続状態を確認してください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        VC.present(alert, animated: true)
    }
    
    static func updateEditHistory(roomId: String) {
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let timeNow = dateFormatter.string(from: Date())
        let editor = Auth.auth().currentUser?.uid
        ref.child("rooms").child(roomId).child("info").updateChildValues(["lastEditTime": timeNow, "lastEditor": editor!])
    }
    
    static func AIV(VC: UIViewController, view: UIView, status: String, session: String) {
        if status == "start" {
            AIV.center = view.center
            AIV.style = .large
            AIV.color = .label
            view.addSubview(AIV)
            AIV.startAnimating()
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                if AIV.isAnimating && session != "other" {
                    AIV.stopAnimating()
                    switch session {
                    case "get":
                        let alert: UIAlertController = UIAlertController(title: "低速すぎるネットワーク", message: "情報を取得できませんでした。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        VC.present(alert, animated: true)
                    case "post":
                        let alert: UIAlertController = UIAlertController(title: "低速すぎるネットワーク", message: "情報をアップロードできませんでした。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        VC.present(alert, animated: true)
                    case "signIn":
                        let alert: UIAlertController = UIAlertController(title: "低速すぎるネットワーク", message: "ログインできませんでした。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        VC.present(alert, animated: true)
                    case "signUp":
                        let alert: UIAlertController = UIAlertController(title: "低速すぎるネットワーク", message: "新規登録できませんでした。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        VC.present(alert, animated: true)
                    case "signOut":
                        let alert: UIAlertController = UIAlertController(title: "低速すぎるネットワーク", message: "ログアウトできませんでした。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        VC.present(alert, animated: true)
                    case "send":
                        let alert: UIAlertController = UIAlertController(title: "低速すぎるネットワーク", message: "メールを送信できませんでした。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        VC.present(alert, animated: true)
                    default:
                        break
                    }
                }
            }
        } else if status == "stop" {
            AIV.stopAnimating()
        }
    }
    
    static func noItemLabel(view: UIView) {
        let titleLabel = UILabel() // ラベルの生成
        titleLabel.frame = CGRect(x: 0, y: 100, width: UIScreen.main.bounds.size.width, height: 44) // 位置とサイズの指定
        titleLabel.textAlignment = NSTextAlignment.center // 横揃えの設定
        titleLabel.text = "表示できる項目がありません" // テキストの設定
        titleLabel.textColor = UIColor.label // テキストカラーの設定
        view.addSubview(titleLabel) // ラベルの追加
    }
}
