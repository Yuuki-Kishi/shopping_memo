//
//  NewmemoViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/12/14.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var plusButton: UIButton!
    
    let dateFormatter = DateFormatter()
    var connect = false
    let userDefaults: UserDefaults = UserDefaults.standard
    var listArray = [(listId: String, listName: String, listCount: Int)]()
    var ref: DatabaseReference!
    var userId: String!
    var roomIdString: String!
    var roomNameString: String!
    var listIdString: String!
    var listNameString: String!
    var myAuthority: String!
    var menuBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = roomNameString
        
        UISetUp()
        setUpData()
        moveData()
        
        tableView.register(UINib(nibName: "CustomListCell", bundle: nil), forCellReuseIdentifier: "CustomListCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        listArray = []
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observeRealtimeDatabase()
    }
    
    func UISetUp() {
        plusButton.layer.cornerRadius = 35.0
        
        plusButton.layer.shadowOpacity = 0.3
        plusButton.layer.shadowRadius = 3
        plusButton.layer.shadowColor = UIColor.gray.cgColor
        plusButton.layer.shadowOffset = CGSize(width: 0, height: 5)
    }
    
    func setUpData() {
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        ref.child("rooms").child(roomIdString).child("members").child(userId).observeSingleEvent(of: .value, with: { [self] snapshot in
            guard let authority = snapshot.childSnapshot(forPath: "authority").value as? String else { return }
            myAuthority = authority
            menu()
        })
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }
        })
    }
    
    func observeRealtimeDatabase() {
        ref.child("rooms").child(roomIdString).child("lists").observe(.childAdded, with: { [self] snapshot in
            let listId = snapshot.key
            ref.child("rooms").child(roomIdString).child("lists").child(listId).child("info").observeSingleEvent(of: .value, with: { [self] snapshot in
                guard let listName = snapshot.childSnapshot(forPath: "listName").value as? String else { return }
                guard let listCount = snapshot.childSnapshot(forPath: "listCount").value as? Int else { return }
                let isContain = listArray.contains(where: {$0.listId == listId})
                if !isContain {
                    listArray.append((listId: listId, listName: listName, listCount: listCount))
                    listArray.sort {$0.listCount < $1.listCount}
                    tableView.reloadData()
                }
            })
        })
        
        ref.child("users").child(userId).child("rooms").observe(.childChanged, with: { [self] snapshot in
            let userId = snapshot.key
            let newAuthority = snapshot.value as? String
            myAuthority = newAuthority!
            menu()
        })
        
        ref.child("rooms").child(roomIdString).child("lists").observe(.childChanged, with: { [self] snapshot in
            let listId = snapshot.key
            ref.child("rooms").child(roomIdString).child("lists").child(listId).child("info").observeSingleEvent(of: .value, with: { [self] snapshot in
                guard let listName = snapshot.childSnapshot(forPath: "listName").value as? String else { return }
                let listCount = (snapshot.childSnapshot(forPath: "listCount").value as? Int) ?? 0
                if let index = listArray.firstIndex(where: {$0.listId == listId}) {
                    listArray[index] = ((listId: listId, listName: listName, listCount: listCount))
                    listArray.sort {$0.listCount < $1.listCount}
                }
                tableView.reloadData()
            })
        })
        
        ref.child("rooms").child(roomIdString).observe(.childChanged, with: { [self] snapshot in
            guard let roomName = snapshot.childSnapshot(forPath: "roomName").value as? String else { return }
            roomNameString = roomName
            title = roomName
        })
        
        ref.child("rooms").child(roomIdString).child("lists").observe(.childRemoved, with: { [self] snapshot in
            let listId = snapshot.key
            if let index = listArray.firstIndex(where: {$0.listId == listId}) { listArray.remove(at: index) }
            tableView.reloadData()
        })
        
        ref.child("rooms").observe(.childRemoved, with: { [self] snapshot in
            let roomId = snapshot.key
            if roomId == roomIdString && myAuthority != "administrator" {
                let alert: UIAlertController = UIAlertController(title: "ルームが削除されました", message: "詳しくはルームの管理者にお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
        
        ref.child("users").child(userId).child("rooms").observe(.childRemoved, with: { [self] snapshot in
            let roomId = snapshot.key
            let authority = snapshot.value as? String
            if roomId == self.roomIdString && authority! != "administrator" {
                let alert: UIAlertController = UIAlertController(title: "ルームを追放されました", message: "詳しくはルームの管理者にお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func moveData() {
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        ref.child("users").child(userId).observe(.childAdded, with: { [self] snapshot in
            let listId = snapshot.key
            guard let listName = snapshot.childSnapshot(forPath: "name").value as? String else { return }
            let listCount = (snapshot.childSnapshot(forPath: "listCount").value as? Int) ?? 0
            ref.child("rooms").child(roomIdString).child("lists").child(listId).child("info").updateChildValues(["listCount": listCount, "listName": listName])
            ref.child("users").child(userId).child(listId).child("name").removeValue()
            ref.child("users").child(userId).child(listId).child("未チェック").observe(.childAdded, with: { [self] snapshot in
                let memoId = snapshot.key
                guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return }
                guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                let checkedCount = (snapshot.childSnapshot(forPath: "checkedCount").value as? Int) ?? 0
                guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return }
                guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
                guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
                ref.child("rooms").child(roomIdString).child("lists").child(listId).child("memo").child(memoId).updateChildValues(["memoCount": memoCount, "checkedCount": checkedCount, "shoppingMemo": shoppingMemo, "isChecked": isChecked, "dateNow": dateNow, "checkedTime": checkedTime, "imageUrl": imageUrl])
                ref.child("users").child(userId).child(listId).child("未チェック").child(memoId).removeValue()
            })
            
            ref.child("users").child(userId).child(listId).child("チェック済み").observe(.childAdded, with: { [self] snapshot in
                let memoId = snapshot.key
                guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return }
                guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                let checkedCount = (snapshot.childSnapshot(forPath: "checkedCount").value as? Int) ?? 0
                guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return }
                guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
                guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
                ref.child("rooms").child(roomIdString).child("lists").child(listId).child("memo").child(memoId).updateChildValues(["memoCount": memoCount, "checkedCount": checkedCount, "shoppingMemo": shoppingMemo, "isChecked": isChecked, "dateNow": dateNow, "checkedTime": checkedTime, "imageUrl": imageUrl])
                ref.child("users").child(userId).child(listId).child("チェック済み").child(memoId).removeValue()
            })
            
            ref.child("users").child(userId).child(listId).child("memo").observe(.childAdded, with: { [self] snapshot in
                let memoId = snapshot.key
                guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return }
                guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                let checkedCount = (snapshot.childSnapshot(forPath: "checkedCount").value as? Int) ?? 0
                guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return }
                guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
                let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String
                ref.child("rooms").child(roomIdString).child("lists").child(listId).child("memo").child(memoId).updateChildValues(["memoCount": memoCount, "checkedCount": checkedCount, "shoppingMemo": shoppingMemo, "isChecked": isChecked, "dateNow": dateNow, "checkedTime": checkedTime, "imageUrl": imageUrl!])
                ref.child("users").child(userId).child(listId).child("memo").child(memoId).removeValue()
                if imageUrl == "" { return }
                
                let imageRef = Storage.storage().reference(forURL: imageUrl!)
                imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        let imageRef = Storage.storage().reference().child("/\(self.roomIdString!)/\(listId)/\(memoId).jpg")
                        imageRef.putData(data!, metadata: nil) { (metadata, error) in
                            if let error = error {
                                print(error)
                            } else {
                                imageRef.downloadURL { (url, error) in
                                    guard let downloadURL = url else { return }
                                    let imageUrl = downloadURL.absoluteString
                                    self.ref.child("rooms").child(self.roomIdString).child("lists").child(listId).child("memo").child(memoId).updateChildValues(["imageUrl": imageUrl])
                                }
                            }
                        }
                    }
                }
            })
        })
        
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
            next?.listIdString = listIdString
            next?.listNameString = listNameString
            next?.roomIdString = roomIdString
        } else if segue.identifier == "toMVC" {
            let next = segue.destination as? MemberViewController
            next?.roomIdString = roomIdString
        } else if segue.identifier == "toTVC" {
            let next = segue.destination as? TransferViewController
            next?.roomIdString = roomIdString
        }
    }
    
    func tableView(_ tableVew: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableVew.deselectRow(at: indexPath, animated: true)
        if connect {
            listIdString = listArray[indexPath.section].listId
            listNameString = listArray[indexPath.section].listName
            self.performSegue(withIdentifier: "toVC", sender: nil)
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
    
    func deleteRoom() {
        let alert: UIAlertController = UIAlertController(title: "本当に削除しますか？", message: "脱退したい場合は管理者権限を譲渡してから脱退してください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "削除", style: .destructive, handler: { action in
            self.ref.child("rooms").child(self.roomIdString).child("members").observe(.childAdded, with: { snapshot in
                let userId = snapshot.key
                self.ref.child("users").child(userId).child("rooms").child(self.roomIdString).removeValue()
            })
            self.ref.child("rooms").child(self.roomIdString).removeValue()
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
    
    //     スワイプした時に表示するアクションの定義
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if connect {
            var deleteAction: UIContextualAction
            let listId = listArray[indexPath.section].listId
            // 削除処理
            deleteAction = UIContextualAction(style: .destructive, title: "削除") { (action, view, completionHandler) in
                //削除処理を記述
                self.listArray.remove(at: indexPath.section)
                self.ref.child("rooms").child(self.roomIdString).child("lists").child(listId).removeValue()
                GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
                let indexSet = NSMutableIndexSet()
                indexSet.add(indexPath.section)
                tableView.deleteSections(indexSet as IndexSet, with: UITableView.RowAnimation.left)
                // 実行結果に関わらず記述
                completionHandler(true)
            }
            self.tableView.reloadData()
            // 定義したアクションをセット
            return UISwipeActionsConfiguration(actions: [deleteAction])
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
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
                    alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        if alertTextField.text != "" {
                            let text = alertTextField.text!
                            self.listArray[indexPath.section].listName = text
                            self.ref.child("rooms").child(self.roomIdString).child("lists").child(listId).child("info").updateChildValues(["listName": text])
                            GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
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
            GeneralPurpose.notConnectAlert(VC: self)
            return UISwipeActionsConfiguration(actions: [])
        }
    }
    
    func menu() {
        if tableView.isEditing {
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(menuBarButtonItem(_:)))
            menuBarButtonItem.tintColor = .label
        } else {
            let Items = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "ルーム名を変更", image: UIImage(systemName: "arrow.triangle.2.circlepath"), handler: { _ in self.roomNameChange()}),
                UIAction(title: "メンバーの確認・変更", image: UIImage(systemName: "person.2.fill"), handler: { _ in self.performSegue(withIdentifier: "toMVC", sender: true)}),
                UIAction(title: "リストを並び替え", image: UIImage(systemName: "list.bullet"), handler: { _ in
                    if !self.listArray.isEmpty {
                        self.tableView.isEditing = true
                        self.menu()
                    } else {
                        let alert: UIAlertController = UIAlertController(title: "並べ替えできません。", message: "並べ替えるリストが存在しません。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                })
            ])
            let transfer = UIAction(title: "管理者権限を譲渡", image: UIImage(systemName: "person.line.dotted.person.fill"), attributes: .destructive, handler: { _ in
                self.performSegue(withIdentifier: "toTVC", sender: true)
            })
            let delete = UIAction(title: "ルームを削除", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { _ in self.deleteRoom()})
            let withdrawal = UIAction(title: "ルームを脱退", image: UIImage(systemName: "door.right.hand.open"), attributes: .destructive, handler: { _ in self.withdrawal()})
            if myAuthority == "administrator" {
                let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), options: .displayInline, children: [Items, transfer, delete])
                menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
            } else {
                let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), options: .displayInline, children: [Items, withdrawal])
                menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
            }
            menuBarButtonItem.tintColor = .label
        }
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
    }
    
    @objc func menuBarButtonItem(_ sender: UIBarButtonItem) {
        tableView.isEditing = false
        menu()
    }
    
    func withdrawal() {
        let alert: UIAlertController = UIAlertController(title: "本当にルームを脱退しますか？", message: "再度加入するには管理者に招待してもらう必要があります。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "脱退", style: .destructive, handler: { anction in
            self.ref.child("users").child(self.userId).child("rooms").child(self.roomIdString).removeValue()
            self.ref.child("rooms").child(self.roomIdString).child("members").child(self.userId).removeValue()
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
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
                alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                alert.addAction(UIAlertAction(title: "新規作成", style: .default, handler: { action in
                    if textField.text != "" {
                        self.dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        self.dateFormatter.timeZone = TimeZone(identifier: "UTC")
                        let date = self.dateFormatter.string(from: Date())
                        GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
                        let text = textField.text!
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child("list\(date)").child("info").updateChildValues(["listName": text, "listCount": -1])
                        textField.text = ""
                    }}))}
            self.present(alert, animated: true, completion: nil)
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
    
    func roomNameChange() {
        var alertTextField: UITextField!
        let alert: UIAlertController = UIAlertController(title: "ルームの名称変更", message: "新しいルームの名前を入力してください。", preferredStyle: .alert)
        alert.addTextField { textField in
            alertTextField = textField
            alertTextField.clearButtonMode = UITextField.ViewMode.always
            alertTextField.returnKeyType = .done
            alertTextField.text = self.roomNameString
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            alert.addAction(UIAlertAction(title: "変更", style: .default, handler: { action in
                if alertTextField.text != "" {
                    GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
                    let text = alertTextField.text
                    self.ref.child("rooms").child(self.roomIdString).child("info").updateChildValues(["roomName": text!])
                }}))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func listSort() {
        for i in 0...listArray.count - 1 {
            let listId = listArray[i].listId
            self.ref.child("rooms").child(roomIdString).child("lists").child(listId).child("info").updateChildValues(["listCount": i])
        }
        GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
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
