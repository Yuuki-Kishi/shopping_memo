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
    
    @IBOutlet var connection: UIImageView!

    let dateFormatter = DateFormatter()

    var listNameText: String!
    var connect = false
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    var listArray = [(listId: String, listName: String, listCount: Int)]()
        
    var ref: DatabaseReference!
    
    var userId: String!
    
    var list: String!
    
    var name: String!
    
    //    var dict: [String : String] = ["":""]
    
    var value: String!
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var editButton: UIButton!
    
    var listCountInt: Int!
    var memoNumber = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listCountInt = userDefaults.integer(forKey: "listCount")
        
        tableView.register(UINib(nibName: "CustomListCell", bundle: nil), forCellReuseIdentifier: "CustomListCell")
        
        //        tableView.frame = CGRect(x: 0, y: 10, width: 408, height: 60)
        
        
        editButton.imageView?.contentMode = .scaleAspectFit
        editButton.contentHorizontalAlignment = .fill
        editButton.contentVerticalAlignment = .fill
        
        let image = UIImage(systemName: "ellipsis.circle")
        editButton.setImage(image, for: .normal)
        editButton.tintColor = UIColor.black

        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        userId = Auth.auth().currentUser?.uid
        
        ref = Database.database().reference()
        
        tableView.delegate = self
        tableView.dataSource = self
                
        listArray = []
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
          if snapshot.value as? Bool ?? false {
              self.connection.image = UIImage(systemName: "wifi")
              self.connect = true
          } else {
              self.connection.image = UIImage(systemName: "wifi.slash")
              self.connect = false
        }})
        
        ref.child("users").child(userId).observe(.childAdded, with: { [self] snapshot in
            let listId = snapshot.key
            guard let listName = snapshot.childSnapshot(forPath: "name").value as? String else { return }
            let listCount = (snapshot.childSnapshot(forPath: "listCount").value as? Int) ?? 0
            self.listArray.append((listId: listId, listName: listName, listCount: listCount))
            listArray.sort {$0.listCount < $1.listCount}
            self.tableView.reloadData()
        })
        
        ref.child("users").child(userId).observe(.childChanged, with: { [self] snapshot in
            let listId = snapshot.key
            guard let listName = snapshot.childSnapshot(forPath: "name").value as? String else { return }
            let listCount = (snapshot.childSnapshot(forPath: "listCount").value as? Int) ?? 0
            let index = listArray.firstIndex(where: {$0.listId == listId})
            self.listArray[index!] = ((listId: listId, listName: listName, listCount: listCount))
            listArray.sort {$0.listCount < $1.listCount}
            self.tableView.reloadData()
        })
        
        ref.child("users").child(userId).observe(.childRemoved, with: { [self] snapshot in
            let listId = snapshot.key
            let index = listArray.firstIndex(where: {$0.listId == listId})
            self.tableView.reloadData()
        })
        userId = Auth.auth().currentUser?.uid
        
        print("list:", list)
//        print("key:", key)
        print("listArray:", listArray)
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.isEditing { return listArray.count }
        return listArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        print("cellCount: \(listArray.count)")
//        return listArray.count + 1
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomListCell") as! CustomListCell
        if indexPath.section == listArray.count {
            cell.listLabel?.text = "＋"
            return cell
        } else {
            cell.listLabel?.text = listArray[indexPath.section].listName
            return cell
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "toViewControllerFromTableView" {
            // 2. 遷移先のViewControllerを取得
            let next = segue.destination as? ViewController
            // 3. １で用意した遷移先の変数に値を渡す]
            next?.list = list
            next?.name = name
            
        }
    }
    
    func tableView(_ tableVew: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableVew.deselectRow(at: indexPath, animated: true)
        if indexPath.section == listArray.count {
            if connect {
                var alertTextField: UITextField!
                let alert: UIAlertController = UIAlertController(title: "リストの新規作成", message: "新しく作るリストの名前を入力してください。", preferredStyle: .alert)
                alert.addTextField { textField in
                    alertTextField = textField
                    alertTextField.returnKeyType = .done
                    alert.addAction(
                        UIAlertAction(
                            title: "キャンセル",
                            style: .cancel
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
                                    
                                    print("date:", date)
                                    print("新規作成")
                                    self.ref.child("users").child(self.userId).child("list\(date)").updateChildValues(["name": text, "listCount": -1])
                                    
                                    textField.text = ""
                                }
                            }
                        )
                    )
                }
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert: UIAlertController = UIAlertController(title: "インターネット未接続", message: "ネットワークの接続状態を確認してください。", preferredStyle: .alert)
                alert.addAction(
                    UIAlertAction(
                        title: "OK",
                        style: .default,
                        handler: { action in
                        }))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            list = listArray[indexPath.section].listId
            name = listArray[indexPath.section].listName
            self.performSegue(withIdentifier: "toViewControllerFromTableView", sender: nil)
        }
    }
    
    @IBAction func edit() {
        if tableView.isEditing {
            let image = UIImage(systemName: "ellipsis.circle")
            editButton.setImage(image, for: .normal)
            editButton.tintColor = UIColor.black
            tableView.isEditing = false
            tableView.reloadData()
        } else {
            let image = UIImage(systemName: "checkmark")
            editButton.setImage(image, for: .normal)
            editButton.tintColor = UIColor.black
            tableView.isEditing = true
            tableView.reloadData()
        }
    }
    
    @IBAction func signOut() {
        let alert: UIAlertController = UIAlertController(title: "本当にログアウトしますか？", message: "ログアウトすると再度ログインする必要があります。", preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: "ログアウト",
                style: .destructive,
                handler: { action in
                    let firebaseAuth = Auth.auth()
                    do {
                        try firebaseAuth.signOut()
                    } catch let signOutError as NSError {
                        print ("Error signing out: %@", signOutError)
                    }
                    self.dismiss(animated: true, completion: nil)
                }))
        alert.addAction(
            UIAlertAction(
                title: "キャンセル",
                style: .cancel
            ))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    //     スワイプした時に表示するアクションの定義
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var deleteAction: UIContextualAction
        if indexPath.section < listArray.count {
            let list = listArray[indexPath.row].listId
            // 削除処理
            deleteAction = UIContextualAction(style: .destructive, title: "削除") { (action, view, completionHandler) in
                //削除処理を記述
                print("Deleteがタップされた")
                                                
                self.ref.child("users").child(self.userId).child(list).removeValue()
                self.listArray.remove(at: indexPath.section)
                print("listArray:", self.listArray)
//                tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                let indexSet = NSMutableIndexSet()
                indexSet.add(indexPath.section)
                tableView.deleteSections(indexSet as IndexSet, with: UITableView.RowAnimation.left )
                
                // 実行結果に関わらず記述
                completionHandler(true)
            }
            
            self.tableView.reloadData()
            
            // 定義したアクションをセット
            return UISwipeActionsConfiguration(actions: [deleteAction])
        } else {
            // 定義したアクションをセット
            return UISwipeActionsConfiguration(actions: [])
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var editAction: UIContextualAction
        if indexPath.section < listArray.count {
            let listId = listArray[indexPath.row].listId
            let listName = listArray[indexPath.row].listName
            // 編集処理
            editAction = UIContextualAction(style: .normal, title: "編集") { (action, view, completionHandler) in
                // 編集処理を記述
                print("編集がタップされた")
                
                var alertTextField: UITextField!
                
                let alert: UIAlertController = UIAlertController(title: "リストの名称変更", message: "新しいリストの名前を入力してください。", preferredStyle: .alert)
                alert.addTextField { textField in
                    alertTextField = textField
                    alertTextField.clearButtonMode = UITextField.ViewMode.always
                    alertTextField.returnKeyType = .done
                    alertTextField.text = listName
                    alert.addAction(
                        UIAlertAction(
                            title: "キャンセル",
                            style: .cancel
                        ))
                    alert.addAction(
                        UIAlertAction(
                            title: "OK",
                            style: .default,
                            handler: { action in
                                if alertTextField.text != "" {
                                    let text = alertTextField.text!
                                    self.listArray[indexPath.row].listName = text
                                    self.ref.child("users").child(self.userId).child(listId).updateChildValues(["name": text])
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
            return UISwipeActionsConfiguration(actions: [editAction])
        } else {
            // 定義したアクションをセット
            return UISwipeActionsConfiguration(actions: [])
        }
    }
    
    func listSort() {
        if listArray.count != 0 {
            for i in 0...listArray.count - 1 {
                let listId = listArray[i].listId
                var listCount = listArray[i].listCount
                
                listCount = i
                self.ref.child("users").child(userId).child(listId).updateChildValues(["listCount": listCount])
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == listArray.count { return false }
        return true
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let list = listArray[sourceIndexPath.section]
        listArray.remove(at: sourceIndexPath.section)
        listArray.insert(list, at: destinationIndexPath.section)
        listSort()
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension Array where Element: Equatable {
    mutating func replace(before: Array.Element, after: Array.Element) {
        self = self.map { ($0 == before) ? after : $0 }
    }
}

