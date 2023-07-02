//
//  CheckedViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2021/04/17.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

protocol CatchProtocol {
    func catchData(count: Array<Any>)
}

class CheckedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    var checkSortCountInt: Int!
    let dateFormatter = DateFormatter()
    var arraySwitch = false
    
    var name: String!
    
    let nonCheck = "未チェック"
    let checked = "チェック済み"
    let memo = "memo"
    
    var user: User!
    
    var delegate:CatchProtocol?
    
    @IBOutlet var checkedList: UILabel!
    
    @IBOutlet var table: UITableView!
    @IBOutlet var clearButton: UIButton!
    
    var userId: String!
    var list: String!
    var shoppingMemoName: String!
    var memoIdString: String!
    var imageUrlString: String!
        
    var auth: Auth!
    
    var ref: DatabaseReference!
    
    
    var checkedArray = [(memoId: String, memoCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    var searchArray = [(memoId: String, memoCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    var nonCheckedArray = [(memoId: String, shoppingMemo: String, isChecked: Bool)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(systemName: "trash")
        clearButton.setImage(image, for: .normal)
        clearButton.tintColor = .red
        
        checkSortCountInt = 3
        
        let image2 = UIImage(systemName: "ellipsis")
        menuButton.setImage(image2, for: .normal)
        menuButton.tintColor = .black
        
        clearButton.layer.cornerRadius = 10.0
        clearButton.layer.borderWidth = 1.0
        clearButton.layer.borderColor = UIColor.systemRed.cgColor
        
        menuButton.layer.cornerRadius = 10.0
        menuButton.layer.borderWidth = 2.0
        menuButton.layer.borderColor = UIColor.label.cgColor
        menuButton.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        searchTextField.layer.cornerRadius = 6.0
        searchTextField.layer.borderColor = UIColor.label.cgColor
        searchTextField.layer.borderWidth = 2.0
        searchTextField.backgroundColor = UIColor.systemGray5

        searchButton.layer.cornerRadius = 10.0
        searchButton.layer.borderWidth = 2.0
        searchButton.layer.borderColor = UIColor.label.cgColor
        searchButton.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        let image3 = UIImage(systemName: "multiply.circle")
        deleteButton.setImage(image3, for: .normal)
        deleteButton.tintColor = .gray
        
        checkedList.adjustsFontSizeToFitWidth = true
        checkedList.text = name
        
        menu()
        
        arraySwitch = false
        
        searchTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを検索",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        
        table.dataSource = self
        table.delegate = self
        
        searchTextField.delegate = self
        
        table.register(UINib(nibName: "CheckedTableViewCell", bundle: .main), forCellReuseIdentifier: "CheckedTableViewCell")
                
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        //checkedに追加されたとき
        ref.child("users").child(userId).child(list).child(checked).observe(.childAdded, with: { [self] snapshot in
            let memoId = snapshot.key // memo0とか
            guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
            guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
            let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
            guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
            
            ref.child("users").child(userId).child(list).child(checked).child(memoId).removeValue()
            
            ref.child("users").child(userId).child(list).child(memo).child(memoId).updateChildValues(["memoCount": memoCount, "shoppingMemo": shoppingMemo, "isChecked": isChecked, "dateNow": dateNow, "checkedTime": checkedTime, "imageUrl": imageUrl])
            
            switch checkSortCountInt {
            case 0:
                checkedArray.sort {$0.shoppingMemo < $1.shoppingMemo}
            case 1:
                checkedArray.sort {$0.shoppingMemo > $1.shoppingMemo}
            case 2:
                checkedArray.sort {$0.dateNow < $1.dateNow}
            default:
                checkedArray.sort {$0.checkedTime > $1.checkedTime}
            }
            self.table.reloadData()
        })
        
        ref.child("users").child(userId).child(list).child(memo).observe(.childAdded, with: { [self] snapshot in
            let memoId = snapshot.key // memo0とか
            guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
            guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
            let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
            guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
            
            dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let date = dateFormatter.date(from: dateNow)
            let time = dateFormatter.date(from: checkedTime)
            
            if isChecked == true {
                self.checkedArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
            }
            
            switch checkSortCountInt {
            case 0:
                checkedArray.sort {$0.shoppingMemo < $1.shoppingMemo}
            case 1:
                checkedArray.sort {$0.shoppingMemo > $1.shoppingMemo}
            case 2:
                checkedArray.sort {$0.dateNow < $1.dateNow}
            default:
                checkedArray.sort {$0.checkedTime > $1.checkedTime}
            }
            self.table.reloadData()
        })
        
        ref.child("users").child(userId).child(list).child(memo).observe(.childChanged, with: { [self] snapshot in
            let memoId = snapshot.key // memo0とか
            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
            guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
            guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
            let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
            guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
            
            
            dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let date = dateFormatter.date(from: dateNow)
            let time = date
            
            let index = self.checkedArray.firstIndex(where: {$0.memoId == memoId})
            if index == nil {
                if isChecked == true {
                    checkedArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
                }
            }else if index != nil {
                if isChecked == true {
                    checkedArray[index!] = ((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
                } else if isChecked == false {
                    checkedArray.remove(at: index!)
                }
            }
                        
            switch checkSortCountInt {
            case 0:
                checkedArray.sort {$0.shoppingMemo < $1.shoppingMemo}
            case 1:
                checkedArray.sort {$0.shoppingMemo > $1.shoppingMemo}
            case 2:
                checkedArray.sort {$0.dateNow < $1.dateNow}
            default:
                checkedArray.sort {$0.checkedTime > $1.checkedTime}
            }
            self.table.reloadData()
        })
        
        ref.child("users").child(userId).observe(.childChanged, with: { [self] snapshot in
            guard let listName = snapshot.childSnapshot(forPath: "name").value as? String else { return }
            name = listName
            checkedList.text = name
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cellCount = 0
        if arraySwitch == false {
            cellCount = checkedArray.count
        } else if arraySwitch == true {
            cellCount = searchArray.count
        }
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //IDツキノセルヲシュトクシテ、セルフゾクノTextLabelニ「テスト」トヒョウジサセテミル
        // セルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "CheckedTableViewCell") as! CheckedTableViewCell
        
        cell.checkedDalegate = self
        cell.imageDelegate = self
        cell.indexPath = indexPath
        
        let time = checkedArray[indexPath.row].checkedTime
        
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let date = dateFormatter.string(from: Date())
        let dateNow = dateFormatter.date(from: date)
        let difference = dateNow!.timeIntervalSince(time)
        
        if difference <= 43200 {
            // セルの中にラベルに配列の要素の値を代入
            if arraySwitch == false {
                cell.memoLabel?.text = checkedArray[indexPath.row].shoppingMemo
                cell.memoLabel?.backgroundColor = UIColor.systemGray3
                cell.whiteView?.backgroundColor = UIColor.systemGray3
                cell.backgroundColor = UIColor.systemGray3
            } else if arraySwitch == true {
                cell.memoLabel?.text = searchArray[indexPath.row].shoppingMemo
                cell.memoLabel?.backgroundColor = UIColor.systemGray3
                cell.whiteView?.backgroundColor = UIColor.systemGray3
                cell.backgroundColor = UIColor.systemGray3
            }
            
            let imageUrl = checkedArray[indexPath.row].imageUrl
            if imageUrl == "" {
                let image = UIImage(systemName: "plus.viewfinder")
                cell.imageButton?.setImage(image, for: .normal)
                cell.imageButton?.tintColor = .label
            } else {
                let image2 = UIImage(systemName: "photo")
                cell.imageButton?.setImage(image2, for: .normal)
                cell.imageButton?.tintColor = .label
            }
        } else if difference > 60 * 60 * 6 {
            if arraySwitch == false {
                cell.memoLabel?.text = checkedArray[indexPath.row].shoppingMemo
                cell.memoLabel?.backgroundColor = UIColor.systemGray5
                cell.whiteView?.backgroundColor = UIColor.systemGray5
                cell.backgroundColor = UIColor.systemGray5
            } else if arraySwitch == true {
                cell.memoLabel?.text = searchArray[indexPath.row].shoppingMemo
                cell.memoLabel?.backgroundColor = UIColor.systemGray5
                cell.whiteView?.backgroundColor = UIColor.systemGray5
                cell.backgroundColor = UIColor.systemGray5
            }
            
            let imageUrl = checkedArray[indexPath.row].imageUrl
            if imageUrl == "" {
                let image = UIImage(systemName: "plus.viewfinder")
                cell.imageButton?.setImage(image, for: .normal)
                cell.imageButton?.tintColor = .label
            } else {
                let image2 = UIImage(systemName: "photo")
                cell.imageButton?.setImage(image2, for: .normal)
                cell.imageButton?.tintColor = .label
            }
        }
        
        if checkedArray[indexPath.row].isChecked {
            //cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
            cell.textLabel?.textColor = UIColor.black
        }
        // 最後に設定したセルを表示
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var alertTextField: UITextField!
        let index = indexPath.row
        let memoId = checkedArray[index].memoId
        let isChecked = checkedArray[index].isChecked
        
        let alert: UIAlertController = UIAlertController(title: "メモの変更", message: "変更後のメモを記入してください。", preferredStyle: .alert)
        alert.addTextField { textField in
            alertTextField = textField
            alertTextField.returnKeyType = .done
            alertTextField.text = self.checkedArray[index].shoppingMemo
            
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        if alertTextField.text != "" {
                            let shoppingMemo = self.checkedArray[index].shoppingMemo
                            let text = alertTextField.text!
                            self.checkedArray[index].shoppingMemo = text
                            self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["shoppingMemo": text])
                            self.table.reloadData()
                        }
                    })
                )
            alert.addAction(
                UIAlertAction(
                    title: "キャンセル",
                    style: .cancel
                )
            )
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if searchTextField.text == "" {
            let alert: UIAlertController = UIAlertController(title: "検索できません。", message: "記入欄が空白です。", preferredStyle: .alert)
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
            searchArray = []
            for i in 0...checkedArray.count - 1 {
                let text = searchTextField.text
                
                let memoId = checkedArray[i].memoId
                let memoCount = checkedArray[i].memoCount
                let shoppingMemo = checkedArray[i].shoppingMemo
                let isChecked = checkedArray[i].isChecked
                let dateNow = checkedArray[i].dateNow
                let checkedTime = checkedArray[i].checkedTime
                let imageUrl = checkedArray[i].imageUrl
                
                if shoppingMemo == text {
                    self.searchArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, checkedTime: checkedTime, imageUrl: imageUrl))
                }
            }
            
            arraySwitch = true
            userDefaults.set(arraySwitch, forKey: "arraySwitch")
            
            self.table.reloadData()
            
            if searchArray.count == 0 {
                let alert: UIAlertController = UIAlertController(title: "該当項目なし。", message: "該当する項目がありません。", preferredStyle: .alert)
                alert.addAction(
                    UIAlertAction(
                        title: "OK",
                        style: .default
                    )
                )
                self.present(alert, animated: true, completion: nil)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.arraySwitch = false
                self.userDefaults.set(self.arraySwitch, forKey: "arraySwitch")
            }
        }
        return true
    }
    
    
    @IBAction func searchMemo() {
        searchTextField.resignFirstResponder()
        if searchTextField.text == "" {
            let alert: UIAlertController = UIAlertController(title: "検索できません。", message: "記入欄が空白です。", preferredStyle: .alert)
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
            searchArray = []
            for i in 0...checkedArray.count - 1 {
                
                let text = searchTextField.text
                
                let memoId = checkedArray[i].memoId
                let memoCount = checkedArray[i].memoCount
                let shoppingMemo = checkedArray[i].shoppingMemo
                let isChecked = checkedArray[i].isChecked
                let dateNow = checkedArray[i].dateNow
                let checkedTime = checkedArray[i].checkedTime
                let imageUrl = checkedArray[i].imageUrl
                
                if shoppingMemo == text {
                    self.searchArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, checkedTime: checkedTime, imageUrl: imageUrl))
                }
            }
            
            arraySwitch = true
            userDefaults.set(arraySwitch, forKey: "arraySwitch")
            
            self.table.reloadData()
            
            if searchArray.count == 0 {
                let alert: UIAlertController = UIAlertController(title: "該当項目なし。", message: "該当する項目がありません。", preferredStyle: .alert)
                alert.addAction(
                    UIAlertAction(
                        title: "OK",
                        style: .default
                    )
                )
                self.present(alert, animated: true, completion: nil)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.arraySwitch = false
                self.userDefaults.set(self.arraySwitch, forKey: "arraySwitch")
            }
        }
    }
    
    func menu() {
        
        print("メニューが呼ばれた。")
        
        
        let Items = [
            UIAction(title: "五十音順", image: UIImage(systemName: "a.circle"), handler: { _ in
                self.checkSortCountInt = 0
                self.userDefaults.set(self.checkSortCountInt, forKey: "checkSortCount")
                self.checkedArray.sort {$0.shoppingMemo < $1.shoppingMemo}
                self.table.reloadData()
            }),
            UIAction(title: "逆五十音順", image: UIImage(systemName: "z.circle"), handler: { _ in
                self.checkSortCountInt = 1
                self.userDefaults.set(self.checkSortCountInt, forKey: "checkSortCount")
                self.checkedArray.sort {$0.shoppingMemo > $1.shoppingMemo}
                self.table.reloadData()
            }),
            UIAction(title: "追加した順", image: UIImage(systemName: "clock"), handler: { _ in
                self.checkSortCountInt = 2
                self.userDefaults.set(self.checkSortCountInt, forKey: "checkSortCount")
                self.checkedArray.sort {$0.dateNow < $1.dateNow}
                self.table.reloadData()
            }),
            UIAction(title: "チェックつけた順", image: UIImage(systemName: "clock.arrow.circlepath"), handler: { _ in
                self.checkSortCountInt = 3
                self.userDefaults.set(self.checkSortCountInt, forKey: "checkedSortCount")
                self.checkedArray.sort {$0.checkedTime > $1.checkedTime}
                self.table.reloadData()
            })
        ]
        menuButton.menu = UIMenu(title: "並び替え", options: .displayInline, children: Items)
        menuButton.showsMenuAsPrimaryAction = true
    }
    
    @IBAction func textDelete() {
        self.searchTextField.text = ""
        self.searchArray = []
        self.arraySwitch = false
        self.table.reloadData()
    }
    
    @IBAction func clear(_ sender: Any) {
        if checkedArray.count > 0 {
            let alert: UIAlertController = UIAlertController(title: "削除してもよろしいですか？", message: "この操作は取り消すことができません。", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        for i in 0...self.checkedArray.count - 1 {
                            let memoId = self.checkedArray[i].memoId
                            self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).removeValue()
                        }
                        self.checkedArray.removeAll()
                        self.table.reloadData()
                        self.dismiss(animated: true, completion: nil)
                    }
                )
            )
            alert.addAction(
                UIAlertAction(
                    title: "キャンセル",
                    style: .cancel
                )
            )
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert: UIAlertController = UIAlertController(title: "削除できません。", message: "削除できる項目がありません.", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default
                )
            )
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)

    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var deleteAction: UIContextualAction
        let deleteMemo = checkedArray[indexPath.row].memoId
        // 削除処理
        deleteAction = UIContextualAction(style: .destructive, title: "削除") { (action, view, completionHandler) in
            //削除処理を記述
            tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
            self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(deleteMemo).removeValue()
            self.checkedArray.remove(at: indexPath.row)
            // 実行結果に関わらず記述
            completionHandler(true)
        }
        self.table.reloadData()
        
        // 定義したアクションをセット
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCheckedImageVC" {
            let next = segue.destination as? CheckedImageViewController
            next?.shoppingMemoName = shoppingMemoName
            next?.memoIdString = memoIdString
            next?.list = list
            next?.imageUrlString = imageUrlString
        }
    }
}

extension CheckedViewController {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension CheckedViewController: checkedMarkDelegete {
    func buttonPressed(indexPath: IndexPath) {
        print("⤴️buttonPressed成功!")
        let memoId = checkedArray[indexPath.row].memoId
        self.memoIdString = memoId
        self.shoppingMemoName = checkedArray[indexPath.row].shoppingMemo
        self.ref.child("users").child(userId).child(list).child(memo).child(memoId).updateChildValues(["isChecked": false])
    }
}

extension CheckedViewController: checkedImageButtonDelegate {
    func buttonTapped(indexPath: IndexPath) {
        print("⤴️buttonPressed成功!")
        self.memoIdString = checkedArray[indexPath.row].memoId
        self.shoppingMemoName = checkedArray[indexPath.row].shoppingMemo
        self.imageUrlString = checkedArray[indexPath.row].imageUrl
        self.performSegue(withIdentifier: "toCheckedImageVC", sender: nil)
    }
}
