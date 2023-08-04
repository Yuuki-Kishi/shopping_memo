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
    var changedSwitch = false
    var checkedSwitch = false
    var removeSwitch = false
    var connect = false
    var name: String!
    var memoIdString: String!
    var imageUrlString: String!
    
    @IBOutlet var table: UITableView!
    @IBOutlet var titleTextField: UITextField!
    var auth: Auth!
    var userId: String!
    var list: String!
    var shoppingMemoName: String!
    
    @IBOutlet var menuButton: UIButton!
    let checked = "チェック済み"
    let nonCheck = "未チェック"
    let memo = "memo"
    var ref: DatabaseReference!
    var menuBarButtonItem: UIBarButtonItem!

    // String型の配列
    var memoArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
        
    var checkedArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    var dataArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = name
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]

        menu()
        
        memoSortInt = userDefaults.integer(forKey: "memoSortInt")
        checkedSortInt = userDefaults.integer(forKey: "checkedSortInt")
        checkedSwitch = userDefaults.bool(forKey: "checkedSwitch")
        
        self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを追加",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 184/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        ref = Database.database().reference()
        
        userId = Auth.auth().currentUser?.uid

        table.dataSource = self
        table.delegate = self
                                
        table.register(UINib(nibName: "CustomTableViewCell", bundle: .main), forCellReuseIdentifier: "CustomTableViewCell")
        
        titleTextField.delegate = self
                
        memoArray = []
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connect = true
            } else {
                self.connect = false
        }})
        
        // nonCheckに追加されたとき、firebaseのデータを引っ張ってくる
        ref.child("users").child(userId).child(list).child(nonCheck).observe(.childAdded, with: { [self] snapshot in
            let memoId = snapshot.key // memo0とか
            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
            guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
            let checkedCount = (snapshot.childSnapshot(forPath: "checkedCount").value as? Int) ?? 0
            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
            guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
            let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
            guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
                        
            ref.child("users").child(userId).child(list).child(nonCheck).child(memoId).removeValue()
            ref.child("users").child(userId).child(list).child(memo).child(memoId).updateChildValues(["memoCount": memoCount, "checkedCount": checkedCount, "shoppingMemo": shoppingMemo, "isChecked": isChecked, "dateNow": dateNow, "checkedTime": checkedTime, "imageUrl": imageUrl])
            
            sort()
        })
        
        ref.child("users").child(userId).child(list).child(checked).observe(.childAdded, with: { [self] snapshot in
            let memoId = snapshot.key // memo0とか
            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
            guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
            let checkedCount = (snapshot.childSnapshot(forPath: "checkedCount").value as? Int) ?? 0
            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
            guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
            let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
            guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
                        
            ref.child("users").child(userId).child(list).child(checked).child(memoId).removeValue()
            ref.child("users").child(userId).child(list).child(memo).child(memoId).updateChildValues(["memoCount": memoCount, "checkedCount": checkedCount, "shoppingMemo": shoppingMemo, "isChecked": isChecked, "dateNow": dateNow, "checkedTime": checkedTime, "imageUrl": imageUrl])
            
            sort()
        })
        
        ref.child("users").child(userId).child(list).child(memo).observe(.childAdded, with: { [self] snapshot in
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
            let time = date
            
            if isChecked {
                self.checkedArray.append((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
            } else {
                self.memoArray.append((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
            }
            
            sort()
        })
        
        ref.child("users").child(userId).child(list).child(memo).observe(.childChanged, with: { [self] snapshot in
            changedSwitch = userDefaults.bool(forKey: "changedSwitch")
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
            let time = Date()
            
            memoSortInt = userDefaults.integer(forKey: "memoSortInt")
            
            if changedSwitch {
                if isChecked {
                    let index = memoArray.firstIndex(where: {$0.memoId == memoId})
                    memoArray.remove(at: index!)
                    checkedArray.append((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time, imageUrl: imageUrl))
                } else {
                    let index = checkedArray.firstIndex(where: {$0.memoId == memoId})
                    checkedArray.remove(at: index!)
                    memoArray.append((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time, imageUrl: imageUrl))
                }
                changedSwitch = false
                userDefaults.set(changedSwitch, forKey: "changedSwitch")
            } else {
                if isChecked {
                    let mIndex = memoArray.firstIndex(where: {$0.memoId == memoId})
                    let cIndex = checkedArray.firstIndex(where: {$0.memoId == memoId})
                    if cIndex == nil {
                        memoArray.remove(at: mIndex!)
                        checkedArray.append((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time, imageUrl: imageUrl))
                    } else {
                        checkedArray[cIndex!] = ((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time, imageUrl: imageUrl))
                    }
                } else {
                    let mIndex = memoArray.firstIndex(where: {$0.memoId == memoId})
                    let cIndex = checkedArray.firstIndex(where: {$0.memoId == memoId})
                    if mIndex == nil {
                        checkedArray.remove(at: cIndex!)
                        memoArray.append((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time, imageUrl: imageUrl))
                    } else {
                        memoArray[mIndex!] = ((memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time, imageUrl: imageUrl))
                    }
                }
            }
            sort()
        })
        
//         memoの中身が消えたとき
        ref.child("users").child(userId).child(list).child(memo).observe(.childRemoved, with: { [self] snapshot in
            self.removeSwitch = userDefaults.bool(forKey: "removeSwitch")
            if !removeSwitch {
                let memoId = snapshot.key
                guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return }
                if isChecked {
                    let index = checkedArray.firstIndex(where: {$0.memoId == memoId})
                    checkedArray.remove(at: index!)
                } else {
                    let index = memoArray.firstIndex(where: {$0.memoId == memoId})
                    memoArray.remove(at: index!)
                }
                self.table.reloadData()
            }
        })

        table.allowsMultipleSelection = true
        table.sectionHeaderTopPadding = 0.01
        table.sectionFooterHeight = 0.0
        table.estimatedSectionHeaderHeight = 0.0
        table.estimatedSectionFooterHeight = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        ref.child("users").child(userId).child(list).observe(.childChanged, with: { [self] snapshot in
            guard let listName = snapshot.childSnapshot(forPath: "listName").value as? String else { return }
            name = listName
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        }
        return sourceIndexPath
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sectionCount = 0
        if !memoArray.isEmpty {
            sectionCount += 1
        }
        if !checkedArray.isEmpty && !checkedSwitch {
            sectionCount += 1
        }
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
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
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
        title.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20).isActive = true

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
            if imageUrl == "" {
                cell.imageButton.setImage(UIImage(systemName: "plus.viewfinder"), for: .normal)
                cell.imageButton.tintColor = .label
            } else {
                cell.imageButton.setImage(UIImage(systemName: "photo"), for: .normal)
                cell.imageButton.tintColor = .label
            }
            cell.checkMarkImageButton.setImage(UIImage(systemName: "square"), for: .normal)
            cell.checkMarkImageButton.tintColor = .label
        } else if indexPath.section == 1 {
            cell.memoLabel.text = dataArray[memoArray.count + indexPath.row].shoppingMemo
            let imageUrl = dataArray[memoArray.count + indexPath.row].imageUrl
            if imageUrl == "" {
                cell.imageButton.setImage(UIImage(systemName: "plus.viewfinder"), for: .normal)
                cell.imageButton.tintColor = .label
            } else {
                cell.imageButton.setImage(UIImage(systemName: "photo"), for: .normal)
                cell.imageButton.tintColor = .label
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
        var isCheckedBool: Bool!
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
                    isCheckedBool = false
                } else if indexPath.section == 1 {
                    memoId = self.checkedArray[indexPath.row].memoId
                    alertTextField.text = self.checkedArray[index].shoppingMemo
                    isCheckedBool = true
                }
            } else if tableView.numberOfSections == 1 {
                if self.checkedArray.isEmpty {
                    memoId = self.memoArray[indexPath.row].memoId
                    alertTextField.text = self.memoArray[index].shoppingMemo
                    isCheckedBool = false
                } else if self.memoArray.isEmpty {
                    memoId = self.checkedArray[indexPath.row].memoId
                    alertTextField.text = self.checkedArray[index].shoppingMemo
                    isCheckedBool = true
                }
            }
            
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        if alertTextField.text != "" {
                            let text = alertTextField.text!
                            if isCheckedBool {
                                self.checkedArray[index].shoppingMemo = text
                            } else {
                                self.memoArray[index].shoppingMemo = text
                            }
                            self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["shoppingMemo": text])
                            self.table.reloadData()
                        }
                    })
                )
            alert.addAction(
                UIAlertAction(
                    title: "キャンセル",
                    style: .cancel
                ))
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
                alert.addAction(
                    UIAlertAction(
                        title: "OK",
                        style: .default,
                        handler: { action in
                        }
                    )
                )
                self.present(alert, animated: true, completion: nil)
            } else {
                self.ref.child("users").child(userId).child(list).child(memo).child("memo\(time)").updateChildValues(["memoCount": -1, "checkedCount": 0, "shoppingMemo": titleTextField.text!, "isChecked": false, "dateNow": time, "checkedTime": time, "imageUrl": ""])
                titleTextField.text = ""
            }
        } else {
            alert()
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
                    //削除処理を記述
                    self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).removeValue()
                    self.memoArray.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                    // 実行結果に関わらず記述
                    completionHandler(true)
                } else {
                    let memoId = self.checkedArray[indexPath.row].memoId
                    //削除処理を記述
                    self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).removeValue()
                    self.checkedArray.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                    // 実行結果に関わらず記述
                    completionHandler(true)
                }
            } else if tableView.numberOfSections == 1 {
                if self.checkedArray.isEmpty {
                    let memoId = self.memoArray[indexPath.row].memoId
                    //削除処理を記述
                    self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).removeValue()
                    self.memoArray.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                    // 実行結果に関わらず記述
                    completionHandler(true)
                } else if self.memoArray.isEmpty {
                    let memoId = self.checkedArray[indexPath.row].memoId
                    //削除処理を記述
                    self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).removeValue()
                    self.checkedArray.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                    // 実行結果に関わらず記述
                    completionHandler(true)
                }
                self.removeSwitch = false
                self.userDefaults.set(self.removeSwitch, forKey: "removeSwitch")
                self.table.reloadData()
            }
        }
        // 定義したアクションをセット
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toImageViewVC" {
            let next = segue.destination as? ImageViewViewController
            next?.shoppingMemoName = shoppingMemoName
            next?.memoIdString = memoIdString
            next?.list = list
            next?.imageUrlString = imageUrlString
        }
    }
    
    func menu() {
        if table.isEditing {
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .done, target: self, action: #selector(menuBarButtonItem(_:)))
            menuBarButtonItem.tintColor = .black
        } else {
            let title: String!
            let image: UIImage!
            let Item1 = [
                UIAction(title: "五十音順", image: UIImage(systemName: "a.circle"), handler: { _ in
                    self.memoSortInt = 0
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    self.memoArray.sort {$0.shoppingMemo < $1.shoppingMemo}
                    self.table.reloadData()
                }),
                UIAction(title: "逆五十音順", image: UIImage(systemName: "z.circle"), handler: { _ in
                    self.memoSortInt = 1
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    self.memoArray.sort {$0.shoppingMemo > $1.shoppingMemo}
                    self.table.reloadData()
                }),
                UIAction(title: "最近追加した順", image: UIImage(systemName: "clock"), handler: { _ in
                    self.memoSortInt = 2
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    self.memoArray.sort {$0.dateNow > $1.dateNow}
                    self.table.reloadData()
                }),
                UIAction(title: "カスタム", image: UIImage(systemName: "hand.point.up"), handler: { _ in
                    self.memoSortInt = 3
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    self.memoArray.sort {$0.memoCount < $1.memoCount}
                    self.table.reloadData()
                })
            ]
            
            let Item2 = [
                UIAction(title: "五十音順", image: UIImage(systemName: "a.circle"), handler: { _ in
                    self.checkedSortInt = 0
                    self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                    self.checkedArray.sort {$0.shoppingMemo < $1.shoppingMemo}
                    self.table.reloadData()
                }),
                UIAction(title: "逆五十音順", image: UIImage(systemName: "z.circle"), handler: { _ in
                    self.checkedSortInt = 1
                    self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                    self.checkedArray.sort {$0.shoppingMemo > $1.shoppingMemo}
                    self.table.reloadData()
                }),
                UIAction(title: "最近完了にした順", image: UIImage(systemName: "clock"), handler: { _ in
                    self.checkedSortInt = 2
                    self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                    self.checkedArray.sort {$0.checkedTime > $1.checkedTime}
                    self.table.reloadData()
                }),
                UIAction(title: "カスタム", image: UIImage(systemName: "hand.point.up"), handler: { _ in
                    self.checkedSortInt = 3
                    self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                    self.checkedArray.sort {$0.checkedCount < $1.checkedCount}
                    self.table.reloadData()
                })
            ]
            
            let Item3 = UIAction(title: "リストの編集", image: UIImage(systemName: "list.bullet"), handler: { _ in
                self.table.isEditing = true
                self.menu()
            })
            
            if checkedSwitch {
                title = "完了項目を表示"
                image = UIImage(systemName: "eye")
            } else {
                title = "完了項目を非表示"
                image = UIImage(systemName: "eye.slash")
            }
            
            let Item4 = UIAction(title: title, image: image, handler: { _ in
                if self.checkedSwitch {
                    self.checkedSwitch = false
                } else {
                    self.checkedSwitch = true
                }
                self.userDefaults.set(self.checkedSwitch, forKey: "checkedSwitch")
                self.menu()
                self.table.reloadData()
            })
            let sort1 = UIMenu(title: "未完了を並び替え", image: UIImage(systemName: "square"),  children: Item1)
            let sort2 = UIMenu(title: "完了を並び替え", image: UIImage(systemName: "checkmark.square"), children: Item2)
            
            let Items = UIMenu(title: "", options: .displayInline, children: [sort1, sort2, Item3, Item4])
            let clear = UIAction(title: "完了項目を削除", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { _ in self.clearChecked()})
            let menu = UIMenu(title: "", image: UIImage(systemName: "ellipsis.circle"), options: .displayInline, children: [Items, clear])
            menuBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
            menuBarButtonItem.tintColor = .black
        }
        self.navigationItem.rightBarButtonItem = menuBarButtonItem
    }
    
    @objc func menuBarButtonItem(_ sender: UIBarButtonItem) {
        table.isEditing = false
        menu()
    }
}

extension ViewController {
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if tableView.numberOfSections == 2 {
            if sourceIndexPath.section == 0 {
                let memo = memoArray[sourceIndexPath.row]
                memoArray.remove(at: sourceIndexPath.row)
                memoArray.insert(memo, at: destinationIndexPath.row)
            } else {
                let memo = checkedArray[sourceIndexPath.row]
                checkedArray.remove(at: sourceIndexPath.row)
                checkedArray.insert(memo, at: destinationIndexPath.row)
            }
        } else if tableView.numberOfSections == 1 {
            if checkedArray.isEmpty {
                let memo = memoArray[sourceIndexPath.row]
                memoArray.remove(at: sourceIndexPath.row)
                memoArray.insert(memo, at: destinationIndexPath.row)
            } else if memoArray.isEmpty {
                let memo = checkedArray[sourceIndexPath.row]
                checkedArray.remove(at: sourceIndexPath.row)
                checkedArray.insert(memo, at: destinationIndexPath.row)
            }
        }
        listSort(indexPath: sourceIndexPath)
    }
    
    func listSort(indexPath: IndexPath) {
        self.memoSortInt = 3
        userDefaults.set(memoSortInt, forKey: "memoSortInt")
        if table.numberOfSections == 2 {
            if indexPath.section == 0 {
                memoArraySort()
            } else {
                checkedArraySort()
            }
        } else if table.numberOfSections == 1 {
            if checkedArray.isEmpty {
                memoArraySort()
            } else if memoArray.isEmpty {
                checkedArraySort()
            }
        }
    }
    
    func memoArraySort() {
        if memoArray.count != 0 {
            for i in 0...memoArray.count - 1 {
                let memoId = memoArray[i].memoId
                var memoCount = memoArray[i].memoCount
                let checkedCount = memoArray[i].checkedCount
                let shoppingMemo = memoArray[i].shoppingMemo
                let isChecked = memoArray[i].isChecked
                let dateNow = memoArray[i].dateNow
                let checkedTime = memoArray[i].checkedTime
                let imageUrl = memoArray[i].imageUrl
                
                memoCount = i
                memoArray[i] = (memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, checkedTime: checkedTime, imageUrl: imageUrl)
                self.ref.child("users").child(userId).child(list).child(memo).child(memoId).updateChildValues(["memoCount": memoCount])
            }
        }
    }
    
    func checkedArraySort() {
        if checkedArray.count != 0 {
            for i in 0...checkedArray.count - 1 {
                let memoId = checkedArray[i].memoId
                let memoCount = checkedArray[i].memoCount
                var checkedCount = checkedArray[i].checkedCount
                let shoppingMemo = checkedArray[i].shoppingMemo
                let isChecked = checkedArray[i].isChecked
                let dateNow = checkedArray[i].dateNow
                let checkedTime = checkedArray[i].checkedTime
                let imageUrl = checkedArray[i].imageUrl
                
                checkedCount = i
                checkedArray[i] = (memoId: memoId, memoCount: memoCount, checkedCount: checkedCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, checkedTime: checkedTime, imageUrl: imageUrl)
                self.ref.child("users").child(userId).child(list).child(memo).child(memoId).updateChildValues(["checkedCount": checkedCount])
            }
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
        self.table.reloadData()
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
    
    func clearChecked() {
        if self.checkedArray.count != 0 {
            if self.connect {
                let alert: UIAlertController = UIAlertController(title: "本当に削除しますか？", message: "この操作は取り消すことができません。", preferredStyle: .alert)
                alert.addAction(
                    UIAlertAction(
                        title: "削除",
                        style: .destructive,
                        handler: { action in
                            self.removeSwitch = true
                            self.userDefaults.set(self.removeSwitch, forKey: "removeSwitch")
                            for i in 0...self.checkedArray.count - 1 {
                                let memoId = self.checkedArray[i].memoId
                                self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).removeValue()
                            }
                            self.checkedArray.removeAll()
                            self.table.reloadData()
                        }))
                alert.addAction(
                    UIAlertAction(
                        title: "キャンセル",
                        style: .cancel
                    ))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.alert()
            }
        } else {
            let alert: UIAlertController = UIAlertController(title: "削除できません", message: "削除できる完了項目がありません。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                    }))
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
            self.changedSwitch = true
            self.userDefaults.set(changedSwitch, forKey: "changedSwitch")
            if self.table.numberOfSections == 2 {
                if indexPath.section == 0 {
                    cell.checkMarkImageButton.setImage(nil, for: .normal)
                    let memoId = memoArray[indexPath.row].memoId
                    let isChecked = memoArray[indexPath.row].isChecked
                    let time = Date()
                    let cTime = dateFormatter.string(from: time)
                    self.memoSortInt = 3
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["isChecked": !isChecked, "checkedTime": cTime])
                    }
                } else if indexPath.section == 1 {
                    cell.checkMarkImageButton.setImage(nil, for: .normal)
                    let memoId = checkedArray[indexPath.row].memoId
                    let isChecked = checkedArray[indexPath.row].isChecked
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["isChecked": !isChecked])
                    }
                }
            } else if self.table.numberOfSections == 1 {
                if !self.memoArray.isEmpty {
                    let memoId = memoArray[indexPath.row].memoId
                    let isChecked = memoArray[indexPath.row].isChecked
                    let time = Date()
                    let cTime = dateFormatter.string(from: time)
                    self.memoSortInt = 3
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["isChecked": !isChecked, "checkedTime": cTime])
                    }
                } else if !self.checkedArray.isEmpty {
                    cell.checkMarkImageButton.setImage(nil, for: .normal)
                    let memoId = checkedArray[indexPath.row].memoId
                    let isChecked = checkedArray[indexPath.row].isChecked
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["isChecked": !isChecked])
                    }
                }
            }
        } else {
            alert()
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
            self.performSegue(withIdentifier: "toImageViewVC", sender: nil)
        } else {
            self.alert()
        }
    }
}


