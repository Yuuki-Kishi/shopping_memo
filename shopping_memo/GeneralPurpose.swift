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
}
