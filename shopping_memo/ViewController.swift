//
//  ViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/11/15.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth



class ViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate, UITableViewDelegate, CatchProtocol {
    
    @IBOutlet weak var checkedListButton: UIButton!
    
    let userDefaults: UserDefaults = UserDefaults.standard
    let dateFormatter = DateFormatter()
    var countInt = 0
    var defaultMemoCount: Int!
    var nonCheckSwitch = true
    var changeSwitch = false
    var sortCountInt = 0
    var searchInt = 0
    var arrayInt = 0
    var name: String!
    
    //Table Viewヲセンゲン→関連付け
    @IBOutlet var table: UITableView!
    @IBOutlet var titleTextField: UITextField!
    var auth: Auth!
    var userId: String!
    var list: String!
    var checkedList: String!
    var shoppingMemo: String!
    
    @IBOutlet var checkedImageButton: UIButton!
    
    @IBOutlet var menuButton: UIButton!
    
    @IBOutlet var searchImageButton: UIButton!
    
    @IBOutlet var addMemoButton: UIButton!
    
    @IBOutlet var deleteButton: UIButton!
    
    let checked = "チェック済み"
    let nonCheck = "未チェック"
    
    var ref: DatabaseReference!
    
    var checkMarks = [false, false, false, false]
    
    // String型の配列
    var memoArray = [(memoId: String, memoCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, imageUrl: String)]()
    
    var searchArray = [(memoId: String, memoCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, imageUrl: String)]()
    
    var checkedMemoArray = [(memoId: String, shoppingMemo: String, isChecked: Bool)]()
    
    @IBOutlet var listNameLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        listNameLabel.text = name
        
        countInt = userDefaults.integer(forKey: "count")
        print("🌀nonCheckSwitch:", nonCheckSwitch)
        userDefaults.set(nonCheckSwitch, forKey: "nonCheckSwitch")
        print("🌀nonCheckSwitch:", nonCheckSwitch)
        sortCountInt = userDefaults.integer(forKey: "sortCount")
        print("sortCountInt:", sortCountInt)
        print("sortCountInt:", userDefaults.integer(forKey: "sortCount"))
        searchInt = 0
        
        print("userDefaults:", userDefaults.integer(forKey: "count"))
        
        defaultMemoCount = -1
        
        if searchInt == 0 {
            self.addMemoButton.setTitle("追加", for: .normal)
            self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを追加",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        } else if searchInt == 1 {
            self.addMemoButton.setTitle("検索", for: .normal)
            self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを検索",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        }
        
        let image = UIImage(systemName: "checkmark.square")
        checkedImageButton.setImage(image, for: .normal)
        checkedImageButton.tintColor = .black
        
        checkedImageButton.imageView?.contentMode = .scaleAspectFit
        checkedImageButton.contentHorizontalAlignment = .fill
        checkedImageButton.contentVerticalAlignment = .fill
        
        addMemoButton.layer.cornerRadius = 10.0
        addMemoButton.layer.borderColor = UIColor.black.cgColor
        addMemoButton.layer.borderWidth = 2.0
        
        titleTextField.layer.cornerRadius = 6.0
        titleTextField.layer.borderColor = UIColor.black.cgColor
        titleTextField.layer.borderWidth = 2.0
        
        menu()
        
        let image3 = UIImage(systemName: "ellipsis")
        menuButton.setImage(image3, for: .normal)
        menuButton.tintColor = .black
        
        let image4 = UIImage(systemName: "multiply.circle")
        deleteButton.setImage(image4, for: .normal)
        deleteButton.tintColor = .gray
        
        
        menuButton.layer.cornerRadius = 10.0
        menuButton.layer.borderColor = UIColor.black.cgColor
        menuButton.layer.borderWidth = 2.0
        
        ref = Database.database().reference()
        
        userId = Auth.auth().currentUser?.uid
        // tableViewっていう関数を使えるようにするための宣言
        table.dataSource = self
        
        table.delegate = self
        
        table.isEditing = true
        
        table.allowsSelectionDuringEditing = true
        
        table.register(UINib(nibName: "CustomTableViewCell", bundle: .main), forCellReuseIdentifier: "CustomTableViewCell")
        
        
        titleTextField.delegate = self
        
        print("didLoad") // → didLoad
        print(memoArray) // → ["大根", "人参", "キャベツ"]
        
        memoArray = []
        
        
        // nonCheckに追加されたとき、firebaseのデータを引っ張ってくる
        ref.child("users").child(userId).child(list).child(nonCheck).observe(.childAdded, with: { [self] snapshot in
            if nonCheckSwitch == true {
                let memoId = snapshot.key // memo0とか
                guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
                guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
                guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
                
                dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(identifier: "UTC")
                let date = dateFormatter.date(from: dateNow)
                                
                self.memoArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, imageUrl: imageUrl))
                
                if sortCountInt == 0 {
                    memoArray.sort {$0.shoppingMemo < $1.shoppingMemo}
                } else if sortCountInt == 1 {
                    memoArray.sort {$0.shoppingMemo > $1.shoppingMemo}
                } else if sortCountInt == 2 {
                    memoArray.sort {$0.dateNow < $1.dateNow}
                } else {
                    memoArray.sort {$0.memoCount < $1.memoCount}
                }
                
                self.table.reloadData()
                
                listSort()
            }
        })
        
        // nonCheckに変化があったとき
        ref.child("users").child(userId).child(list).child(nonCheck).observe(.childChanged, with: { snapshot in
            self.changeSwitch = self.userDefaults.bool(forKey: "changeSwitch")
            if self.changeSwitch == true {
                self.memoArray = []
                
                let memoId = snapshot.key // memo0とか
                guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
                guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
                guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }

                
                self.dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                self.dateFormatter.timeZone = TimeZone(identifier: "UTC")
                let date = self.dateFormatter.date(from: dateNow)
                
                self.memoArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, imageUrl: imageUrl))
                
                if self.sortCountInt == 0 {
                    self.memoArray.sort {$0.shoppingMemo < $1.shoppingMemo}
                } else if self.sortCountInt == 1 {
                    self.memoArray.sort {$0.shoppingMemo > $1.shoppingMemo}
                } else if self.sortCountInt == 2 {
                    self.memoArray.sort {$0.dateNow < $1.dateNow}
                } else {
                    self.memoArray.sort {$0.memoCount < $1.memoCount}
                }
                
                self.changeSwitch = false
                self.userDefaults.set(self.changeSwitch, forKey: "changeSwitch")
                
                self.table.reloadData()
            }
        })
        
        // nonCheckの中身が消えたとき
        ref.child("users").child(userId).child(list).child(nonCheck).observe(.childRemoved, with: { [self] snapshot in
            nonCheckSwitch = userDefaults.bool(forKey: "nonCheckSwitch")
            if nonCheckSwitch == true {
                let index = self.memoArray.firstIndex(where: {$0.memoId == snapshot.key})
                self.memoArray.remove(at: index!)
                
                guard let removedMemoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
                guard let removedShoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
                guard var removedIsChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
                guard let removeDateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
                
                removedIsChecked = !removedIsChecked
                                
                ref.child("users").child(userId).child(list).child(checked).child(snapshot.key).updateChildValues(["memoCount": removedMemoCount, "shoppingMemo": removedShoppingMemo, "isChecked": removedIsChecked, "dateNow": removeDateNow])
                
                //            if self.memoArray.isEmpty {
                //                self.ref.child("users").child(self.userId).child(self.list).setValue("temporaly value")
                //            }
                self.table.reloadData()
            }
        })
        
        
        //        ref.child("users").child(userId).child(list).child(checked).observe(.childChanged, with: { snapshot in
        //            print("changed: \(snapshot)")
        //            self.table.reloadData()
        //        })
        
        
        // checkedに追加されたとき
        //        ref.child("users").child(userId).child(list).child(checked).observe(.childAdded, with: { snapshot in
        //            let memoId = snapshot.key // memo0とか
        //            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
        //            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
        //
        //
        //            self.checkedMemoArray.append((memoId: memoId, shoppingMemo: shoppingMemo, isChecked: isChecked))
        //            self.memoArray.sort(by: {(A, B) -> Bool in
        //            return A.isChecked != true && B.isChecked == true
        //                        })
        //            self.table.reloadData()
        //        })
        
        
        
        table.allowsMultipleSelection = true
        
        if Auth.auth().currentUser != nil {
            // User is signed in.
            // ...
            print("user: \(Auth.auth().currentUser)")
        } else {
            // No user is signed in.
            // ...
            print(Auth.auth().currentUser)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cellCount = 0
        
        if searchInt == 0 {
            cellCount = memoArray.count
        } else if searchInt == 1 {
            cellCount = searchArray.count
        }
        //セルの数を数える→セルの数を決める
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        print("indexPath:", indexPath)
        
        var checkImage: UIImage!
        
        
        //IDツキノセルヲシュトクシテ、セルフゾクノTextLabelニ「テスト」トヒョウジサセテミル
        // セルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell") as! CustomTableViewCell
        cell.checkDalegate = self
        cell.imageDelegate = self
        cell.indexPath = indexPath
        
        print("🌙memoArray:", memoArray)
        
        
        //        cell.memoLabel.text = memoArray[indexPath.row].shoppingMemo
        print(indexPath.row)
        print(memoArray.count)
        print("ここでエラーが出てる")
        print(memoArray[indexPath.row])
        print(memoArray[indexPath.row].shoppingMemo)
        
        arrayInt = userDefaults.integer(forKey: "arrayInt")
        
        print("arrayInt:", arrayInt)
        
        if arrayInt == 0 {
            // セルの中にラベルに配列の要素の値を代入
            cell.memoLabel.text = memoArray[indexPath.row].shoppingMemo
        } else if arrayInt == 1 {
            cell.memoLabel.text = searchArray[indexPath.row].shoppingMemo
        }
        
        let imageUrl = memoArray[indexPath.row].imageUrl
        if imageUrl == "" {
            let image = UIImage(systemName: "photo")
            cell.imageButton.setImage(image, for: .normal)
            cell.imageButton.tintColor = .black
        } else {
            
        }
        
        
        
        
        //        self.ref.child("users").child(userId).child(list).child(nonCheck).child(["\(memoArray[indexPath.row].memoId)"]).updateChildValues(<#[AnyHashable : Any]#>)
        
        print(memoArray[indexPath.row])
        if memoArray[indexPath.row].isChecked {
            //            cell.accessoryType = .checkmark
            //                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            //                cell.textLabel?.textColor = UIColor.blue
            
            //                checkMarks = checkMarks.enumerated().flatMap { (elem: (Int, Bool)) -> Bool in
            //                    if indexPath.row != elem.0 {
            //                        let otherCellIndexPath = NSIndexPath(row: elem.0, section: 0)
            //                        if let otherCell = tableView.cellForRow(at: otherCellIndexPath as IndexPath) {
            //                            otherCell.accessoryType = .none
            //                            otherCell.textLabel?.font = UIFont.systemFont(ofSize: 17)
            //                            otherCell.textLabel?.textColor = UIColor.black
            //                        }
            //                    }
            //                    return indexPath.row == elem.0
            //                }
        } else {
            //            cell.accessoryType = .checkmark
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
            cell.textLabel?.textColor = UIColor.black
        }
        
        
        //        memoArray.sort {$0.memoCount < $1.memoCount}
        
        // 最後に設定したセルを表示
        return cell
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAtが呼ばれました！")
        
        var alertTextField: UITextField!
        let index = indexPath.row
        let memo = memoArray[index]
        let memoId = memoArray[index].memoId
        let memoCount = memoArray[index].memoCount
        var shoppingMemo = memoArray[index].shoppingMemo
        let isChecked = memoArray[index].isChecked
        let dateNow = memoArray[index].dateNow
        
        let alert: UIAlertController = UIAlertController(title: "メモの変更", message: "変更後のメモを記入してください。", preferredStyle: .alert)
        alert.addTextField { textField in
            alertTextField = textField
            alertTextField.returnKeyType = .done
            alertTextField.text = self.memoArray[index].shoppingMemo
            
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        if alertTextField.text != "" {
                            var shoppingMemo = self.memoArray[index];shoppingMemo
                            let text = alertTextField.text!
                            self.memoArray[index].shoppingMemo = text
                            print("memoArray:", self.memoArray[index])
                            self.ref.child("users").child(self.userId).child(self.list).child(self.nonCheck).child(memoId).updateChildValues(["shoppingMemo": text])
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
        if searchInt == 0 {
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
                self.ref.child("users").child(userId).child(list).child(nonCheck).child("memo\(time)").updateChildValues(["memoCount": defaultMemoCount!, "shoppingMemo": titleTextField.text!, "isChecked": false, "dateNow": time, "imageUrl": ""])
                                
                countInt += 1
                userDefaults.set(countInt, forKey: "count")
                //            listSort()
                //            self.table.reloadData()
                titleTextField.text = ""
            }
            
        } else if searchInt == 1 {
            if titleTextField.text == "" {
                let alert: UIAlertController = UIAlertController(title: "検索できません。", message: "検索キーワードがありません。", preferredStyle: .alert)
                alert.addAction(
                    UIAlertAction(
                        title: "OK",
                        style: .default
                    )
                )
                self.present(alert, animated: true, completion: nil)
            } else {
                searchArray = []
                for i in 0...memoArray.count - 1 {
                    
                    let text = titleTextField.text
                    
                    let memoId = memoArray[i].memoId
                    let memoCount = memoArray[i].memoCount
                    let shoppingMemo = memoArray[i].shoppingMemo
                    let isChecked = memoArray[i].isChecked
                    let dateNow = memoArray[i].dateNow
                    let imageUrl = memoArray[i].imageUrl
                    
                    print("shoppingMemoんぬ:", shoppingMemo)
                    
                    if shoppingMemo == text {
                        self.searchArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, imageUrl: imageUrl))
                        print("shoppingMemoんぬ:", shoppingMemo)
                    }
                    
                }
                
                arrayInt = 1
                
                userDefaults.set(arrayInt, forKey: "arrayInt")
                
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
        //終わりの文
        return true
    }
    
    @IBAction func addMemo(_ sender: Any) {
        titleTextField.resignFirstResponder()
        searchInt = userDefaults.integer(forKey: "searchInt")
        print("serachInt", searchInt)
        if searchInt == 0 {
            print("searchInt:", searchInt)
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
                self.ref.child("users").child(userId).child(list).child(nonCheck).child("memo\(time)").updateChildValues(["memoCount": defaultMemoCount!, "shoppingMemo": titleTextField.text!, "isChecked": false, "dateNow": time, "imageUrl": ""])
                
                countInt += 1
                userDefaults.set(countInt, forKey: "count")
                titleTextField.text = ""
            }
        } else if searchInt == 1{
            if titleTextField.text == "" {
                let alert: UIAlertController = UIAlertController(title: "検索できません。", message: "検索キーワードがありません。", preferredStyle: .alert)
                alert.addAction(
                    UIAlertAction(
                        title: "OK",
                        style: .default
                    )
                )
                self.present(alert, animated: true, completion: nil)
            } else {
                print("searchInt:", searchInt)
                searchArray = []
                for i in 0...memoArray.count - 1 {
                    
                    let text = titleTextField.text
                    
                    let memoId = memoArray[i].memoId
                    let memoCount = memoArray[i].memoCount
                    let shoppingMemo = memoArray[i].shoppingMemo
                    let isChecked = memoArray[i].isChecked
                    let dateNow = memoArray[i].dateNow
                    let imageUrl = memoArray[i].imageUrl
                    
                    print("shoppingMemoんぬ:", shoppingMemo)
                    
                    if shoppingMemo == text {
                        self.searchArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, imageUrl: imageUrl))
                        print("shoppingMemoんぬ:", shoppingMemo)
                    }
                    
                }
                print("searchArray:", searchArray)
                
                arrayInt = 1
                
                userDefaults.set(arrayInt, forKey: "arrayInt")
                
                print("arrayInt:", arrayInt)
                
                //            let num = memoArray.count - searchArray.count
                
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
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "toCheckedViewController" {
            // 2. 遷移先のViewControllerを取得
            let next = segue.destination as? CheckedViewController
            
            //            print("😄checkedMemoArray:",checkedMemoArray)
            // 3. １で用意した遷移先の変数に値を渡す
            //            next?.checkedArray = checkedMemoArray
            next?.list = list
            next?.name = name
            //            print("nextList:", next?.checkedArray)
        } else if segue.identifier == "toImageViewVC" {
            let next = segue.destination as? ImageViewViewController
            next?.shoppingMemo = shoppingMemo
        }
        
    }
    
    func catchData(count: Array<Any>) {
        memoArray + count
        
    }
    
    func menu() {
        
        print("メニューが呼ばれた。")
        
        let Items = [
            UIAction(title: "追加", image: UIImage(systemName: "plus"), handler: { _ in
                if self.searchInt == 1 {
                    self.addMemoButton.setTitle("追加", for: .normal)
                    self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを追加",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
                    self.searchInt = 0
                    self.userDefaults.set(self.searchInt, forKey: "searchInt")
                    self.titleTextField.text = ""
                    self.table.reloadData()
                    print("追加モード")
                }
            }),
            UIAction(title:"検索", image: UIImage(systemName: "magnifyingglass"), handler: { _ in
                if self.searchInt == 0 {
                    self.addMemoButton.setTitle("検索", for: .normal)
                    self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを検索",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
                    self.searchInt = 1
                    self.userDefaults.set(self.searchInt, forKey: "searchInt")
                    self.table.reloadData()
                    print("検索モード")
                }
            })
        ]
        
        let Items2 = [
            UIAction(title: "五十音順", image: UIImage(systemName: "a.circle"), handler: { _ in
                self.sortCountInt = 0
                self.userDefaults.set(self.sortCountInt, forKey: "sortCount")
                self.memoArray.sort {$0.shoppingMemo < $1.shoppingMemo}
                self.table.reloadData()
                print("ソートしました。")
            }),
            UIAction(title: "逆五十音順", image: UIImage(systemName: "z.circle"), handler: { _ in
                self.sortCountInt = 1
                self.userDefaults.set(self.sortCountInt, forKey: "sortCount")
                self.memoArray.sort {$0.shoppingMemo > $1.shoppingMemo}
                self.table.reloadData()
                print("ソートしました。")
            }),
            UIAction(title: "追加した順", image: UIImage(systemName: "clock"), handler: { _ in
                self.sortCountInt = 2
                self.userDefaults.set(self.sortCountInt, forKey: "sortCount")
                self.memoArray.sort {$0.dateNow < $1.dateNow}
                self.table.reloadData()
                print("ソートしました。")
            }),
            UIAction(title: "カスタム", image: UIImage(systemName: "hand.point.up"), handler: { _ in
                self.sortCountInt = 3
                self.userDefaults.set(self.sortCountInt, forKey: "sortCount")
                self.memoArray.sort {$0.memoCount < $1.memoCount}
                self.table.reloadData()
                print("ソートしました。")
            })
        ]
        
        let sort = UIMenu(title: "モード", children: Items)
        let sort2 = UIMenu(title: "並び替え", children: Items2)
        
        print("メニューです。")
        
        menuButton.menu = UIMenu(title: "", options: .displayInline, children: [sort, sort2])
        
        menuButton.showsMenuAsPrimaryAction = true
        
    }
    
    
    @IBAction func textDelete() {
        self.titleTextField.text = ""
        self.searchArray = []
        self.table.reloadData()
    }
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func checkedListButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "toCheckedViewController", sender: nil)
    }
    
    @IBAction func toCheckedList2(_ sender: Any) {
        self.performSegue(withIdentifier: "toCheckedViewController", sender: nil)
    }
    //     スワイプした時に表示するアクションの定義
    //    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    //
    //
    //        // 編集処理
    //        let editAction = UIContextualAction(style: .normal, title: "編集") { (action, view, completionHandler) in
    //            // 編集処理を記述
    //            print("編集がタップされた")
    //
    //            // 実行結果に関わらず記述
    //            completionHandler(true)
    //
    //        }
    //
    //            editAction.backgroundColor = UIColor.systemBlue
    //
    //
    //        // 定義したアクションをセット
    //        return UISwipeActionsConfiguration(actions: [editAction])
    //
    //    }
}

extension ViewController {
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
//        nonCheckSwitch = false
//        userDefaults.set(nonCheckSwitch, forKey: "nonCheckSwitch")
                
        // TODO: 入れ替え時の処理を実装する（データ制御など）
        let memo = memoArray[sourceIndexPath.row]
        memoArray.remove(at: sourceIndexPath.row)
        memoArray.insert(memo, at: destinationIndexPath.row)
        
        
//        self.ref.child("users").child(userId).child(list).child(nonCheck).removeValue()
        
        
        listSort()
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//
//            self.nonCheckSwitch = true
//            self.userDefaults.set(self.nonCheckSwitch, forKey: "nonCheckSwitch")
//            print("nonCheckSwitch!?:", self.nonCheckSwitch)
//
//        }
    }
    
    func listSort() {
        if memoArray.count != 0 {
            for i in 0...memoArray.count - 1 {
                print("i:", i)
                
                let memoId = memoArray[i].memoId
                var memoCount = memoArray[0].memoCount
                let indexPath = IndexPath(row: i, section: 0)
                let shoppingMemo = memoArray[i].shoppingMemo
                let isChecked = memoArray[0].isChecked
                let dateNow = memoArray[i].dateNow
                let imageUrl = memoArray[i].imageUrl

                print("for:", type(of: dateNow))

                dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(identifier: "UTC")
                let time = dateFormatter.string(from: dateNow)
                
                memoCount = i
                print("indexPath2:", indexPath.row)
                print("memoId:", memoId)
                memoArray[i] = (memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, imageUrl: imageUrl)

                print(memoArray[i])
                
                if i == self.memoArray.count {
                    changeSwitch = true
                    userDefaults.set(changeSwitch, forKey: "changeSwitch")
                } else {
                    changeSwitch = false
                    userDefaults.set(changeSwitch, forKey: "changeSwitch")
                }

                self.ref.child("users").child(userId).child(list).child(nonCheck).child(memoId).updateChildValues(["memoCount": memoCount])
                
                
                
                //            print("i:", i)
                
                //            self.table.reloadData()
                
                //            self.table.reloadRows(at: [indexPath], with: .fade)
                //            let row = NSIndexPath(row: i, section: 0)
                //            self.table.reloadRowsAtIndexPaths([row], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            self.sortCountInt = 3
            userDefaults.set(sortCountInt, forKey: "sortCountInt")
        }
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
        
        let memoId = memoArray[indexPath.row].memoId
        
        self.ref.child("users").child(userId).child(list).child(nonCheck).child(memoId).removeValue()
    }
}

extension ViewController: imageButtonDelegate {
    func buttonTapped(indexPath: IndexPath) {
        print("⤴️buttonTapped成功!")
        self.shoppingMemo = memoArray[indexPath.row].shoppingMemo
        self.performSegue(withIdentifier: "toImageViewVC", sender: nil)
    }
}


