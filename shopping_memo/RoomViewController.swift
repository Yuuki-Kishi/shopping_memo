//
//  RoomViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/11.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class RoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var plusButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var noCellLabel: UILabel!
    
    var ref: DatabaseReference!
    var dateFormatter = DateFormatter()
    let userDefaults: UserDefaults = UserDefaults.standard
    var connect: Bool!
    var userId: String!
    var roomIdString: String!
    var roomNameString: String!
    var roomArray = [(roomId: String, roomName: String, lastEditTime: Date, lastEditorName: String, authority: String)]()
    var otherArray = [(roomId: String, roomName: String, lastEditTime: Date, lastEditorName: String, authority: String)]()
    var guestArray = [(roomId: String, roomName: String, lastEditTime: Date, lastEditorName: String, authority: String)]()
    var signOutBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpData()
        tableViewSetUp()
        menu()
        UISetUp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observeRealtimeDatabase()
    }
    
    func tableViewSetUp() {
        tableView.register(UINib(nibName: "RoomTableViewCell", bundle: nil), forCellReuseIdentifier: "RoomTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func UISetUp() {
        title = "ホーム"
        navigationItem.hidesBackButton = true
        plusButton.layer.cornerRadius = 35.0
        plusButton.layer.shadowOpacity = 0.3
        plusButton.layer.shadowRadius = 3
        plusButton.layer.shadowColor = UIColor.gray.cgColor
        plusButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        noCellLabel.adjustsFontSizeToFitWidth = true
        if let userId = userDefaults.string(forKey: "userId") { moveData(oldUserId: userId) }
    }
    
    func setUpData() {
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        ref.child("users").child(userId).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
            var email = snapshot.childSnapshot(forPath: "email").value as? String
            let userName = snapshot.childSnapshot(forPath: "userName").value as? String
            if email == nil {
                email = Auth.auth().currentUser?.email
                self.ref.child("users").child(self.userId).child("metadata").updateChildValues(["email": email!])
            }
            if userName == nil {
                self.ref.child("users").child(self.userId).child("metadata").updateChildValues(["userName": "未設定"])
                var alertTextField: UITextField!
                let alert: UIAlertController = UIAlertController(title: "ユーザーネームが未設定です", message: "ユーザーネームは後で設定することもできます。", preferredStyle: .alert)
                alert.addTextField { textField in
                    alertTextField = textField
                    alertTextField.returnKeyType = .done
                    alertTextField.clearButtonMode = .always
                    alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                    alert.addAction(UIAlertAction(title: "設定", style: .default, handler: { action in
                        if textField.text != "" {
                            let text = textField.text!
                            self.ref.child("users").child(self.userId).child("metadata").updateChildValues(["userName": text])
                            textField.text = ""
                        }}))}
                self.present(alert, animated: true, completion: nil)
            }
        })
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
                if let oldUserId = self.userDefaults.string(forKey: "userId") {
                    self.moveData(oldUserId: oldUserId)
                }
            } else {
                self.connect = false
            }
        })
    }
    
    func observeRealtimeDatabase() {
        guestArray = []
        otherArray = []
        
        ref.child("users").child(userId).child("rooms").observe(.childAdded, with: { [self] snapshot in
            GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "get")
            let roomId = snapshot.key
            ref.child("users").child(userId).child("rooms").observeSingleEvent(of: .value, with: { [self] snapshot in
                let roomCount = snapshot.childrenCount
                if roomCount == 0 { GeneralPurpose.AIV(VC: self, view: view, status: "stop", session: "get") }
                ref.child("rooms").child(roomId).child("info").observeSingleEvent(of: .value, with: { [self] snapshot in
                    guard let roomName = snapshot.childSnapshot(forPath: "roomName").value as? String else { return }
                    guard let time = snapshot.childSnapshot(forPath: "lastEditTime").value as? String else { return }
                    guard let lastEditorId = snapshot.childSnapshot(forPath: "lastEditor").value as? String else { return }
                    dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    dateFormatter.timeZone = TimeZone(identifier: "UTC")
                    let lastEditTime = dateFormatter.date(from: time)
                    ref.child("rooms").child(roomId).child("members").child(userId).observeSingleEvent(of: .value, with: { [self] snapshot in
                        guard let authority = snapshot.childSnapshot(forPath: "authority").value as? String else { return }
                        ref.child("users").child(lastEditorId).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
                            guard let userName = snapshot.childSnapshot(forPath: "userName").value as? String else { return }
                            if authority == "guest" {
                                let isContain = guestArray.contains(where: {$0.roomId == roomId})
                                if !isContain {
                                    guestArray.append((roomId: roomId, roomName: roomName, lastEditTime: lastEditTime!, lastEditorName: userName, authority: authority))
                                }
                                guestArray.sort {$0.lastEditTime > $1.lastEditTime}
                            } else {
                                let isContain = otherArray.contains(where: {$0.roomId == roomId})
                                if !isContain {
                                    otherArray.append((roomId: roomId, roomName: roomName, lastEditTime: lastEditTime!, lastEditorName: userName, authority: authority))
                                }
                                otherArray.sort {$0.lastEditTime > $1.lastEditTime}
                            }
                            if roomCount == guestArray.count + otherArray.count {
                                GeneralPurpose.AIV(VC: self, view: view, status: "stop", session: "get")
                            }
                            tableView.reloadData()
                        })
                    })
                })
            })
        })
        
        ref.child("rooms").observe(.childChanged, with: { [self] snapshot in
            let roomId = snapshot.key
            ref.child("rooms").child(roomId).child("info").observeSingleEvent(of: .value, with: { [self] snapshot in
                guard let roomName = snapshot.childSnapshot(forPath: "roomName").value as? String else { return }
                guard let time = snapshot.childSnapshot(forPath: "lastEditTime").value as? String else { return }
                guard let lastEditorId = snapshot.childSnapshot(forPath: "lastEditor").value as? String else { return }
                dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(identifier: "UTC")
                let lastEditTime = dateFormatter.date(from: time)
                ref.child("rooms").child(roomId).child("members").child(userId).observeSingleEvent(of: .value, with: { [self] snapshot in
                    guard let authority = snapshot.childSnapshot(forPath: "authority").value as? String else { return }
                    ref.child("users").child(lastEditorId).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
                        guard let userName = snapshot.childSnapshot(forPath: "userName").value as? String else { return }
                        if let index = guestArray.firstIndex(where: {$0.roomId == roomId}) {
                            if authority == "guest" {
                                guestArray[index] = ((roomId: roomId, roomName: roomName, lastEditTime: lastEditTime!, lastEditorName: userName, authority: authority))
                                guestArray.sort {$0.lastEditTime < $1.lastEditTime}
                            } else {
                                guestArray.remove(at: index)
                                otherArray.append((roomId: roomId, roomName: roomName, lastEditTime: lastEditTime!, lastEditorName: userName, authority: authority))
                                otherArray.sort {$0.lastEditTime > $1.lastEditTime}
                            }
                        } else if let index = otherArray.firstIndex(where: {$0.roomId == roomId}) {
                            otherArray[index] = ((roomId: roomId, roomName: roomName, lastEditTime: lastEditTime!, lastEditorName: userName, authority: authority))
                            otherArray.sort {$0.lastEditTime > $1.lastEditTime}
                        }
                        tableView.reloadData()
                    })
                })
            })
        })
        
        ref.child("users").child(userId).child("rooms").observe(.childRemoved, with: { [self] snapshot in
            let roomId = snapshot.key
            if let index = guestArray.firstIndex(where: {$0.roomId == roomId}) {
                guestArray.remove(at: index)
            } else if let index = otherArray.firstIndex(where: {$0.roomId == roomId}) {
                otherArray.remove(at: index)
            }
            tableView.reloadData()
        })
    }
    
    func moveData(oldUserId: String) {
        GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "other")
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        ref.child("users").child(oldUserId).observe(.childAdded, with: { [self] snapshot in
            let listId = snapshot.key
            guard let listName = snapshot.childSnapshot(forPath: "name").value as? String else { return }
            ref.child("users").child(userId!).child(listId).updateChildValues(["listName": listName])
            ref.child("users").child(oldUserId).child(listId).child("name").removeValue()
            ref.child("users").child(oldUserId).child(listId).child("未チェック").observe(.childAdded, with: { [self] snapshot in
                let memoId = snapshot.key
                guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return }
                guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return }
                guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
                ref.child("users").child(userId!).child(listId).child("未チェック").child(memoId).updateChildValues(["memoCount": memoCount, "shoppingMemo": shoppingMemo, "isChecked": isChecked, "dateNow": dateNow, "imageUrl": imageUrl])
                ref.child("users").child(oldUserId) .child(listId).child("未チェック").child(memoId).removeValue()
            })
            
            ref.child("users").child(oldUserId).child(listId).child("チェック済み").observe(.childAdded, with: { [self] snapshot in
                let memoId = snapshot.key
                guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return }
                guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return }
                guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
                ref.child("users").child(userId!).child(listId).child("チェック済み").child(memoId).updateChildValues(["memoCount": memoCount, "shoppingMemo": shoppingMemo, "isChecked": isChecked, "dateNow": dateNow, "imageUrl": imageUrl])
                ref.child("users").child(oldUserId).child(listId).child("チェック済み").child(memoId).removeValue()
            })
            
            ref.child("users").child(oldUserId).child(listId).child("memo").observe(.childAdded, with: { [self] snapshot in
                let memoId = snapshot.key
                guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return }
                guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                let checkedCount = (snapshot.childSnapshot(forPath: "checkedCount").value as? Int) ?? 0
                guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return }
                guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
                let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String
                ref.child("users").child(userId!).child(listId).child("memo").child(memoId).updateChildValues(["memoCount": memoCount, "checkedCount": checkedCount, "shoppingMemo": shoppingMemo, "isChecked": isChecked, "dateNow": dateNow, "checkedTime": checkedTime, "imageUrl": imageUrl!])
                ref.child("users").child(oldUserId).child(listId).child("memo").child(memoId).removeValue()
                if imageUrl! == "" { relayFinish(); return }
                
                let imageRef = Storage.storage().reference(forURL: imageUrl!)
                imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print(error)
                    } else {
                        let imageRef = Storage.storage().reference().child("/\(self.userId!)/\(listId)/\(memoId).jpg")
                        imageRef.putData(data!, metadata: nil) { (metadata, error) in
                            if let error = error {
                                print(error)
                            } else {
                                imageRef.downloadURL { (url, error) in
                                    guard let downloadURL = url else { return }
                                    let imageUrl = downloadURL.absoluteString
                                    self.ref.child("users").child(self.userId!).child(listId).child("memo").child(memoId).updateChildValues(["imageUrl": imageUrl])
                                    self.relayFinish()
                                }
                            }
                        }
                    }
                }
            })
        })
    }
    
    func relayFinish() {
        GeneralPurpose.AIV(VC: self, view: self.view, status: "stop", session: "other")
        let alert: UIAlertController = UIAlertController(title: "引き継ぎが完了しました", message: "以前のアカウントのデータは削除されました。使用方法はチュートリアルをご覧ください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.userDefaults.removeObject(forKey: "userId")
        }))
        self.present(alert, animated: true, completion:  nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        roomArray = guestArray + otherArray
        if roomArray.count == 0 { tableView.backgroundColor = .clear }
        else { tableView.backgroundColor = .systemBackground }
        return roomArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomTableViewCell") as! RoomTableViewCell
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = .current
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let lastEditTime = dateFormatter.string(from: roomArray[indexPath.section].lastEditTime)
        cell.lastEditTimeLabel?.text = lastEditTime
        cell.editorLabel?.text = roomArray[indexPath.section].lastEditorName
        cell.accessoryType = .disclosureIndicator
        let authority = roomArray[indexPath.section].authority
        if authority == "guest" {
            cell.backgroundColor = .systemOrange
            cell.roomNameLabel?.text = roomArray[indexPath.section].roomName + " (招待されています)"
        } else {
            cell.backgroundColor = .systemGray6
            cell.roomNameLabel?.text = roomArray[indexPath.section].roomName
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if connect {
            let authority = roomArray[indexPath.section].authority
            if authority == "guest" {
                enterRoom(indexPath: indexPath)
            } else {
                roomIdString = roomArray[indexPath.section].roomId
                roomNameString = roomArray[indexPath.section].roomName
                self.performSegue(withIdentifier: "toLVC", sender: nil)
            }
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "toLVC" {
            // 2. 遷移先のViewControllerを取得
            let next = segue.destination as? ListViewController
            // 3. １で用意した遷移先の変数に値を渡す]
            next?.roomIdString = roomIdString
            next?.roomNameString = roomNameString
        }
    }
    
    func enterRoom(indexPath: IndexPath) {
        let alert: UIAlertController = UIAlertController(title: "このルームに加入しますか？", message: "後から脱退することができます。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "加入", style: .default, handler: { action in
            let roomId = self.roomArray[indexPath.section].roomId
            self.ref.child("rooms").child(roomId).child("members").child(self.userId).updateChildValues(["authority": "member"])
            self.ref.child("users").child(self.userId).child("rooms").updateChildValues([roomId: "member"])
            self.roomIdString = roomId
            self.roomNameString = self.roomArray[indexPath.section].roomName
            self.performSegue(withIdentifier: "toLVC", sender: nil)
        }))
        alert.addAction(UIAlertAction(title: "保留", style: .default))
        alert.addAction(UIAlertAction(title: "加入しない", style: .cancel, handler: { anction in
            let roomId = self.roomArray[indexPath.section].roomId
            self.ref.child("users").child(self.userId).child("rooms").child(roomId).removeValue()
            self.ref.child("rooms").child(roomId).child("members").child(self.userId).removeValue()
        }))
        self.present(alert, animated: true, completion:  nil)
    }
    
    func plusRoom() {
        if connect {
            var alertTextField: UITextField!
            let alert: UIAlertController = UIAlertController(title: "ルームの新規作成", message: "新しく作るルームの名前を入力してください。", preferredStyle: .alert)
            alert.addTextField { textField in
                alertTextField = textField
                alertTextField.returnKeyType = .done
                alertTextField.clearButtonMode = .always
                alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                alert.addAction(UIAlertAction(title: "新規作成", style: .default, handler: { action in
                    if textField.text != "" {
                        let text = textField.text!
                        let email = Auth.auth().currentUser?.email
                        self.dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        self.dateFormatter.timeZone = TimeZone(identifier: "UTC")
                        let date = self.dateFormatter.string(from: Date())
                        self.ref.child("users").child(self.userId).child("rooms").updateChildValues(["room\(date)": "administrator"])
                        self.ref.child("rooms").child("room\(date)").child("info").updateChildValues(["roomName": text, "lastEditTime": date, "lastEditor": self.userId!])
                        self.ref.child("rooms").child("room\(date)").child("members").child(self.userId!).updateChildValues(["authority": "administrator", "email": email!])
                        textField.text = ""
                    }}))}
            self.present(alert, animated: true, completion: nil)
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
    
    func menu() {
        let Items = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: "情報・設定", image: UIImage(systemName: "gearshape"), handler: { _ in
                self.performSegue(withIdentifier: "toSVC", sender: nil)})
        ])
        let signOut = UIAction(title: "ログアウト", image: UIImage(systemName: "door.right.hand.open"), attributes: .destructive, handler: { _ in self.signOut()})
        let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), options: .displayInline, children: [Items, signOut])
        signOutBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
        signOutBarButtonItem.tintColor = .label
        self.navigationItem.rightBarButtonItem = signOutBarButtonItem
    }
    
    @IBAction func plus() {
        plusRoom()
    }
    
    func signOut() {
        let alert: UIAlertController = UIAlertController(title: "本当にログアウトしますか？", message: "ログアウトすると再度ログインする必要があります。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ログアウト", style: .destructive, handler: { action in
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            self.navigationController?.popToRootViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
}
