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
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var plusButton: UIButton!
            
    let dateFormatter = DateFormatter()
    var connect = false
    let userDefaults: UserDefaults = UserDefaults.standard
    var listArray = [(listId: String, listName: String, listCount: Int)]()
    var ref: DatabaseReference!
    var userId: String!
    var list: String!
    var name: String!
    var menuBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "リスト"
        navigationItem.hidesBackButton = true
        
        menu()
        
        plusButton.layer.cornerRadius = 35.0
        
        plusButton.layer.shadowOpacity = 0.3
        plusButton.layer.shadowRadius = 3
        plusButton.layer.shadowColor = UIColor.gray.cgColor
        plusButton.layer.shadowOffset = CGSize(width: 0, height: 5)
                        
        tableView.register(UINib(nibName: "CustomListCell", bundle: nil), forCellReuseIdentifier: "CustomListCell")
                
        userId = Auth.auth().currentUser?.uid
        
        ref = Database.database().reference()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        listArray = []
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
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
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return listArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomListCell") as! CustomListCell
        cell.listLabel?.text = listArray[indexPath.section].listName
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "toVC" {
            // 2. 遷移先のViewControllerを取得
            let next = segue.destination as? ViewController
            // 3. １で用意した遷移先の変数に値を渡す]
            next?.list = list
            next?.name = name
        }
    }
    
    func tableView(_ tableVew: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableVew.deselectRow(at: indexPath, animated: true)
        if connect {
            list = listArray[indexPath.section].listId
            name = listArray[indexPath.section].listName
            self.performSegue(withIdentifier: "toVC", sender: nil)
        } else {
            alert()
        }
    }
    
    func signOut() {
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
                    self.navigationController?.popToRootViewController(animated: true)
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
        if connect {
            var deleteAction: UIContextualAction
            let list = listArray[indexPath.section].listId
            // 削除処理
            deleteAction = UIContextualAction(style: .destructive, title: "削除") { (action, view, completionHandler) in
                //削除処理を記述
                self.ref.child("users").child(self.userId).child(list).removeValue()
                self.listArray.remove(at: indexPath.section)
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
            alert()
            return UISwipeActionsConfiguration(actions: [])
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var editAction: UIContextualAction
        if connect {
            let listId = listArray[indexPath.section].listId
            let listName = listArray[indexPath.section].listName
            // 編集処理
            editAction = UIContextualAction(style: .normal, title: "編集") { (action, view, completionHandler) in
                // 編集処理を記述
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
                                    self.listArray[indexPath.section].listName = text
                                    self.ref.child("users").child(self.userId).child(listId).updateChildValues(["name": text])
                                }}))
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
            alert()
            return UISwipeActionsConfiguration(actions: [])
        }
    }
    
    func menu() {
        if tableView.isEditing {
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(menuBarButtonItem(_:)))
            menuBarButtonItem.tintColor = .label
        } else {
            let Items = UIMenu(title: "", options: .displayInline, children: [
//                UIAction(title: "リストの追加", image: UIImage(systemName: "plus"), handler: { _ in self.listPlus()}),
                UIAction(title: "リストの編集", image: UIImage(systemName: "list.bullet"), handler: { _ in self.tableView.isEditing = true; self.menu()})
            ])
            let signOut = UIAction(title: "ログアウト", attributes: .destructive, handler: { _ in self.signOut()})
            let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), options: .displayInline, children: [Items, signOut])
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
            menuBarButtonItem.tintColor = .label
        }
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
    }
    
    @objc func menuBarButtonItem(_ sender: UIBarButtonItem) {
        tableView.isEditing = false
        menu()
    }
    
    func alert() {
        let alert: UIAlertController = UIAlertController(title: "インターネット未接続", message: "ネットワークの接続状態を確認してください。", preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            ))
        self.present(alert, animated: true, completion: nil)
    }
    
    func listPlus() {
        if connect {
            var alertTextField: UITextField!
            let alert: UIAlertController = UIAlertController(title: "リストの新規作成", message: "新しく作るリストの名前を入力してください。", preferredStyle: .alert)
            alert.addTextField { textField in
                alertTextField = textField
                alertTextField.returnKeyType = .done
                alertTextField.clearButtonMode = .always 
                alert.addAction(
                    UIAlertAction(
                        title: "キャンセル",
                        style: .cancel
                    ))
                alert.addAction(
                    UIAlertAction(
                        title: "新規作成",
                        style: .default,
                        handler: { action in
                            if textField.text != "" {
                                let text = textField.text!
                                self.dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                                self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                                self.dateFormatter.timeZone = TimeZone(identifier: "UTC")
                                let date = self.dateFormatter.string(from: Date())
                                self.ref.child("users").child(self.userId).child("list\(date)").updateChildValues(["name": text, "listCount": -1])
                                textField.text = ""
                            }}))}
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
    }
    
    func listSort() {
        for i in 0...listArray.count - 1 {
            let listId = listArray[i].listId
            var listCount = listArray[i].listCount
            listCount = i
            self.ref.child("users").child(userId).child(listId).updateChildValues(["listCount": listCount])
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
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
    
    @IBAction func plus() {
        listPlus()
    }
}

extension Array where Element: Equatable {
    mutating func replace(before: Array.Element, after: Array.Element) {
        self = self.map { ($0 == before) ? after : $0 }
    }
}
