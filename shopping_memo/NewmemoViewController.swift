//
//  NewmemoViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/12/14.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class NewmemoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var TextField: UITextField!
    
    @IBOutlet var signOutButton: UIButton!

    let dateFormatter = DateFormatter()

    var listNameText: String!
    var nonCheckSwitch: Bool!
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    var listArray = [String]()
    var keyArray = [String]()
    
    var deleteAccount = false
    
    var ref: DatabaseReference!
    
    var userId: String!
    
    var list: String!
    
    var name: String!
    
    //    var dict: [String : String] = ["":""]
    
    var value: String!
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var plusButton: UIButton!
    
    var listCountInt: Int!
    var memoNumber = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listCountInt = userDefaults.integer(forKey: "listCount")
        nonCheckSwitch = userDefaults.bool(forKey: "nonCheckSwitch")
        
        tableView.register(UINib(nibName: "CustomListCell", bundle: nil), forCellReuseIdentifier: "CustomListCell")
        
        //        tableView.frame = CGRect(x: 0, y: 10, width: 408, height: 60)
        
        
        plusButton.imageView?.contentMode = .scaleAspectFit
        plusButton.contentHorizontalAlignment = .fill
        plusButton.contentVerticalAlignment = .fill
        
        let image = UIImage(systemName: "plus")
        plusButton.setImage(image, for: .normal)
        plusButton.tintColor = UIColor.black

        plusButton.layer.cornerRadius = 10.0
        plusButton.layer.borderWidth = 1.5
        plusButton.layer.borderColor = UIColor.black.cgColor
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        userId = Auth.auth().currentUser?.uid
        
        ref = Database.database().reference()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        ref.child("users").child(userId).observe(.childAdded, with: { [self] snapshot in
            guard let listName = snapshot.childSnapshot(forPath: "name").value as? String else { return }

            self.listArray.append(listName)
            print("listArray:", listArray)
            self.keyArray.append(snapshot.key)

            //            if (type(of: memoValue)) == Optional<Any>.self{
            //                print("type if: memoID追加\(memoId)")
            //                print(memoValue!)
            //                self.listArray.append(memoId)
            //            } else if memoValue as! String != "temporaly value" {
            //                print("temp if: memoID追加\(memoId)")
            //                self.listArray.append(memoId)
            //            } else {
            //
            //            }
            self.tableView.reloadData()
        })
        
        userId = Auth.auth().currentUser?.uid
        
        print("list:", list)
//        print("key:", key)
        print("listArray:", listArray)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("cellCount: \(listArray.count)")
        return listArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomListCell") as! CustomListCell
        
        if indexPath.row == listArray.count {
            cell.listLabel?.text = "＋"
            return cell
        } else {
            cell.listLabel?.text = listArray[indexPath.row]
            return cell
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "toViewControllerFromTableView" {
            // 2. 遷移先のViewControllerを取得
            let next = segue.destination as? ViewController
            // 3. １で用意した遷移先の変数に値を渡す
            next?.list = list
            next?.name = name
            
        }
    }
    
    func tableView(_ tableVew: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == listArray.count {
            
            var alertTextField: UITextField!
            
            let alert: UIAlertController = UIAlertController(title: "リストの新規作成", message: "新しく作るリストの名前を入力してください。", preferredStyle: .alert)
            alert.addTextField { textField in
                alertTextField = textField
                alertTextField.returnKeyType = .done
                alert.addAction(
                    UIAlertAction(
                        title: "キャンセル",
                        style: .default,
                        handler: { action in
                        }
                    )
                )
                alert.addAction(
                    UIAlertAction(
                        title: "新規作成",
                        style: .default,
                        handler: { action in
                            if textField.text != "" {
                                let text = textField.text!
                                let memo = ["memo": text]
                                                                
                                self.dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                                self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                                self.dateFormatter.timeZone = TimeZone(identifier: "UTC")
                                let date = self.dateFormatter.string(from: Date())
                                
                                self.ref.child("users").child(self.userId).child("list\(date)").updateChildValues(["name": text, "memo": memo])
                                                                
                                textField.text = ""
                            }
                        }
                    )
                )
            }
            self.present(alert, animated: true, completion: nil)
        } else {
            let cell = tableView.cellForRow(at: indexPath)
            let key = keyArray[indexPath.row]
            let listName = listArray[indexPath.row]
            list = key
            name = listName
            print("🎌list:", list!)
            print("🇯🇵listName:", name!)
            self.performSegue(withIdentifier: "toViewControllerFromTableView", sender: nil)
        }
    }
    
    @IBAction func plus() {
        var alertTextField: UITextField!
        
        let alert: UIAlertController = UIAlertController(title: "リストの新規作成", message: "新しく作るリストの名前を入力してください。", preferredStyle: .alert)
        alert.addTextField { textField in
            alertTextField = textField
            alertTextField.returnKeyType = .done
            alert.addAction(
                UIAlertAction(
                    title: "キャンセル",
                    style: .default,
                    handler: { action in
                    }
                )
            )
            alert.addAction(
                UIAlertAction(
                    title: "新規作成",
                    style: .default,
                    handler: { action in
                        if textField.text != "" {
                            let text = textField.text!
                            let memo = ["memo": text]
                            
                            self.dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                            self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                            self.dateFormatter.timeZone = TimeZone(identifier: "UTC")
                            let date = self.dateFormatter.string(from: Date())
                            
                            self.ref.child("users").child(self.userId).child("list\(date)").updateChildValues(["name": text, "memo": text])
                            
                            textField.text = ""
                        }
                    }
                )
            )
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    //     スワイプした時に表示するアクションの定義
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var deleteAction: UIContextualAction
        var editAction: UIContextualAction
        if indexPath.row < listArray.count {
            list = listArray[indexPath.row]
            // 削除処理
            deleteAction = UIContextualAction(style: .destructive, title: "削除") { (action, view, completionHandler) in
                //削除処理を記述
                print("Deleteがタップされた")
                                
                self.list = self.keyArray[indexPath.row]
                
                self.listArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                self.ref.child("users").child(self.userId).child(self.list).removeValue()
                
                // 実行結果に関わらず記述
                completionHandler(true)
            }
            // 編集処理
            editAction = UIContextualAction(style: .normal, title: "編集") { (action, view, completionHandler) in
                // 編集処理を記述
                print("編集がタップされた")
                
                var alertTextField: UITextField!
                
                let alert: UIAlertController = UIAlertController(title: "リストの名称変更", message: "新しいリストの名前を入力してください。", preferredStyle: .alert)
                alert.addTextField { textField in
                    alertTextField = textField
                    alertTextField.returnKeyType = .done
                    alertTextField.text = self.list
                    alert.addAction(
                        UIAlertAction(
                            title: "キャンセル",
                            style: .default,
                            handler: { action in
                            }
                        )
                    )
                    alert.addAction(
                        UIAlertAction(
                            title: "OK",
                            style: .default,
                            handler: { action in
                                if alertTextField.text != "" {
                                    
                                    let list = self.listArray[indexPath.row]
                                    let key = self.keyArray[indexPath.row]
                                    let text = alertTextField.text!
                                    let memo = ["memo": text]
                                    
                                    self.listArray.replace(before: list, after: text)
                                    
                                    self.ref.child("users").child(self.userId).child(key).updateChildValues(["name": text])
                                }
                            }
                        )
                    )
                    
                    self.present(alert, animated: true, completion: nil)
                }
                // 実行結果に関わらず記述
                completionHandler(true)
            }
            editAction.backgroundColor = UIColor.systemBlue
            
            self.tableView.reloadData()
            
            // 定義したアクションをセット
            return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        } else {
            // 定義したアクションをセット
            return UISwipeActionsConfiguration(actions: [])
        }
    }
}

extension Array where Element: Equatable {
    mutating func replace(before: Array.Element, after: Array.Element) {
        self = self.map { ($0 == before) ? after : $0 }
    }
}

