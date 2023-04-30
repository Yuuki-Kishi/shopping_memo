//
//  MakeNewMemofileViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2021/01/10.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class MakeNewMemofileViewController: UIViewController, UITextFieldDelegate {
    
    var userId: String!
    @IBOutlet weak var makeNewMemoButton: UIButton!
    @IBOutlet var textField: UITextField!
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    var listCountInt: Int!
    
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listCountInt = userDefaults.integer(forKey: "listCount")
        print("userDefaults:", userDefaults.integer(forKey: "listCount"))
        
        textField.layer.cornerRadius = 6.0
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 2.0
        makeNewMemoButton.layer.cornerRadius = 10.0
        makeNewMemoButton.layer.borderColor = UIColor.black.cgColor
        makeNewMemoButton.layer.borderWidth = 2.0
        
        textField.attributedPlaceholder = NSAttributedString(string: "新しいメモの名前",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        
        textField.delegate = self
        
        userId = Auth.auth().currentUser?.uid
        
        ref = Database.database().reference()
        // Do any additional setup after loading the view.
        
    }
    
    
    @IBAction func MakeNewMemo(_ sender: Any) {
        
        if textField.text == "" {
            let aleat: UIAlertController = UIAlertController(title: "新規作成できません", message: "リストのタイトルが指定されていません", preferredStyle: .alert)
            aleat.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        print("OKボタンが押されました")
                    }
                )
            )
            present(aleat, animated: true, completion: nil)
            
        } else {
            let text = textField.text!
            let checked = ["チェック済み": text]
            let nonCheck = ["未チェック": text]
            
            let data = ["\(text)": text]
            
            self.ref.child("users").child(userId).child("list\(listCountInt!)").updateChildValues(["name": text, "未チェック": text, "チェック済": text])
            
            //        self.ref.child("users").child(userId).updateChildValues(data)
            
            print("追加なりけり")
            
            listCountInt += 1
            userDefaults.set(listCountInt, forKey: "listCount")
            
            //        ref.child("users").child(userId).observe(.childAdded, with: { snapshot in
            //            let dataId = snapshot.key
            //
            //            self.ref.child("users").child(self.userId).child(dataId).updateChildValues(checked)
            //            self.ref.child("users").child(self.userId).child(dataId).updateChildValues(nonCheck)
            //
            //            print("dataId:",dataId)
            //        })
            
            textField.text = ""
            
            self.dismiss(animated: true, completion:  nil)
            self.performSegue(withIdentifier: "toNewmemoViewController", sender: nil)
            
        }
    }
    
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
