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
    var defaultMemoCount: Int!
    var sortCountInt = 3
    var searchSwitch = false
    var arraySwitch = false
    var name: String!
    var memoIdString: String!
    var imageUrlString: String!
    
    //Table Viewヲセンゲン→関連付け
    @IBOutlet var table: UITableView!
    @IBOutlet var titleTextField: UITextField!
    var auth: Auth!
    var userId: String!
    var list: String!
    var checkedList: String!
    var shoppingMemoName: String!
    
    @IBOutlet var checkedImageButton: UIButton!
    
    @IBOutlet var menuButton: UIButton!
    
    @IBOutlet var searchImageButton: UIButton!
    
    @IBOutlet var addMemoButton: UIButton!
    
    @IBOutlet var deleteButton: UIButton!
    
    let checked = "チェック済み"
    let nonCheck = "未チェック"
    let memo = "memo"
    
    var ref: DatabaseReference!
    
    var checkMarks = [false, false, false, false]
    
    // String型の配列
    var memoArray = [(memoId: String, memoCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    var searchArray = [(memoId: String, memoCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    var checkedMemoArray = [(memoId: String, shoppingMemo: String, isChecked: Bool)]()
    
    @IBOutlet var listNameLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        listNameLabel.text = name
        
        sortCountInt = userDefaults.integer(forKey: "sortCount")
        userDefaults.set(arraySwitch, forKey: "arraySwitch")
                
        defaultMemoCount = -1
        
        if searchSwitch == false {
            self.addMemoButton.setTitle("追加", for: .normal)
            self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを追加",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        } else if searchSwitch == true {
            self.addMemoButton.setTitle("検索", for: .normal)
            self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを検索",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        }
        
        let image = UIImage(systemName: "checkmark.square")
        checkedImageButton.setImage(image, for: .normal)
        checkedImageButton.tintColor = .black
        
        checkedImageButton.imageView?.contentMode = .scaleAspectFit
        checkedImageButton.contentHorizontalAlignment = .fill
        checkedImageButton.contentVerticalAlignment = .fill
        
        addMemoButton.layer.cornerRadius = 10.0
        addMemoButton.layer.borderColor = UIColor.label.cgColor
        addMemoButton.layer.borderWidth = 2.0
        addMemoButton.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 184/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        addMemoButton.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        addMemoButton.layer.shadowColor = UIColor.label.cgColor
        addMemoButton.layer.shadowOpacity = 0.3
        addMemoButton.layer.shadowRadius = 4
        
        titleTextField.layer.cornerRadius = 6.0
        titleTextField.layer.borderColor = UIColor.label.cgColor
        titleTextField.layer.borderWidth = 2.0
        titleTextField.backgroundColor = .systemGray5
        
        titleTextField.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        titleTextField.layer.shadowColor = UIColor.label.cgColor
        titleTextField.layer.shadowOpacity = 0.3
        titleTextField.layer.shadowRadius = 4
        
        menu()
        
        let image3 = UIImage(systemName: "ellipsis")
        menuButton.setImage(image3, for: .normal)
        menuButton.tintColor = .black
        
        let image4 = UIImage(systemName: "multiply.circle")
        deleteButton.setImage(image4, for: .normal)
        deleteButton.tintColor = .gray
        
        
        menuButton.layer.cornerRadius = 10.0
        menuButton.layer.borderColor = UIColor.label.cgColor
        menuButton.layer.borderWidth = 2.0
        menuButton.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 184/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        menuButton.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        menuButton.layer.shadowColor = UIColor.label.cgColor
        menuButton.layer.shadowOpacity = 0.3
        menuButton.layer.shadowRadius = 4
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 184/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        
        ref = Database.database().reference()
        
        userId = Auth.auth().currentUser?.uid
        // tableViewっていう関数を使えるようにするための宣言
        table.dataSource = self
        
        table.delegate = self
        
        table.isEditing = true
        
        table.allowsSelectionDuringEditing = true
        
        listNameLabel.adjustsFontSizeToFitWidth = true
        
        table.register(UINib(nibName: "CustomTableViewCell", bundle: .main), forCellReuseIdentifier: "CustomTableViewCell")
        
        
        titleTextField.delegate = self
        
        print("didLoad") // → didLoad
        print(memoArray) // → ["大根", "人参", "キャベツ"]
        
        memoArray = []
        
        
        // nonCheckに追加されたとき、firebaseのデータを引っ張ってくる
        ref.child("users").child(userId).child(list).child(nonCheck).observe(.childAdded, with: { [self] snapshot in
            let memoId = snapshot.key // memo0とか
            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
            guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
            guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
            let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
            guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
                        
            ref.child("users").child(userId).child(list).child(nonCheck).child(memoId).removeValue()
            ref.child("users").child(userId).child(list).child(memo).child(memoId).updateChildValues(["memoCount": memoCount, "shoppingMemo": shoppingMemo, "isChecked": isChecked, "dateNow": dateNow, "checkedTime": checkedTime, "imageUrl": imageUrl])
            
            switch sortCountInt {
            case 0:
                memoArray.sort {$0.shoppingMemo < $1.shoppingMemo}
            case 1:
                memoArray.sort {$0.shoppingMemo > $1.shoppingMemo}
            case 2:
                memoArray.sort {$0.dateNow < $1.dateNow}
            default:
                memoArray.sort {$0.memoCount < $1.memoCount}
            }
            
            self.table.reloadData()
        })
        
        ref.child("users").child(userId).child(list).child(memo).observe(.childAdded, with: { [self] snapshot in
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
            
            if isChecked == false {
                self.memoArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
            }
            
            switch sortCountInt {
            case 0:
                memoArray.sort {$0.shoppingMemo < $1.shoppingMemo}
            case 1:
                memoArray.sort {$0.shoppingMemo > $1.shoppingMemo}
            case 2:
                memoArray.sort {$0.dateNow < $1.dateNow}
            default:
                memoArray.sort {$0.memoCount < $1.memoCount}
            }
            
            self.table.reloadData()
        })
        
        // nonCheckに変化があったとき
//        ref.child("users").child(userId).child(list).child(nonCheck).observe(.childChanged, with: { [self] snapshot in
//            let memoId = snapshot.key // memo0とか
//            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
//            guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
//            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
//            guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
//            let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
//            guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
//
//
//            dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
//            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//            dateFormatter.timeZone = TimeZone(identifier: "UTC")
//            let date = dateFormatter.date(from: dateNow)
//            let time = date
//
//            let index = self.memoArray.firstIndex(where: {$0.memoId == memoId})
//            memoArray[index!] = ((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time!, imageUrl: imageUrl))
//
//            switch sortCountInt {
//            case 0:
//                memoArray.sort {$0.shoppingMemo < $1.shoppingMemo}
//            case 1:
//                memoArray.sort {$0.shoppingMemo > $1.shoppingMemo}
//            case 2:
//                memoArray.sort {$0.dateNow < $1.dateNow}
//            default:
//                memoArray.sort {$0.memoCount < $1.memoCount}
//            }
//
//            self.table.reloadData()
//        })
        
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
            let time = Date()
            print("time:", time)
            
            let index = self.memoArray.firstIndex(where: {$0.memoId == memoId})
            if index == nil {
                if isChecked == false {
                    memoArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time, imageUrl: imageUrl))
                }
            }else if index != nil {
                if isChecked == false {
                    memoArray[index!] = ((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: date!, checkedTime: time, imageUrl: imageUrl))
                } else if isChecked == true {
                    memoArray.remove(at: index!)
                }
            }
                        
            switch sortCountInt {
            case 0:
                memoArray.sort {$0.shoppingMemo < $1.shoppingMemo}
            case 1:
                memoArray.sort {$0.shoppingMemo > $1.shoppingMemo}
            case 2:
                memoArray.sort {$0.dateNow < $1.dateNow}
            default:
                memoArray.sort {$0.memoCount < $1.memoCount}
            }
            self.table.reloadData()
        })
        
        // nonCheckの中身が消えたとき
//        ref.child("users").child(userId).child(list).child(nonCheck).observe(.childRemoved, with: { [self] snapshot in
//            nonCheckSwitch = userDefaults.bool(forKey: "nonCheckSwitch")
//            print("nonCheckSwitch:", nonCheckSwitch)
//            if nonCheckSwitch == true {
//                let index = memoArray.firstIndex(where: {$0.memoId == snapshot.key})
//                memoArray.remove(at: index!)
//
//                guard let removedMemoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
//                guard let removedShoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
//                guard var removedIsChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
//                guard let removeDateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
//                let removeCheckedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
//                guard let removeImageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
//
//                removedIsChecked = !removedIsChecked
//
//                dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
//                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//                dateFormatter.timeZone = TimeZone(identifier: "UTC")
//                let time = dateFormatter.string(from: Date())
//
//                ref.child("users").child(userId).child(list).child(memo).child(snapshot.key).updateChildValues(["memoCount": removedMemoCount, "shoppingMemo": removedShoppingMemo, "isChecked": removedIsChecked, "dateNow": removeDateNow, "checkedTime": time, "imageUrl": removeImageUrl])
//
//                //            if self.memoArray.isEmpty {
//                //                self.ref.child("users").child(self.userId).child(self.list).setValue("temporaly value")
//                //            }
//                self.table.reloadData()
//            }
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
    
    override func viewDidAppear(_ animated: Bool) {
        ref.child("users").child(userId).child(list).observe(.childChanged, with: { [self] snapshot in
            guard let listName = snapshot.childSnapshot(forPath: "listName").value as? String else { return }
            name = listName
            listNameLabel.text = name
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
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cellCount = 0
        
        if searchSwitch == false {
            cellCount = memoArray.count
        } else if searchSwitch == true {
            cellCount = searchArray.count
        }
        //セルの数を数える→セルの数を決める
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //IDツキノセルヲシュトクシテ、セルフゾクノTextLabelニ「テスト」トヒョウジサセテミル
        // セルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell") as! CustomTableViewCell
        cell.checkDalegate = self
        cell.imageDelegate = self
        cell.indexPath = indexPath
                    
        arraySwitch = userDefaults.bool(forKey: "arraySwitch")
        print("arraySwitch:", arraySwitch)
                
        if arraySwitch == false {
            // セルの中にラベルに配列の要素の値を代入
            cell.memoLabel.text = memoArray[indexPath.row].shoppingMemo
        } else if arraySwitch == true {
            cell.memoLabel.text = searchArray[indexPath.row].shoppingMemo
        }
        
        var backgroundConfig = UIBackgroundConfiguration.listPlainCell()
        backgroundConfig.backgroundColor = UIColor.systemGray5
        
        cell.backgroundConfiguration = backgroundConfig
        
        let imageUrl = memoArray[indexPath.row].imageUrl
        if imageUrl == "" {
            let image = UIImage(systemName: "plus.viewfinder")
            cell.imageButton.setImage(image, for: .normal)
            cell.imageButton.tintColor = .label
        } else {
            let image2 = UIImage(systemName: "photo")
            cell.imageButton.setImage(image2, for: .normal)
            cell.imageButton.tintColor = .label
        }
                
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
        // 最後に設定したセルを表示
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var alertTextField: UITextField!
        let index = indexPath.row
        let memoId = memoArray[index].memoId
        
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
                            let shoppingMemo = self.memoArray[index].shoppingMemo
                            let text = alertTextField.text!
                            self.memoArray[index].shoppingMemo = text
                            print("memoArray:", self.memoArray[index])
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
        if searchSwitch == false {
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
                print("🇯🇵list:", list!)
                self.ref.child("users").child(userId).child(list).child(memo).child("memo\(time)").updateChildValues(["memoCount": defaultMemoCount!, "shoppingMemo": titleTextField.text!, "isChecked": false, "dateNow": time, "checkedTime": time, "imageUrl": ""])
                titleTextField.text = ""
            }
            
        } else if searchSwitch == true {
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
                    let checkedTime = memoArray[i].checkedTime
                    let imageUrl = memoArray[i].imageUrl
                                        
                    if shoppingMemo == text {
                        self.searchArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, checkedTime: checkedTime, imageUrl: imageUrl))
                    }
                }
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
                    self.arraySwitch = true
                    self.userDefaults.set(self.arraySwitch, forKey: "arraySwitch")
                }
            }
        }
        //終わりの文
        return true
    }
    
    @IBAction func addMemo(_ sender: Any) {
        titleTextField.resignFirstResponder()
        if searchSwitch == false {
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
                self.ref.child("users").child(userId).child(list).child(memo).child("memo\(time)").updateChildValues(["memoCount": defaultMemoCount!, "shoppingMemo": titleTextField.text!, "isChecked": false, "dateNow": time, "checkedTime": time, "imageUrl": ""])
                titleTextField.text = ""
            }
            
        } else if searchSwitch == true {
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
                    let checkedTime = memoArray[i].checkedTime
                    let imageUrl = memoArray[i].imageUrl
                                        
                    if shoppingMemo == text {
                        self.searchArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, checkedTime: checkedTime, imageUrl: imageUrl))
                    }
                }
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
                    self.arraySwitch = true
                    self.userDefaults.set(self.arraySwitch, forKey: "arraySwitch")
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
            next?.shoppingMemoName = shoppingMemoName
            next?.memoIdString = memoIdString
            next?.list = list
            next?.imageUrlString = imageUrlString
        }
        
    }
    
    func catchData(count: Array<Any>) {
        memoArray + count
        
    }
    
    func menu() {
        
        print("メニューが呼ばれた。")
        
        let Items = [
            UIAction(title: "追加", image: UIImage(systemName: "plus"), handler: { _ in
                if self.searchSwitch == true {
                    self.addMemoButton.setTitle("追加", for: .normal)
                    self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを追加",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
                    self.searchSwitch = false
                    self.userDefaults.set(self.searchSwitch, forKey: "searchSwitch")
                    self.arraySwitch = false
                    self.userDefaults.set(self.arraySwitch, forKey: "arraySwitch")
                    self.titleTextField.text = ""
                    self.table.reloadData()
                    print("追加モード")
                }
            }),
            UIAction(title:"検索", image: UIImage(systemName: "magnifyingglass"), handler: { _ in
                if self.searchSwitch == false {
                    self.addMemoButton.setTitle("検索", for: .normal)
                    self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを検索",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
                    self.searchSwitch = true
                    self.userDefaults.set(self.searchSwitch, forKey: "searchSwitch")
                    self.arraySwitch = false
                    self.userDefaults.set(self.arraySwitch, forKey: "arraySwitch")
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
                let shoppingMemo = memoArray[i].shoppingMemo
                let isChecked = memoArray[0].isChecked
                let dateNow = memoArray[i].dateNow
                let checkedTime = memoArray[i].checkedTime
                let imageUrl = memoArray[i].imageUrl
                
                memoCount = i
                memoArray[i] = (memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, checkedTime: checkedTime, imageUrl: imageUrl)
                self.ref.child("users").child(userId).child(list).child(memo).child(memoId).updateChildValues(["memoCount": memoCount])
            }
            self.sortCountInt = 3
            userDefaults.set(sortCountInt, forKey: "sortCount")
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
        let time = Date()
        let cTime = dateFormatter.string(from: time)
        self.ref.child("users").child(userId).child(list).child(memo).child(memoId).updateChildValues(["isChecked": true, "checkedTime": cTime])
    }
}

extension ViewController: imageButtonDelegate {
    func buttonTapped(indexPath: IndexPath) {
        print("⤴️buttonTapped成功!")
        self.memoIdString = memoArray[indexPath.row].memoId
        self.shoppingMemoName = memoArray[indexPath.row].shoppingMemo
        self.imageUrlString = memoArray[indexPath.row].imageUrl
        self.performSegue(withIdentifier: "toImageViewVC", sender: nil)
    }
}


