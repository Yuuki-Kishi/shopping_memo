//
//  ViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/11/15.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate, UITableViewDelegate {
    
    let userDefaults: UserDefaults = UserDefaults.standard
    let dateFormatter = DateFormatter()
    var memoSortInt = 3
    var checkedSortInt = 2
    var checkedSwitch = false
    var removeSwitch = false
    var connect = false
    var linking = false
    
    @IBOutlet var table: UITableView!
    @IBOutlet var titleTextField: UITextField!
    var auth: Auth!
    var userId: String!
    var roomIdString: String!
    var listIdString: String!
    var listNameString: String!
    var memoIdString: String!
    var shoppingMemoName: String!
    var imageUrlString: String!
    
    @IBOutlet var menuButton: UIButton!
    var ref: DatabaseReference!
    var menuBarButtonItem: UIBarButtonItem!
    var viewModel = iPhoneViewModel()
    
    // String型の配列
    var memoArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    var checkedArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    var dataArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDelegateAndData()
        setUpTableViewAndTextField()
        menu()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeRealtimeDatabase()
        if userDefaults.bool(forKey: "notSleepSwitch") { UIApplication.shared.isIdleTimerDisabled = true }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        sendMessage(notice: "clear")
    }
    
    func setUpDelegateAndData() {
        title = listNameString
        memoSortInt = userDefaults.integer(forKey: "memoSortInt")
        checkedSortInt = userDefaults.integer(forKey: "checkedSortInt")
        checkedSwitch = userDefaults.bool(forKey: "checkedSwitch")
        userDefaults.set(linking, forKey: "linking")
        titleTextField.delegate = self
        viewModel.iPhoneDelegate = self
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
            }
        })
    }
    
    func setUpTableViewAndTextField() {
        self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを追加",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        table.dataSource = self
        table.delegate = self
        table.allowsMultipleSelection = true
        table.sectionHeaderTopPadding = 0.01
        table.estimatedSectionHeaderHeight = 0.0
        table.estimatedSectionFooterHeight = 0.0
        table.register(UINib(nibName: "CustomTableViewCell", bundle: .main), forCellReuseIdentifier: "CustomTableViewCell")
    }
    
    func observeRealtimeDatabase() {
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        memoArray = []
        checkedArray = []
        
        ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").observe(.childAdded, with: { [self] snapshot in
            GeneralPurpose.AIV(VC: self, view: view, status: "start", session: "get")
            let memoId = snapshot.key // memo0とか
            ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").observeSingleEvent(of: .value, with: { [self] snapshot in
                let memos = snapshot.childrenCount
                ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").child(memoId).observeSingleEvent(of: .value, with: { [self] snapshot in
                    guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
                    guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                    let checkedCount = (snapshot.childSnapshot(forPath: "checkedCount").value as? Int) ?? 0
                    guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
                    guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                    let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
                    guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
                    
                    dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    dateFormatter.timeZone = TimeZone(identifier: "UTC")
                    let date = dateFormatter.date(from: dateNow)
                    let time = dateFormatter.date(from: checkedTime)
                    
                    if isChecked {
                        self.checkedArray.append((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
                    } else {
                        self.memoArray.append((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
                    }
                    if memos == memoArray.count + checkedArray.count { GeneralPurpose.AIV(VC: self, view: view, status: "stop", session: "get") }
                    sort()
                })
            })
        })
        
        ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").observe(.childChanged, with: { [self] snapshot in
            let memoId = snapshot.key // memo0とか
            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
            guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
            let checkedCount = (snapshot.childSnapshot(forPath: "checkedCount").value as? Int) ?? 0
            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
            guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
            let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
            guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
            
            dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let date = dateFormatter.date(from: dateNow)
            let time = dateFormatter.date(from: checkedTime)
            
            memoSortInt = userDefaults.integer(forKey: "memoSortInt")
            linking = userDefaults.bool(forKey: "linking")
            
            if let mIndex = memoArray.firstIndex(where: {$0.memoId == memoId}) {
                if !isChecked {
                    memoArray[mIndex] = ((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
                } else {
                    memoArray.remove(at: mIndex)
                    checkedArray.append((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
                }
            } else if let cIndex = checkedArray.firstIndex(where: {$0.memoId == memoId}) {
                if isChecked {
                    checkedArray[cIndex] = ((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
                } else {
                    checkedArray.remove(at: cIndex)
                    memoArray.append((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
                }
            }
            sort()
        })
        
        ref.child("rooms").child(roomIdString).child("lists").child(listIdString).observe(.childChanged, with: { [self] snapshot in
            guard let listName = snapshot.childSnapshot(forPath: "listName").value as? String else { return }
            listNameString = listName
            title = listName
            if linking { sendMessage(notice: "sendData")}
        })
        
        //         memoの中身が消えたとき
        ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").observe(.childRemoved, with: { [self] snapshot in
            self.removeSwitch = userDefaults.bool(forKey: "removeSwitch")
            if !removeSwitch {
                let memoId = snapshot.key
                guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return }
                if isChecked {
                    guard let index = checkedArray.firstIndex(where: {$0.memoId == memoId}) else { return }
                    checkedArray.remove(at: index)
                } else {
                    guard let index = memoArray.firstIndex(where: {$0.memoId == memoId}) else { return }
                    memoArray.remove(at: index)
                }
                self.table.reloadData()
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
        
        ref.child("rooms").child(roomIdString).child("lists").observe(.childRemoved, with: { [self] snapshot in
            let listId = snapshot.key
            if listId == listIdString {
                let alert: UIAlertController = UIAlertController(title: "リストが削除されました", message: "詳しくはリストを削除したメンバーにお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true)
            }
        })
        
        ref.child("rooms").child(roomIdString).child("members").observe(.childRemoved, with: { snapshot in
            let userId = snapshot.key
            if userId == self.userId {
                let alert: UIAlertController = UIAlertController(title: "ルームを追放されました", message: "詳しくはルームの管理者にお問い合わせください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                    let viewControllers = self.navigationController?.viewControllers
                    self.navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == proposedDestinationIndexPath.section { return proposedDestinationIndexPath }
        return sourceIndexPath
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sectionCount = 0
        if !memoArray.isEmpty { sectionCount += 1 }
        if !checkedArray.isEmpty && !checkedSwitch { sectionCount += 1 }
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView,titleForHeaderInSection section: Int) -> String? {
        var sectionTitle = ""
        if tableView.numberOfSections == 2 {
            if section == 0 {
                sectionTitle = "未完了"
            } else {
                sectionTitle = "完了"
            }
        } else if tableView.numberOfSections == 1 {
            if memoArray.isEmpty {
                sectionTitle = "完了"
            } else if checkedArray.isEmpty {
                sectionTitle = "未完了"
            } else {
                sectionTitle = "未完了"
            }
        }
        return sectionTitle
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30)
        
        let title = UILabel()
        if tableView.numberOfSections == 2 {
            if section == 0 {
                title.text = "未完了"
            } else {
                title.text = "完了"
            }
        } else if tableView.numberOfSections == 1 {
            if memoArray.isEmpty {
                title.text = "完了"
            } else if checkedArray.isEmpty {
                title.text = "未完了"
            } else {
                title.text = "未完了"
            }
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
        dataArray = memoArray + checkedArray
        
        if !memoArray.isEmpty && !checkedArray.isEmpty {
            if section == 0 {
                cellCount = memoArray.count
            } else if section == 1 {
                cellCount = checkedArray.count
            }
        } else {
            cellCount = dataArray.count
        }
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell") as! CustomTableViewCell
        cell.checkDalegate = self
        cell.imageDelegate = self
        cell.indexPath = indexPath
        cell.checkMarkImageButton.isUserInteractionEnabled = !table.isEditing
        if indexPath.section == 0 {
            cell.memoLabel.text = dataArray[indexPath.row].shoppingMemo
            let imageUrl = dataArray[indexPath.row].imageUrl
            let difference = Date().timeIntervalSince(dataArray[indexPath.row].checkedTime)
            if imageUrl == "" {
                cell.imageButton.setImage(UIImage(systemName: "plus.viewfinder"), for: .normal)
                cell.imageButton.tintColor = .label
            } else {
                cell.imageButton.setImage(UIImage(systemName: "photo"), for: .normal)
                cell.imageButton.tintColor = .label
            }
            if memoArray.isEmpty {
                if difference < 60 * 60 * 6 {
                    cell.backgroundColor = .systemGray5
                } else {
                    cell.backgroundColor = .systemGray6
                }
                cell.checkMarkImageButton.setImage(UIImage(systemName: "checkmark.square"), for: .normal)
                cell.checkMarkImageButton.tintColor = .label
            } else {
                cell.backgroundColor = .systemGray6
                cell.checkMarkImageButton.setImage(UIImage(systemName: "square"), for: .normal)
                cell.checkMarkImageButton.tintColor = .label
            }
        } else if indexPath.section == 1 {
            cell.memoLabel.text = dataArray[memoArray.count + indexPath.row].shoppingMemo
            let imageUrl = dataArray[memoArray.count + indexPath.row].imageUrl
            let difference = Date().timeIntervalSince(dataArray[memoArray.count + indexPath.row].checkedTime)
            if imageUrl == "" {
                cell.imageButton.setImage(UIImage(systemName: "plus.viewfinder"), for: .normal)
                cell.imageButton.tintColor = .label
            } else {
                cell.imageButton.setImage(UIImage(systemName: "photo"), for: .normal)
                cell.imageButton.tintColor = .label
            }
            if difference < 60 * 60 * 6 {
                cell.backgroundColor = .systemGray5
            } else {
                cell.backgroundColor = .systemGray6
            }
            cell.checkMarkImageButton.setImage(UIImage(systemName: "checkmark.square"), for: .normal)
            cell.checkMarkImageButton.tintColor = .label
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var alertTextField: UITextField!
        let index = indexPath.row
        var memoId = ""
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alert: UIAlertController = UIAlertController(title: "メモの変更", message: "変更後のメモを記入してください。", preferredStyle: .alert)
        alert.addTextField { textField in
            alertTextField = textField
            alertTextField.clearButtonMode = UITextField.ViewMode.always
            alertTextField.returnKeyType = .done
            if tableView.numberOfSections == 2 {
                if indexPath.section == 0 {
                    memoId = self.memoArray[indexPath.row].memoId
                    alertTextField.text = self.memoArray[index].shoppingMemo
                } else if indexPath.section == 1 {
                    memoId = self.checkedArray[indexPath.row].memoId
                    alertTextField.text = self.checkedArray[index].shoppingMemo
                }
            } else if tableView.numberOfSections == 1 {
                if self.checkedArray.isEmpty {
                    memoId = self.memoArray[indexPath.row].memoId
                    alertTextField.text = self.memoArray[index].shoppingMemo
                } else if self.memoArray.isEmpty {
                    memoId = self.checkedArray[indexPath.row].memoId
                    alertTextField.text = self.checkedArray[index].shoppingMemo
                }
            }
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                if alertTextField.text != "" {
                    let text = alertTextField.text!
                    self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).updateChildValues(["shoppingMemo": text])
                    GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
                }}))
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if connect {
            dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let time = dateFormatter.string(from: Date())
            if titleTextField.text == "" {
                let alert: UIAlertController = UIAlertController(title: "メモを追加できません。", message: "記入欄が空白です。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").child("memo\(time)").updateChildValues(["memoCount": -1, "checkedCount": 0, "shoppingMemo": titleTextField.text!, "isChecked": false, "dateNow": time, "checkedTime": time, "imageUrl": ""])
                titleTextField.text = ""
                GeneralPurpose.updateEditHistory(roomId: roomIdString)
            }
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
        //終わりの文
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var deleteAction: UIContextualAction
        // 削除処理
        deleteAction = UIContextualAction(style: .destructive, title: "削除") { (action, view, completionHandler) in
            self.removeSwitch = true
            self.userDefaults.set(self.removeSwitch, forKey: "removeSwitch")
            if tableView.numberOfSections == 2 {
                if indexPath.section == 0 {
                    let memoId = self.memoArray[indexPath.row].memoId
                    if self.memoArray.count == 1 {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).removeValue()
                        self.memoArray.remove(at: indexPath.row)
                        tableView.deleteSections([0], with: UITableView.RowAnimation.automatic)
                        completionHandler(true)
                    } else {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).removeValue()
                        self.memoArray.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                        completionHandler(true)
                    }
                } else {
                    let memoId = self.checkedArray[indexPath.row].memoId
                    if self.checkedArray.count == 1 {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).removeValue()
                        self.checkedArray.remove(at: indexPath.row)
                        tableView.deleteSections([1], with: UITableView.RowAnimation.automatic)
                        completionHandler(true)
                    } else {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).removeValue()
                        self.checkedArray.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                        completionHandler(true)
                    }
                }
            } else if tableView.numberOfSections == 1 {
                if self.checkedArray.isEmpty {
                    let memoId = self.memoArray[indexPath.row].memoId
                    if self.memoArray.count == 1 {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).removeValue()
                        self.memoArray.remove(at: indexPath.row)
                        tableView.deleteSections([0], with: UITableView.RowAnimation.automatic)
                        completionHandler(true)
                    } else {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).removeValue()
                        self.memoArray.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                        // 実行結果に関わらず記述
                        completionHandler(true)
                    }
                } else if self.memoArray.isEmpty {
                    let memoId = self.checkedArray[indexPath.row].memoId
                    if self.checkedArray.count == 1 {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).removeValue()
                        self.checkedArray.remove(at: indexPath.row)
                        tableView.deleteSections([0], with: UITableView.RowAnimation.automatic)
                        completionHandler(true)
                    } else {
                        //削除処理を記述
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).removeValue()
                        self.checkedArray.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                        // 実行結果に関わらず記述
                        completionHandler(true)
                    }
                }
                self.removeSwitch = false
                self.userDefaults.set(self.removeSwitch, forKey: "removeSwitch")
                GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
                self.table.reloadData()
            }
        }
        // 定義したアクションをセット
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toIVVC" {
            let next = segue.destination as? ImageViewViewController
            next?.roomIdString = roomIdString
            next?.listIdString = listIdString
            next?.memoIdString = memoIdString
            next?.shoppingMemoName = shoppingMemoName
            next?.imageUrlString = imageUrlString
        }
    }
    
    func menu() {
        if table.isEditing {
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(menuBarButtonItem(_:)))
            menuBarButtonItem.tintColor = .label
        } else {
            let checkedTitle: String!
            let checkedImage: UIImage!
            let watchTitle: String!
            let watchImage: UIImage!
            let Item1 = [
                UIAction(title: "五十音順", image: UIImage(systemName: "a.circle"), handler: { _ in
                    self.memoSortInt = 0
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    self.sort()
                }),
                UIAction(title: "逆五十音順", image: UIImage(systemName: "z.circle"), handler: { _ in
                    self.memoSortInt = 1
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    self.sort()
                }),
                UIAction(title: "最近追加した順", image: UIImage(systemName: "clock"), handler: { _ in
                    self.memoSortInt = 2
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    self.sort()
                }),
                UIAction(title: "カスタム", image: UIImage(systemName: "hand.point.up"), handler: { _ in
                    self.memoSortInt = 3
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    self.sort()
                })
            ]
            
            let Item2 = [
                UIAction(title: "五十音順", image: UIImage(systemName: "a.circle"), handler: { _ in
                    self.checkedSortInt = 0
                    self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                    self.sort()
                }),
                UIAction(title: "逆五十音順", image: UIImage(systemName: "z.circle"), handler: { _ in
                    self.checkedSortInt = 1
                    self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                    self.sort()
                }),
                UIAction(title: "最近完了にした順", image: UIImage(systemName: "clock"), handler: { _ in
                    self.checkedSortInt = 2
                    self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                    self.sort()
                }),
                UIAction(title: "カスタム", image: UIImage(systemName: "hand.point.up"), handler: { _ in
                    self.checkedSortInt = 3
                    self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                    self.sort()
                })
            ]
            
            let Item3 = UIAction(title: "リストの編集", image: UIImage(systemName: "list.bullet"), handler: { _ in
                self.table.isEditing = true
                self.menu()
            })
            
            if checkedSwitch {
                checkedTitle = "完了項目を表示"
                checkedImage = UIImage(systemName: "eye")
            } else {
                checkedTitle = "完了項目を非表示"
                checkedImage = UIImage(systemName: "eye.slash")
            }
            
            let Item4 = UIAction(title: checkedTitle, image: checkedImage, handler: { _ in
                if self.checkedSwitch {
                    self.checkedSwitch = false
                } else {
                    self.checkedSwitch = true
                }
                self.userDefaults.set(self.checkedSwitch, forKey: "checkedSwitch")
                self.menu()
                self.table.reloadData()
            })
            
            if linking {
                watchTitle = "Apple Watchを切断"
                watchImage = UIImage(systemName: "applewatch.slash")
            } else {
                watchTitle = "Apple Watchに接続"
                watchImage = UIImage(systemName: "applewatch.radiowaves.left.and.right")
            }
            
            let Item5 = UIAction(title: watchTitle, image: watchImage, handler: { _ in self.watchLink()})
            
            let sort1 = UIMenu(title: "未完了を並び替え", image: UIImage(systemName: "square"),  children: Item1)
            let sort2 = UIMenu(title: "完了を並び替え", image: UIImage(systemName: "checkmark.square"), children: Item2)
            
            let Items = UIMenu(title: "", options: .displayInline, children: [sort1, sort2, Item3, Item4, Item5])
            let clear = UIAction(title: "完了項目を削除", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { _ in self.clearChecked()})
            let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), options: .displayInline, children: [Items, clear])
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
            menuBarButtonItem.tintColor = .label
        }
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
    }
    
    @objc func menuBarButtonItem(_ sender: UIBarButtonItem) {
        table.isEditing = false
        menu()
    }
    
    func watchLink() {
        if linking {
            let alert: UIAlertController = UIAlertController(title: "Apple Watchとの通信を切断しますか？", message: "再度利用するには再度接続する必要があります。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "切断", style: .destructive, handler: { anction in
                self.sendMessage(notice: "clear")
                GeneralPurpose.AIV(VC: self, view: self.view, status: "start", session: "other")
            }))
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert: UIAlertController = UIAlertController(title: "Apple Watchは接続されていますか？", message: "このデバイスに接続されていないとデータを送ることができません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { anction in
                self.sendMessage(notice: "sendData")
                GeneralPurpose.AIV(VC: self, view: self.view, status: "stop", session: "other")
            }))
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: - sendMessage
    func sendMessage(notice: String) {
        if notice == "sendData" || notice == "reloadData" {
            let messages: [String: Any] = ["notice": notice, "listName": self.listNameString!, "memoId": self.memoArray.map {$0.memoId}, "shoppingMemo": self.memoArray.map {$0.shoppingMemo}, "imageUrl": self.memoArray.map {$0.imageUrl}]
            self.viewModel.session.sendMessage(messages, replyHandler: nil) { (error) in
                print(error.localizedDescription)
            }
        } else if notice == "clear" {
            let messages = ["notice": "clear"]
            self.viewModel.session.sendMessage(messages, replyHandler: nil) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func reply() {
        self.linking = true
        self.userDefaults.set(self.linking, forKey: "linking")
        menu()
        GeneralPurpose.AIV(VC: self, view: self.view, status: "start", session: "other")
        let alert: UIAlertController = UIAlertController(title: "Apple Watchと接続しました", message: "画面を移動すると接続は切断されます。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
    func signalCut() {
        self.linking = false
        self.userDefaults.set(self.linking, forKey: "linking")
        menu()
        GeneralPurpose.AIV(VC: self, view: self.view, status: "stop", session: "other")
        let alert: UIAlertController = UIAlertController(title: "Apple Watchとの通信を切断しました", message: "再度使用するには再度接続してください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController {
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if tableView.numberOfSections == 2 {
            if sourceIndexPath.section == 0 {
                memoSortInt = 3
                userDefaults.set(memoSortInt, forKey: "memoSortInt")
                let memo = memoArray[sourceIndexPath.row]
                memoArray.remove(at: sourceIndexPath.row)
                memoArray.insert(memo, at: destinationIndexPath.row)
                memoArraySort()
            } else {
                checkedSortInt = 3
                userDefaults.set(checkedSortInt, forKey: "checkedSortInt")
                let memo = checkedArray[sourceIndexPath.row]
                checkedArray.remove(at: sourceIndexPath.row)
                checkedArray.insert(memo, at: destinationIndexPath.row)
                checkedArraySort()
            }
        } else if tableView.numberOfSections == 1 {
            if checkedArray.isEmpty {
                memoSortInt = 3
                userDefaults.set(memoSortInt, forKey: "memoSortInt")
                let memo = memoArray[sourceIndexPath.row]
                memoArray.remove(at: sourceIndexPath.row)
                memoArray.insert(memo, at: destinationIndexPath.row)
                memoArraySort()
            } else if memoArray.isEmpty {
                checkedSortInt = 3
                userDefaults.set(checkedSortInt, forKey: "checkedSortInt")
                let memo = checkedArray[sourceIndexPath.row]
                checkedArray.remove(at: sourceIndexPath.row)
                checkedArray.insert(memo, at: destinationIndexPath.row)
                checkedArraySort()
            } else {
                memoSortInt = 3
                userDefaults.set(memoSortInt, forKey: "memoSortInt")
                let memo = memoArray[sourceIndexPath.row]
                memoArray.remove(at: sourceIndexPath.row)
                memoArray.insert(memo, at: destinationIndexPath.row)
                memoArraySort()
            }
        }
        GeneralPurpose.updateEditHistory(roomId: roomIdString)
    }
    
    func memoArraySort() {
        for i in 0 ..< memoArray.count {
            let memoId = memoArray[i].memoId
            memoArray[i].memoCount = i
            self.ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").child(memoId).updateChildValues(["memoCount": i])
        }
    }
    
    func checkedArraySort() {
        for i in 0 ..< checkedArray.count {
            let memoId = checkedArray[i].memoId
            checkedArray[i].checkedCount = i
            self.ref.child("rooms").child(roomIdString).child("lists").child(listIdString).child("memo").child(memoId).updateChildValues(["checkedCount": i])
        }
    }
    
    func sort() {
        switch memoSortInt {
        case 0:
            memoArray.sort {$0.shoppingMemo < $1.shoppingMemo}
        case 1:
            memoArray.sort {$0.shoppingMemo > $1.shoppingMemo}
        case 2:
            memoArray.sort {$0.dateNow > $1.dateNow}
        default:
            memoArray.sort {$0.memoCount < $1.memoCount}
        }
        
        switch checkedSortInt {
        case 0:
            checkedArray.sort {$0.shoppingMemo < $1.shoppingMemo}
        case 1:
            checkedArray.sort {$0.shoppingMemo > $1.shoppingMemo}
        case 2:
            checkedArray.sort {$0.checkedTime > $1.checkedTime}
        default:
            checkedArray.sort {$0.checkedCount < $1.checkedCount}
        }
        if linking { sendMessage(notice: "reloadData") }
        self.table.reloadData()
    }
    
    func clearChecked() {
        if self.checkedArray.count != 0 {
            if self.connect {
                let alert: UIAlertController = UIAlertController(title: "本当に削除しますか？", message: "この操作は取り消すことができません。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "削除", style: .destructive, handler: { action in
                    self.removeSwitch = true
                    self.userDefaults.set(self.removeSwitch, forKey: "removeSwitch")
                    for i in 0...self.checkedArray.count - 1 {
                        let memoId = self.checkedArray[i].memoId
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).removeValue()
                    }
                    self.checkedArray.removeAll()
                    GeneralPurpose.updateEditHistory(roomId: self.roomIdString)
                    self.table.reloadData()
                }))
                alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                self.present(alert, animated: true, completion: nil)
            } else {
                GeneralPurpose.notConnectAlert(VC: self)
            }
        } else {
            let alert: UIAlertController = UIAlertController(title: "削除できません", message: "削除できる完了項目がありません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
        self.removeSwitch = false
        self.userDefaults.set(self.removeSwitch, forKey: "removeSwitch")
    }
}

extension ViewController {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension ViewController: checkMarkDelegete {
    func buttonPressed(indexPath: IndexPath) {
        print("⤴️buttonPressed成功!")
        let cell = table.dequeueReusableCell(withIdentifier: "CustomTableViewCell") as! CustomTableViewCell
        if connect {
            if self.table.numberOfSections == 2 {
                if indexPath.section == 0 {
                    cell.checkMarkImageButton.setImage(nil, for: .normal)
                    let memoId = memoArray[indexPath.row].memoId
                    let isChecked = memoArray[indexPath.row].isChecked
                    let cTime = dateFormatter.string(from: Date())
                    self.memoSortInt = 3
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).updateChildValues(["isChecked": !isChecked, "checkedTime": cTime])
                    }
                } else if indexPath.section == 1 {
                    cell.checkMarkImageButton.setImage(nil, for: .normal)
                    let memoId = checkedArray[indexPath.row].memoId
                    let isChecked = checkedArray[indexPath.row].isChecked
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).updateChildValues(["isChecked": !isChecked])
                    }
                }
            } else if self.table.numberOfSections == 1 {
                if !self.memoArray.isEmpty {
                    let memoId = memoArray[indexPath.row].memoId
                    let isChecked = memoArray[indexPath.row].isChecked
                    let cTime = dateFormatter.string(from: Date())
                    self.memoSortInt = 3
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).updateChildValues(["isChecked": !isChecked, "checkedTime": cTime])
                    }
                } else if !self.checkedArray.isEmpty {
                    cell.checkMarkImageButton.setImage(nil, for: .normal)
                    let memoId = checkedArray[indexPath.row].memoId
                    let isChecked = checkedArray[indexPath.row].isChecked
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("rooms").child(self.roomIdString).child("lists").child(self.listIdString).child("memo").child(memoId).updateChildValues(["isChecked": !isChecked])
                    }
                }
            }
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
            table.reloadData()
        }
    }
}

extension ViewController: imageButtonDelegate {
    func buttonTapped(indexPath: IndexPath) {
        print("⤴️buttonTapped成功!")
        if connect {
            if table.numberOfSections == 2 {
                if indexPath.section == 0 {
                    self.memoIdString = memoArray[indexPath.row].memoId
                    self.shoppingMemoName = memoArray[indexPath.row].shoppingMemo
                    self.imageUrlString = memoArray[indexPath.row].imageUrl
                } else {
                    self.memoIdString = checkedArray[indexPath.row].memoId
                    self.shoppingMemoName = checkedArray[indexPath.row].shoppingMemo
                    self.imageUrlString = checkedArray[indexPath.row].imageUrl
                }
            } else if table.numberOfSections == 1 {
                if self.checkedArray.isEmpty {
                    self.memoIdString = memoArray[indexPath.row].memoId
                    self.shoppingMemoName = memoArray[indexPath.row].shoppingMemo
                    self.imageUrlString = memoArray[indexPath.row].imageUrl
                } else if self.memoArray.isEmpty {
                    self.memoIdString = checkedArray[indexPath.row].memoId
                    self.shoppingMemoName = checkedArray[indexPath.row].shoppingMemo
                    self.imageUrlString = checkedArray[indexPath.row].imageUrl
                }
            }
            self.performSegue(withIdentifier: "toIVVC", sender: nil)
        } else {
            GeneralPurpose.notConnectAlert(VC: self)
        }
    }
}

extension ViewController: iPhoneViewModelDelegate {
    func check(indexPath: IndexPath) { buttonPressed(indexPath: indexPath) }
    func getData() { reply() }
    func cleared() { signalCut() }
}
