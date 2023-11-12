//
//  RoomViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/11.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class RoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var plusButton: UIButton!
    @IBOutlet var tableView: UITableView!
    
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
        setUpNavigation()
        tableViewSetUp()
        UISetUp()
        menu()
        setUpData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observeRealtimeDatabase()
    }
    
    func setUpNavigation() {
        title = "ホーム"
        navigationItem.hidesBackButton = true
    }
    
    func tableViewSetUp() {
        tableView.register(UINib(nibName: "RoomTableViewCell", bundle: nil), forCellReuseIdentifier: "RoomTableViewCell")
        
        tableView.delegate = self
        tableView.dataSource = self
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
        
        ref.child("users").child(userId).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
            var email = snapshot.childSnapshot(forPath: "email").value as? String
            let userName = snapshot.childSnapshot(forPath: "userName").value as? String
            if email == nil {
                email = Auth.auth().currentUser?.email
                self.ref.child("users").child(self.userId).child("metadata").updateChildValues(["email": email!])
            }
            if userName == nil { self.ref.child("users").child(self.userId).child("metadata").updateChildValues(["userName": "未設定"]) }
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
        guestArray = []
        otherArray = []
        
        ref.child("users").child(userId).child("rooms").observe(.childAdded, with: { [self] snapshot in
            GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "get")
            let roomId = snapshot.key
            ref.child("users").child(userId).child("rooms").observeSingleEvent(of: .value, with: { [self] snapshot in
                let roomCount = snapshot.childrenCount
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        roomArray = guestArray + otherArray
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
