//
//  MemberViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/13.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class MemberViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var plusButton: UIButton!
    
    var ref: DatabaseReference!
    var dateFormatter = DateFormatter()
    var connect: Bool!
    var userId: String!
    var roomIdString: String!
    var myAuthority: String!
    var administratorArray = [(administratorId: String, administratorName: String, administratorEmail: String)]()
    var memberArray = [(memberId: String, memberName: String, memberEmail: String)]()
    var guestArray = [(guestId: String, guestName: String, guestEmail: String)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observeRealtimeDatabase()
    }
    
    func setUp() {
        title = "メンバー"
        plusButton.layer.cornerRadius = 35.0
        tableView.register(UINib(nibName: "SettingTableViewCell", bundle: nil), forCellReuseIdentifier: "SettingTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
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
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        ref.child("rooms").child(roomIdString).child("members").observe(.childAdded, with: { [self] snapshot in
            GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "get")
            let userId = snapshot.key
            ref.child("rooms").child(roomIdString).child("members").observeSingleEvent(of: .value, with: { [self] snapshot in
                let userCount = snapshot.childrenCount
                ref.child("rooms").child(roomIdString).child("members").child(userId).observeSingleEvent(of: .value, with: { [self] snapshot in
                    guard let authority = snapshot.childSnapshot(forPath: "authority").value as? String else { return }
                    if userId == self.userId {myAuthority = authority}
                    let email = (snapshot.childSnapshot(forPath: "email").value as? String) ?? ""
                    ref.child("users").child(userId).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
                        guard let userName = snapshot.childSnapshot(forPath: "userName").value as? String else { return }
                        if authority == "administrator" {
                            let isContain = administratorArray.contains(where: {$0.administratorId == userId})
                            if !isContain { administratorArray.append((administratorId: userId, administratorName: userName, administratorEmail: email)) }
                        } else if authority == "member" {
                            let isContain = memberArray.contains(where:  {$0.memberId == userId})
                            if !isContain {
                                memberArray.append((memberId: userId, memberName: userName, memberEmail: email))
                                memberArray.sort {$0.memberName < $1.memberName}
                            }
                        } else if authority == "guest" {
                            let isContain = guestArray.contains(where: {$0.guestId == userId})
                            if !isContain {
                                guestArray.append((guestId: userId, guestName: userName, guestEmail: email))
                                guestArray.sort {$0.guestName < $1.guestName}
                            }
                        }
                        if myAuthority != "administrator" { plusButton.isHidden = true }
                        if userCount == administratorArray.count + memberArray.count + guestArray.count {
                            GeneralPurpose.AIV(VC: self, view: view, status: "stop", session: "get")
                        }
                        tableView.reloadData()
                    })
                })
            })
        })
        
        ref.child("rooms").child(roomIdString).child("members").observe(.childChanged, with: { [self] snapshot in
            let userId = snapshot.key
            guard let email = snapshot.childSnapshot(forPath: "email").value as? String else { return }
            if let index = guestArray.firstIndex(where: {$0.guestId == userId}) {
                let userName = guestArray[index].guestName
                guestArray.remove(at: index)
                memberArray.append((memberId: userId, memberName: userName, memberEmail: email))
                tableView.reloadData()
            }
        })
        
        ref.child("users").observe(.childChanged, with: { [self] snapshot in
            let Id = snapshot.key
            ref.child("rooms").child(roomIdString).child("members").observe(.childAdded, with: { [self] snapshot in
                let userId = snapshot.key
                if userId == Id {
                    ref.child("users").child(Id).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
                        guard let userName = snapshot.childSnapshot(forPath: "userName").value as? String else { return }
                            if let index = administratorArray.firstIndex(where: {$0.administratorId == Id}) {
                                administratorArray[index].administratorName = userName
                            }
                            if let index = memberArray.firstIndex(where: {$0.memberId == Id}) {
                                memberArray[index].memberName = userName
                            }
                            if let index = guestArray.firstIndex(where: {$0.guestId == Id}) {
                                guestArray[index].guestName = userName
                            }
                            tableView.reloadData()
                        })}})})
        
        ref.child("rooms").child(roomIdString).child("members").observe(.childRemoved, with: { [self] snapshot in
            let userId = snapshot.key
            guard let authority = snapshot.childSnapshot(forPath: "authority").value as? String else { return }
            if userId == self.userId {
                let alert: UIAlertController = UIAlertController(title: "ルームを追放されました", message: "詳しくはルームの管理者にお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    let viewControllers = self.navigationController?.viewControllers
                    self.navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                if authority == "member" {
                    if let mIndex = memberArray.firstIndex(where: {$0.memberId == userId}) { memberArray.remove(at: mIndex) }
                } else if authority == "guest" {
                    if let gIndex = guestArray.firstIndex(where: {$0.guestId == userId}) { guestArray.remove(at: gIndex) }
                }
                tableView.reloadData()
            }
        })
        
        ref.child("rooms").observe(.childRemoved, with: { [self] snapshot in
            let roomId = snapshot.key
            if roomId == roomIdString {
                let alert: UIAlertController = UIAlertController(title: "ルームが削除されました", message: "詳しくはルームの管理者にお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    let viewControllers = self.navigationController?.viewControllers
                    self.navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sectionCount = 1
        if !memberArray.isEmpty {sectionCount += 1}
        if !guestArray.isEmpty {sectionCount += 1}
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30)
        
        let title = UILabel()
        if section == 0 {
            title.text = "管理者"
        } else if section == 1 {
            if guestArray.isEmpty {
                title.text = "メンバー"
            } else if memberArray.isEmpty {
                title.text = "招待中"
            } else {
                title.text = "メンバー"
            }
        } else {
            title.text = "招待中"
        }
        title.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        title.textColor = .label
        title.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        title.sizeToFit()
        headerView.addSubview(title)

        title.translatesAutoresizingMaskIntoConstraints = false
        title.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        title.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true

        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cellCount = 0
        if section == 0 {
            cellCount = administratorArray.count
        } else if section == 1 {
            if guestArray.isEmpty {
                cellCount = memberArray.count
            } else if memberArray.isEmpty {
                cellCount = guestArray.count
            } else {
                cellCount = memberArray.count
            }
        } else {
            cellCount = guestArray.count
        }
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell") as! SettingTableViewCell
        if section == 0 {
            cell.ItemLabel.text = administratorArray[indexPath.row].administratorName
            cell.DataLabel.text = administratorArray[indexPath.row].administratorEmail
            let userId = administratorArray[indexPath.row].administratorId
            if userId == self.userId {cell.ItemLabel.textColor = .systemGreen; cell.ItemLabel.font = UIFont.boldSystemFont(ofSize: 15)}
            else {cell.ItemLabel.textColor = .label; cell.ItemLabel.font = UIFont.systemFont(ofSize: 15)}
            cell.selectionStyle = .none
        } else if section == 1 {
            if guestArray.isEmpty {
                cell.ItemLabel.text = memberArray[indexPath.row].memberName
                cell.DataLabel.text = memberArray[indexPath.row].memberEmail
                let userId = memberArray[indexPath.row].memberId
                if userId == self.userId {cell.ItemLabel.textColor = .systemGreen; cell.ItemLabel.font = UIFont.boldSystemFont(ofSize: 15)}
                else {cell.ItemLabel.textColor = .label; cell.ItemLabel.font = UIFont.systemFont(ofSize: 15)}
            } else if memberArray.isEmpty {
                cell.ItemLabel.text = guestArray[indexPath.row].guestName
                cell.DataLabel.text = guestArray[indexPath.row].guestEmail
                let userId = guestArray[indexPath.row].guestId
                if userId == self.userId {cell.ItemLabel.textColor = .systemGreen; cell.ItemLabel.font = UIFont.boldSystemFont(ofSize: 15)}
                else {cell.ItemLabel.textColor = .label; cell.ItemLabel.font = UIFont.systemFont(ofSize: 15)}
            } else {
                cell.ItemLabel.text = memberArray[indexPath.row].memberName
                cell.DataLabel.text = memberArray[indexPath.row].memberEmail
                let userId = memberArray[indexPath.row].memberId
                if userId == self.userId {cell.ItemLabel.textColor = .systemGreen; cell.ItemLabel.font = UIFont.boldSystemFont(ofSize: 15)}
                else {cell.ItemLabel.textColor = .label; cell.ItemLabel.font = UIFont.systemFont(ofSize: 15)}
            }
        } else {
            cell.ItemLabel.text = guestArray[indexPath.row].guestName
            cell.DataLabel.text = guestArray[indexPath.row].guestEmail
            let userId = guestArray[indexPath.row].guestId
            if userId == self.userId {cell.ItemLabel.textColor = .systemGreen; cell.ItemLabel.font = UIFont.boldSystemFont(ofSize: 15)}
            else {cell.ItemLabel.textColor = .label; cell.ItemLabel.font = UIFont.systemFont(ofSize: 15)}
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if connect {
            if myAuthority == "administrator" {
                if indexPath.section == 0 {
                    return UISwipeActionsConfiguration(actions: [])
                } else if indexPath.section == 1 {
                    if guestArray.isEmpty {
                        let memberId = memberArray[indexPath.row].memberId
                        return userDeleteSwipe(userId: memberId, indexPath: indexPath)
                    } else if memberArray.isEmpty {
                        let guestId = guestArray[indexPath.row].guestId
                        return userDeleteSwipe(userId: guestId, indexPath: indexPath)
                    } else {
                        let memberId = memberArray[indexPath.row].memberId
                        return userDeleteSwipe(userId: memberId, indexPath: indexPath)
                    }
                } else {
                    let guestId = guestArray[indexPath.row].guestId
                    return userDeleteSwipe(userId: guestId, indexPath: indexPath)
                }
            }
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
            return UISwipeActionsConfiguration(actions: [])
        }
        return UISwipeActionsConfiguration(actions: [])
    }
    
    func userDeleteSwipe(userId: String, indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var deleteAction: UIContextualAction
        deleteAction = UIContextualAction(style: .destructive, title: "追放") { (action, view, completionHandler) in
            let alert: UIAlertController = UIAlertController(title: "本当に追放しますか？", message: "追放された人はこのルームに入れなくなります。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "追放", style: .destructive, handler:  { actioin in
                self.ref.child("rooms").child(self.roomIdString).child("members").child(userId).removeValue()
                self.ref.child("users").child(userId).child("rooms").child(self.roomIdString).removeValue()
                if self.guestArray.isEmpty {
                    if self.memberArray.count == 1 {
                        self.memberArray.remove(at: indexPath.row)
                        self.tableView.deleteSections([indexPath.section], with: UITableView.RowAnimation.automatic)
                    } else {
                        self.memberArray.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                    }
                } else if self.memberArray.isEmpty {
                    if self.guestArray.count == 1 {
                        self.guestArray.remove(at: indexPath.row)
                        self.tableView.deleteSections([indexPath.section], with: UITableView.RowAnimation.automatic)
                    } else {
                        self.guestArray.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                    }
                } else {
                    if indexPath.section == 1 {
                        if self.memberArray.count == 1 {
                            self.memberArray.remove(at: indexPath.row)
                            self.tableView.deleteSections([indexPath.section], with: UITableView.RowAnimation.automatic)
                        } else {
                            self.memberArray.remove(at: indexPath.row)
                            self.tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                        }
                    } else if indexPath.section == 2 {
                        if self.guestArray.count == 1 {
                            self.guestArray.remove(at: indexPath.row)
                            self.tableView.deleteSections([indexPath.section], with: UITableView.RowAnimation.automatic)
                        } else {
                            self.guestArray.remove(at: indexPath.row)
                            self.tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                        }
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            // 実行結果に関わらず記述
            completionHandler(true)
            self.present(alert, animated: true)
        }
        self.tableView.reloadData()
        // 定義したアクションをセット
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "toQRCRVC" {
            let next = segue.destination as? QRCodeReadViewController
            next?.roomIdString = roomIdString
        }
    }
    
    @IBAction func memberPlus() {
        let alert: UIAlertController = UIAlertController(title: "メンバーを追加", message: "メンバーを追加する方法を選択してください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        alert.addAction(UIAlertAction(title: "QRコード", style: .default, handler: { action in
                    self.performSegue(withIdentifier: "toQRCRVC", sender: true)
                }))
        alert.addAction(UIAlertAction(title: "手入力", style: .default, handler: { action in
                    self.handyPlus()
                }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func handyPlus() {
        var alertTextField: UITextField!
        let alert: UIAlertController = UIAlertController(title: "メンバーを追加", message: "追加したい人のユーザーIDを入力してください。", preferredStyle: .alert)
        alert.addTextField { textField in
            alertTextField = textField
            alertTextField.clearButtonMode = UITextField.ViewMode.always
            alertTextField.returnKeyType = .done
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                if alertTextField.text != "" {
                    let text = alertTextField.text
                    var trueId = false
                    self.ref.child("users").child(text!).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
                        guard let email = snapshot.childSnapshot(forPath: "email").value as? String else { self.afterAddAlert(trueId: trueId); return }
                        ref.child("rooms").child(roomIdString).child("members").child(text!).updateChildValues(["authority": "guest", "email": email])
                        ref.child("users").child(text!).child("rooms").updateChildValues(["\(roomIdString!)": "guest"])
                        trueId = true
                        self.afterAddAlert(trueId: trueId)
                    })
                }}))}
        self.present(alert, animated: true, completion: nil)
    }
    
    func afterAddAlert(trueId: Bool) {
        if trueId {
            let alert: UIAlertController = UIAlertController(title: "招待が完了しました", message: "右からスワイプすることで招待を取り消すことができます。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert: UIAlertController = UIAlertController(title: "招待できません", message: "招待できる人のIDではありません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
