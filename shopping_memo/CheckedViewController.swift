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
    var checkedSwitch = true
    
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    var checkSortCountInt: Int!
    let dateFormatter = DateFormatter()
    var arrayInt: Int!
    
    var name: String!
    
    let nonCheck = "未チェック"
    
    let checked = "チェック済み"
    
    var user: User!
    
    var delegate:CatchProtocol?
    
    @IBOutlet var checkedList: UILabel!
    
    @IBOutlet var table: UITableView!
    @IBOutlet var clearButton: UIButton!
    
    var userId: String!
    var list: String!
    
    var checkedSwitchCount: Int!
    
    var auth: Auth!
    
    var ref: DatabaseReference!
    
    
    var checkedArray = [(memoId: String, memoCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, imageUrl: String)]()
    
    var searchArray = [(memoId: String, memoCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, imageUrl: String)]()
    
    var nonCheckedArray = [(memoId: String, shoppingMemo: String, isChecked: Bool)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(systemName: "trash")
        clearButton.setImage(image, for: .normal)
        clearButton.tintColor = .red
        
        checkSortCountInt = userDefaults.integer(forKey: "checkSortCount")
        
        let image2 = UIImage(systemName: "ellipsis")
        menuButton.setImage(image2, for: .normal)
        menuButton.tintColor = .systemRed
        
        clearButton.layer.cornerRadius = 10.0
        clearButton.layer.borderWidth = 1.0
        clearButton.layer.borderColor = UIColor.systemRed.cgColor
        
        menuButton.layer.cornerRadius = 10.0
        menuButton.layer.borderWidth = 2.0
        menuButton.layer.borderColor = UIColor.label.cgColor
        menuButton.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        searchTextField.layer.cornerRadius = 6.0
        searchTextField.layer.borderWidth = 2.0
        searchButton.layer.borderColor = UIColor.label.cgColor
        searchButton.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 183/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        searchButton.layer.cornerRadius = 10.0
        searchButton.layer.borderWidth = 2.0
        searchButton.layer.borderColor = UIColor.black.cgColor
        
        let image3 = UIImage(systemName: "multiply.circle")
        deleteButton.setImage(image3, for: .normal)
        deleteButton.tintColor = .gray
        
        checkedList.adjustsFontSizeToFitWidth = true
        checkedList.text = name
        
        menu()
        
        arrayInt = 0
        
        userDefaults.set(checkedSwitch, forKey: "checkedSwitch")
        searchTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを検索",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        
        print("ぬuserDefauls:", userDefaults.bool(forKey: "checkedSwitch"))
        checkedSwitchCount = 1

        table.dataSource = self
        
        table.delegate = self
        
        //table.isEditing = true
        
        //table.allowsSelectionDuringEditing = true
        
        searchTextField.delegate = self
        
        table.register(UINib(nibName: "CheckedTableViewCell", bundle: .main), forCellReuseIdentifier: "CheckedTableViewCell")
        
        print("removedList1:", checkedArray)
        // Do any additional setup after loading the view.
        
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        
        //        ref.child("users").child(userId).child(list).child(checked).observe(.childChanged, with: { snapshot in
        //            print("changed: \(snapshot)")
        //            self.table.reloadData()
        //        })
        
        
        //checkedに追加されたとき
        ref.child("users").child(userId).child(list).child(checked).observe(.childAdded, with: { [self] snapshot in
            let memoId = snapshot.key // memo0とか
            guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
            guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
            guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }

            
            self.dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
            self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            self.dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let date = self.dateFormatter.date(from: dateNow)
            
            self.checkedArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, imageUrl: imageUrl))
            
            print("removedList2:", self.checkedArray)
            
            print("ソートやねん")

            if self.checkSortCountInt == 0 {
                self.checkedArray.sort {$0.shoppingMemo < $1.shoppingMemo}
            } else if self.checkSortCountInt == 1 {
                self.checkedArray.sort {$0.shoppingMemo > $1.shoppingMemo}
            } else {
                self.checkedArray.sort {$0.dateNow < $1.dateNow}
            }
            
            self.table.reloadData()
        })
        print("removedList3:", checkedArray)
        
        //checkedの中身が消えたとき
        ref.child("users").child(userId).child(list).child(checked).observe(.childRemoved, with: { [self] snapshot in
            
            checkedSwitch = userDefaults.bool(forKey: "checkedSwitch")
            
            if checkedSwitch == true {
                                
                print("removed: \(snapshot)")
                let index = self.checkedArray.firstIndex(where: {$0.memoId == snapshot.key})
                
    //            print("removeda: \(self.checkedArray[index!])")
                print("📱snapshot:\(snapshot.key)")
                self.checkedArray.remove(at: index!)
                
                
                guard let removedMemoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                guard let removedShoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
                guard var removedIsChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
                guard let romovedDateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                guard let removeImageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }

                
                removedIsChecked = !removedIsChecked
                
                print("removedIsChecked:", removedIsChecked)
                
                ref.child("users").child(self.userId).child(self.list).child(self.nonCheck).child(snapshot.key).updateChildValues(["memoCount": removedMemoCount, "shoppingMemo": removedShoppingMemo, "isChecked": removedIsChecked, "dateNow": romovedDateNow, "imageUrl": removeImageUrl])

                
                //               if self.checkedArray.isEmpty {
                //                   self.ref.child("users").child(self.userId).child(self.list).setValue("temporaly value")
                //               }
                self.table.reloadData()
                
            }

        })
        
        //nonCheckに追加されたとき
        //        ref.child("users").child(userId).child(list).child(nonCheck).observe(.childAdded, with: { snapshot in
        //            let memoId = snapshot.key // memo0とか
        //            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
        //            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
        //
        //            self.nonCheckedArray.append((memoId: memoId, shoppingMemo: shoppingMemo, isChecked: isChecked))
        //                        self.checkedArray.sort(by: {(A, B) -> Bool in
        //                            return A.isChecked != true && B.isChecked == true
        //                        })
        //            print("removedList4:", self.nonCheckedArray)
        //            self.table.reloadData()
        //        })
        //        print("removedList5:", nonCheckedArray)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cellCount = 0
        if arrayInt == 0 {
            cellCount = checkedArray.count
        } else if arrayInt == 1 {
            cellCount = searchArray.count
        }
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        print("✋", checkedArray)
        //IDツキノセルヲシュトクシテ、セルフゾクノTextLabelニ「テスト」トヒョウジサセテミル
        // セルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "CheckedTableViewCell") as! CheckedTableViewCell
        
        cell.checkedDalegate = self
        cell.indexPath = indexPath
        
        // セルの中にラベルに配列の要素の値を代入
        if arrayInt == 0 {
            cell.memoLabel?.text = checkedArray[indexPath.row].shoppingMemo
        } else if arrayInt == 1 {
            cell.memoLabel?.text = searchArray[indexPath.row].shoppingMemo
        }
        
        print(checkedArray[indexPath.row])
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
        let memo = checkedArray[index]
        let memoId = checkedArray[index].memoId
        let memoCount = checkedArray[index].memoCount
        var shoppingMemo = checkedArray[index].shoppingMemo
        let isChecked = checkedArray[index].isChecked
        let dateNow = checkedArray[index].dateNow
        
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
                            var shoppingMemo = self.checkedArray[index];shoppingMemo
                            let text = alertTextField.text!
                            self.checkedArray[index].shoppingMemo = text
                            print("checkedArray:", self.checkedArray[index])
                            self.ref.child("users").child(self.userId).child(self.list).child(self.checked).child(memoId).updateChildValues(["shoppingMemo": text])
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "toViewController" {
            // 2. 遷移先のViewControllerを取得
            let next = segue.destination as? ViewController
            // 3. １で用意した遷移先の変数に値を渡す
            //            next?.checkedArray = nonCheckedArray
            next?.list = list
            //            print("nextList:", next?.checkedArray)
            
            delegate?.catchData(count: nonCheckedArray)
            
            //元の画面に戻る処理
            dismiss(animated: true, completion: nil)
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
                let imageUrl = checkedArray[i].imageUrl

                print("shoppingMemoんぬ:", shoppingMemo)
                
                if shoppingMemo == text {
                    self.searchArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, imageUrl: imageUrl))
                    print("shoppingMemoんぬ:", shoppingMemo)
                }
                
            }
            
            arrayInt = 1
            
            userDefaults.set(arrayInt, forKey: "arrayInt")
            
            //            let num = checkedArray.count - searchArray.count
            
            //            for i in 0...num - 1 {
            //                self.searchArray.append((memoId: "", memoCount: 0, shoppingMemo: "", isChecked: false, dateNow: searchArray[0].dateNow))
            //            }
            
            //            tableView(table, cellForRowAt: IndexPath())
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
                self.arrayInt = 0
                
                self.userDefaults.set(self.arrayInt, forKey: "arrayInt")
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
                let imageUrl = checkedArray[i].imageUrl

                print("shoppingMemoんぬ:", shoppingMemo)
                
                if shoppingMemo == text {
                    self.searchArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, imageUrl: imageUrl))
                    print("shoppingMemoんぬ:", shoppingMemo)
                }
                
            }
            
            arrayInt = 1
            
            userDefaults.set(arrayInt, forKey: "arrayInt")
            
            //            let num = checkedArray.count - searchArray.count
            
            //            for i in 0...num - 1 {
            //                self.searchArray.append((memoId: "", memoCount: 0, shoppingMemo: "", isChecked: false, dateNow: searchArray[0].dateNow))
            //            }
            
            //            tableView(table, cellForRowAt: IndexPath())
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
                self.arrayInt = 0
                
                self.userDefaults.set(self.arrayInt, forKey: "arrayInt")
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
                print("ソートしました。")
            }),
            UIAction(title: "逆五十音順", image: UIImage(systemName: "z.circle"), handler: { _ in
                self.checkSortCountInt = 1
                self.userDefaults.set(self.checkSortCountInt, forKey: "checkSortCount")
                self.checkedArray.sort {$0.shoppingMemo > $1.shoppingMemo}
                self.table.reloadData()
                print("ソートしました。")
            }),
            UIAction(title: "追加した順", image: UIImage(systemName: "clock"), handler: { _ in
                self.checkSortCountInt = 2
                self.userDefaults.set(self.checkSortCountInt, forKey: "checkSortCount")
                self.checkedArray.sort {$0.dateNow < $1.dateNow}
                self.table.reloadData()
                print("ソートしました。")
            }),
        ]
        
        
        print("メニューです。")
        
        menuButton.menu = UIMenu(title: "並び替え", options: .displayInline, children: Items)
        
        menuButton.showsMenuAsPrimaryAction = true
        
    }
    
    @IBAction func textDelete() {
        self.searchTextField.text = ""
        self.searchArray = []
        self.arrayInt = 0
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
                        self.checkedSwitch = false
                        self.userDefaults.set(self.checkedSwitch, forKey: "checkedSwitch")
                        self.checkedSwitchCount = 2
                        self.checkedArray.removeAll()
                        
                        self.ref.child("users").child(self.userId).child(self.list).child(self.checked).removeValue()
                        
                        self.ref.child("users").child(self.userId).child(self.list).observe(.childAdded, with: { snapshot in
                            
                            let dataId = self.list!
                            
                            let checkName = [self.checked: dataId]
                            
                            self.ref.child("users").child(self.userId).child(self.list).updateChildValues(checkName)
                            
                        })
                        self.table.reloadData()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            
                            self.checkedSwitch = true
                            self.userDefaults.set(self.checkedSwitch, forKey: "checkedSwitch")
                            
                            self.dismiss(animated: true, completion: nil)
                        }
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
        print("🇯🇵IndexPath:", indexPath)
        var deleteAction: UIContextualAction
        let checkedMemo = checkedArray[indexPath.row].memoId
        // 削除処理
        deleteAction = UIContextualAction(style: .destructive, title: "削除") { (action, view, completionHandler) in
            //削除処理を記述
            self.checkedSwitch = false
            self.userDefaults.set(self.checkedSwitch, forKey: "checkedSwitch")
            print("Deleteがタップされた")
            
            self.checkedArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
            self.ref.child("users").child(self.userId).child(self.list).child(self.checked).child(checkedMemo).removeValue()
            print("Delete完了")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkedSwitch = true
                self.userDefaults.set(self.checkedSwitch, forKey: "checkedSwitch")
            }
            
            // 実行結果に関わらず記述
            completionHandler(true)
            
        }
        
        self.table.reloadData()
        
        // 定義したアクションをセット
        return UISwipeActionsConfiguration(actions: [deleteAction])
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
        self.ref.child("users").child(userId).child(list).child(checked).child(memoId).removeValue()
    }
}
