//
//  ViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/11/15.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth



class ViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate, UITableViewDelegate, checkedMarkDelegete, checkedImageButtonDelegate/*, CatchProtocol, checkedMarkDelegete, checkedImageButtonDelegate*/ {
    
    @IBOutlet weak var checkedListButton: UIButton!
    
    let userDefaults: UserDefaults = UserDefaults.standard
    let dateFormatter = DateFormatter()
    var defaultMemoCount = -1
    var memoSortInt = 3
    var checkedSortInt = 2
    var changedSwitch = false
    var searchSwitch = false
    var arraySwitch = false
    var checkedSwitch = false
    var sectionSwitch = false
    var removeSwitch = false
    var connect = false
    var name: String!
    var memoIdString: String!
    var imageUrlString: String!
    var sectionCount: Int!
    var sectionTitle = ""
    
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
    
    @IBOutlet var connection: UIImageView!
    let checked = "チェック済み"
    let nonCheck = "未チェック"
    let memo = "memo"
    
    var ref: DatabaseReference!
    
    var checkMarks = [false, false, false, false]
    
    // String型の配列
    var memoArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
//    var searchArray = [(memoId: String, memoCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    var checkedArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    var dataArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    @IBOutlet var listNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        listNameLabel.text = name
        
        memoSortInt = userDefaults.integer(forKey: "memoSortInt")
        checkedSortInt = userDefaults.integer(forKey: "checkedSortInt")
        checkedSwitch = userDefaults.bool(forKey: "checkedSwitch")
        
        //if searchSwitch == false {
//        self.addMemoButton.setTitle("追加", for: .normal)
        self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを追加",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
//        } else if searchSwitch == true {
//            self.addMemoButton.setTitle("検索", for: .normal)
//            self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを検索",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
//        }
        
//        let image = UIImage(systemName: "checkmark.square")
//        checkedImageButton.setImage(image, for: .normal)
//        checkedImageButton.tintColor = .black
//
//        checkedImageButton.imageView?.contentMode = .scaleAspectFit
//        checkedImageButton.contentHorizontalAlignment = .fill
//        checkedImageButton.contentVerticalAlignment = .fill
//
//        addMemoButton.layer.cornerRadius = 10.0
//        addMemoButton.layer.borderColor = UIColor.label.cgColor
//        addMemoButton.layer.borderWidth = 2.0
//        addMemoButton.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 184/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
//        addMemoButton.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
//        addMemoButton.layer.shadowColor = UIColor.label.cgColor
//        addMemoButton.layer.shadowOpacity = 0.3
//        addMemoButton.layer.shadowRadius = 4
        
        menu()
        
        let image3 = UIImage(systemName: "ellipsis.circle")
        menuButton.setImage(image3, for: .normal)
        menuButton.tintColor = .black
        
//        let image4 = UIImage(systemName: "multiply.circle")
//        deleteButton.setImage(image4, for: .normal)
//        deleteButton.tintColor = .gray
        
        
//        menuButton.layer.cornerRadius = 10.0
//        menuButton.layer.borderColor = UIColor.label.cgColor
//        menuButton.layer.borderWidth = 2.0
//        menuButton.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 184/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
//        menuButton.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
//        menuButton.layer.shadowColor = UIColor.label.cgColor
//        menuButton.layer.shadowOpacity = 0.3
//        menuButton.layer.shadowRadius = 4
        
        view.backgroundColor = UIColor.dynamicColor(light: UIColor(red: 175/255, green: 239/255, blue: 184/255, alpha: 1), dark: UIColor(red: 147/255, green: 201/255, blue: 158/255, alpha: 1))
        
        
        ref = Database.database().reference()
        
        userId = Auth.auth().currentUser?.uid
        // tableViewっていう関数を使えるようにするための宣言
        table.dataSource = self
        
        table.delegate = self
                
//        table.allowsSelectionDuringEditing = true
        
        listNameLabel.adjustsFontSizeToFitWidth = true
        
        table.register(UINib(nibName: "CustomTableViewCell", bundle: .main), forCellReuseIdentifier: "CustomTableViewCell")
        
        titleTextField.delegate = self
        
        print("didLoad") // → didLoad
        print(memoArray) // → ["大根", "人参", "キャベツ"]
        
        memoArray = []
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                self.connection.image = UIImage(systemName: "wifi")
                self.connect = true
            } else {
                self.connection.image = UIImage(systemName: "wifi.slash")
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
//            switch memoSortInt {
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
            changedSwitch = userDefaults.bool(forKey: "changedSwitch")
            sectionSwitch = userDefaults.bool(forKey: "sectionSwitch")
            let memoId = snapshot.key // memo0とか
            guard let shoppingMemo = snapshot.childSnapshot(forPath: "shoppingMemo").value as? String else { return } // shoppingmemo
            guard let memoCount = snapshot.childSnapshot(forPath: "memoCount").value as? Int else { return }
            let checkedCount = (snapshot.childSnapshot(forPath: "checkedCount").value as? Int) ?? 0
            guard let isChecked = snapshot.childSnapshot(forPath: "isChecked").value as? Bool else { return } // 完了かどうか
            guard let dateNow = snapshot.childSnapshot(forPath: "dateNow").value as? String else { return }
            let checkedTime = (snapshot.childSnapshot(forPath: "checkedTime").value as? String) ?? "20230101000000000"
            guard let imageUrl = snapshot.childSnapshot(forPath: "imageUrl").value as? String else { return }
            
            print("OK")

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
            print("removeSwitch:", self.removeSwitch)
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
        
        table.estimatedSectionHeaderHeight = 0.0
        table.estimatedSectionFooterHeight = 0.0
        
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
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        }
        return sourceIndexPath
    }
    
//    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        let header = view as! UITableViewHeaderFooterView
//        header.textLabel?.textColor = .label
//        header.backgroundColor = .systemGray6
//    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sectionCount = 0
        if !memoArray.isEmpty {
            sectionCount += 1
        } else if !checkedArray.isEmpty && !checkedSwitch {
            sectionCount += 1
        }
        print("sectionCount:", sectionCount)
        return sectionCount
    }
    // Sectionのタイトル
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
        print("sectionTitle:", sectionTitle)
        return sectionTitle
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 60
//    }
    
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 0
//    }
//

//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let headerView = UIView()
//        headerView.backgroundColor = .systemPink
//        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 200)
//
//        let title = UILabel()
//        title.text = "test"
//        title.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
//        title.textColor = .white
//        title.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
//        title.sizeToFit()
//        headerView.addSubview(title)
//
//        title.translatesAutoresizingMaskIntoConstraints = false
//        title.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
//        title.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20).isActive = true
//
//        return headerView
//    }
    
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
        
//
//        if tableView.numberOfSections == 1 {
//            if memoArray.isEmpty {
//                return checkedArray.count
//            }
//        }
//
//        //if searchSwitch == false {
////        if sectionTitle == "未完了" {
//        if section == 0 {
//            cellCount = memoArray.count
//            //        } else if sectionTitle == "完了" {
//        }else if section == 1 {
//            cellCount = checkedArray.count
//        } else {
//            cellCount = 0
//        }
//        } else if searchSwitch == true {
//            cellCount = searchArray.count
//        }
        
//        if tableView.numberOfSections == 2 {
//            if section == 0 {
//                cellCount = memoArray.count
//            } else if section == 1 {
//                cellCount = checkedArray.count
//            }
//        } else if tableView.numberOfSections == 1 {
//            if checkedArray.isEmpty || checkedSwitch {
//                cellCount = memoArray.count
//            } else if memoArray.isEmpty {
//                cellCount = checkedArray.count
//            }
//        }
        //セルの数を数える→セルの数を決める
//        print(cellCount)
        return cellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //IDツキノセルヲシュトクシテ、セルフゾクノTextLabelニ「テスト」トヒョウジサセテミル
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
            cell.checkMarkImageButton.setImage(UIImage(systemName: "square"), for: .normal)
            cell.checkMarkImageButton.tintColor = .label
        }
        
//        if sectionTitle == "未完了" {
//            cell.isCheckedBool = memoArray[indexPath.row].isChecked
//        } else if sectionTitle == "完了" {
//            cell.isCheckedBool = checkedArray[indexPath.row].isChecked
//        }
                
//        arraySwitch = userDefaults.bool(forKey: "arraySwitch")
//        print("arraySwitch:", arraySwitch)
                
//        if arraySwitch == false {
            // セルの中にラベルに配列の要素の値を代入
        
        //MARK: ↓の変数を書き直す
//        sectionCount = tableView.numberOfSections
//
//        if sectionCount == 2 {
//            if indexPath.section == 0 {
//                print("memoArray:", memoArray)
//                if indexPath.row < memoArray.count {
//                    cell.memoLabel.text = memoArray[indexPath.row].shoppingMemo
//                    let imageUrl = memoArray[indexPath.row].imageUrl
//                    if imageUrl == "" {
//                        let image = UIImage(systemName: "plus.viewfinder")
//                        cell.imageButton.setImage(image, for: .normal)
//                        cell.imageButton.tintColor = .label
//                    } else {
//                        let image2 = UIImage(systemName: "photo")
//                        cell.imageButton.setImage(image2, for: .normal)
//                        cell.imageButton.tintColor = .label
//                    }
//                    let image = UIImage(systemName: "square")
//                    cell.checkMarkImageButton.setImage(image, for: .normal)
//                    cell.checkMarkImageButton.tintColor = .label
//                }
//            } else if indexPath.section == 1 {
//                print("checkedArray:", checkedArray)
//                if indexPath.row < checkedArray.count {
//                    cell.memoLabel.text = checkedArray[indexPath.row].shoppingMemo
//                    let imageUrl = checkedArray[indexPath.row].imageUrl
//                    if imageUrl == "" {
//                        let image = UIImage(systemName: "plus.viewfinder")
//                        cell.imageButton.setImage(image, for: .normal)
//                        cell.imageButton.tintColor = .label
//                    } else {
//                        let image2 = UIImage(systemName: "photo")
//                        cell.imageButton.setImage(image2, for: .normal)
//                        cell.imageButton.tintColor = .label
//                    }
//                    let image = UIImage(systemName: "checkmark.square")
//                    cell.checkMarkImageButton.setImage(image, for: .normal)
//                    cell.checkMarkImageButton.tintColor = .label
//                }
//            }
//        } else if sectionCount == 1 {
//            if checkedArray.isEmpty || checkedSwitch {
//                print("memoArray:", memoArray)
//                if indexPath.row < memoArray.count {
//                    cell.memoLabel.text = memoArray[indexPath.row].shoppingMemo
//                    let imageUrl = memoArray[indexPath.row].imageUrl
//                    if imageUrl == "" {
//                        let image = UIImage(systemName: "plus.viewfinder")
//                        cell.imageButton.setImage(image, for: .normal)
//                        cell.imageButton.tintColor = .label
//                    } else {
//                        let image2 = UIImage(systemName: "photo")
//                        cell.imageButton.setImage(image2, for: .normal)
//                        cell.imageButton.tintColor = .label
//                    }
//                    let image = UIImage(systemName: "square")
//                    cell.checkMarkImageButton.setImage(image, for: .normal)
//                    cell.checkMarkImageButton.tintColor = .label
//                }
//            } else if memoArray.isEmpty {
//                print("checkedArray:", checkedArray)
//                if indexPath.row < checkedArray.count {
//                    cell.memoLabel.text = checkedArray[indexPath.row].shoppingMemo
//                    let imageUrl = checkedArray[indexPath.row].imageUrl
//                    if imageUrl == "" {
//                        let image = UIImage(systemName: "plus.viewfinder")
//                        cell.imageButton.setImage(image, for: .normal)
//                        cell.imageButton.tintColor = .label
//                    } else {
//                        let image2 = UIImage(systemName: "photo")
//                        cell.imageButton.setImage(image2, for: .normal)
//                        cell.imageButton.tintColor = .label
//                    }
//                    let image = UIImage(systemName: "checkmark.square")
//                    cell.checkMarkImageButton.setImage(image, for: .normal)
//                    cell.checkMarkImageButton.tintColor = .label
//                }
//            }
//        }

//        } else if arraySwitch == true {
//            cell.memoLabel.text = searchArray[indexPath.row].shoppingMemo
//        }
        
//        var backgroundConfig = UIBackgroundConfiguration.listPlainCell()
//        backgroundConfig.backgroundColor = UIColor.systemGray5
//
//        cell.backgroundConfiguration = backgroundConfig
                
//        print(memoArray[indexPath.row])
//        if memoArray[indexPath.row].isChecked {
//            //            cell.accessoryType = .checkmark
//            //                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
//            //                cell.textLabel?.textColor = UIColor.blue
//
//            //                checkMarks = checkMarks.enumerated().flatMap { (elem: (Int, Bool)) -> Bool in
//            //                    if indexPath.row != elem.0 {
//            //                        let otherCellIndexPath = NSIndexPath(row: elem.0, section: 0)
//            //                        if let otherCell = tableView.cellForRow(at: otherCellIndexPath as IndexPath) {
//            //                            otherCell.accessoryType = .none
//            //                            otherCell.textLabel?.font = UIFont.systemFont(ofSize: 17)
//            //                            otherCell.textLabel?.textColor = UIColor.black
//            //                        }
//            //                    }
//            //                    return indexPath.row == elem.0
//            //                }
//        } else {
//            //            cell.accessoryType = .checkmark
//            cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
//            cell.textLabel?.textColor = UIColor.black
//        }
        // 最後に設定したセルを表示
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var alertTextField: UITextField!
        let index = indexPath.row
        var memoId = ""
        var switchBool: Bool!
        tableView.deselectRow(at: indexPath, animated: true)
        
        if self.sectionCount == 2 {
            if indexPath.section == 0 {
                memoId = memoArray[indexPath.row].memoId
            } else if indexPath.section == 1 {
                memoId = checkedArray[indexPath.row].memoId
            }
        } else if self.sectionCount == 1 {
            if self.sectionTitle == "未完了" {
                memoId = memoArray[indexPath.row].memoId
            } else if self.sectionTitle == "完了" {
                memoId = checkedArray[indexPath.row].memoId
            }
        }
        
        let alert: UIAlertController = UIAlertController(title: "メモの変更", message: "変更後のメモを記入してください。", preferredStyle: .alert)
        alert.addTextField { textField in
            alertTextField = textField
            alertTextField.clearButtonMode = UITextField.ViewMode.always
            alertTextField.returnKeyType = .done
            if self.sectionCount == 2 {
                if indexPath.section == 0 {
                    alertTextField.text = self.memoArray[index].shoppingMemo
                    switchBool = false
                } else if indexPath.section == 1 {
                    alertTextField.text = self.checkedArray[index].shoppingMemo
                    switchBool = true
                }
            } else if self.sectionCount == 1 {
                if self.sectionTitle == "未完了" {
                    alertTextField.text = self.memoArray[index].shoppingMemo
                    switchBool = false
                } else if self.sectionTitle == "完了" {
                    alertTextField.text = self.checkedArray[index].shoppingMemo
                    switchBool = true
                }
            }
            
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                        if alertTextField.text != "" {
                            let text = alertTextField.text!
                            if switchBool {
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
                )
            )
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        //if searchSwitch == false {
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
                print("🇯🇵list:", list!)
                self.ref.child("users").child(userId).child(list).child(memo).child("memo\(time)").updateChildValues(["memoCount": defaultMemoCount, "checkedCount": 0, "shoppingMemo": titleTextField.text!, "isChecked": false, "dateNow": time, "checkedTime": time, "imageUrl": ""])
                titleTextField.text = ""
            }
        } else {
            alert()
        }
            
//        } else if searchSwitch == true {
//            if titleTextField.text == "" {
//                let alert: UIAlertController = UIAlertController(title: "検索できません。", message: "検索キーワードがありません。", preferredStyle: .alert)
//                alert.addAction(
//                    UIAlertAction(
//                        title: "OK",
//                        style: .default
//                    )
//                )
//                self.present(alert, animated: true, completion: nil)
//            } else {
//                searchArray = []
//                for i in 0...memoArray.count - 1 {
//                    let text = titleTextField.text
//                    let memoId = memoArray[i].memoId
//                    let memoCount = memoArray[i].memoCount
//                    let shoppingMemo = memoArray[i].shoppingMemo
//                    let isChecked = memoArray[i].isChecked
//                    let dateNow = memoArray[i].dateNow
//                    let checkedTime = memoArray[i].checkedTime
//                    let imageUrl = memoArray[i].imageUrl
//
//                    if shoppingMemo == text {
//                        self.searchArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, checkedTime: checkedTime, imageUrl: imageUrl))
//                    }
//                }
//                self.table.reloadData()
//
//                if searchArray.count == 0 {
//                    let alert: UIAlertController = UIAlertController(title: "該当項目なし。", message: "該当する項目がありません。", preferredStyle: .alert)
//                    alert.addAction(
//                        UIAlertAction(
//                            title: "OK",
//                            style: .default
//                        )
//                    )
//                    self.present(alert, animated: true, completion: nil)
//                }
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.arraySwitch = true
//                    self.userDefaults.set(self.arraySwitch, forKey: "arraySwitch")
//                }
//            }
//        }
        //終わりの文
        return true
    }
    
//    @IBAction func addMemo(_ sender: Any) {
//        titleTextField.resignFirstResponder()
//        if searchSwitch == false {
//            dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
//            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//            dateFormatter.timeZone = TimeZone(identifier: "UTC")
//            let time = dateFormatter.string(from: Date())
//            if titleTextField.text == "" {
//                let alert: UIAlertController = UIAlertController(title: "メモを追加できません。", message: "記入欄が空白です。", preferredStyle: .alert)
//                alert.addAction(
//                    UIAlertAction(
//                        title: "OK",
//                        style: .default,
//                        handler: { action in
//                        }
//                    )
//                )
//                self.present(alert, animated: true, completion: nil)
//            } else {
//                self.ref.child("users").child(userId).child(list).child(memo).child("memo\(time)").updateChildValues(["memoCount": defaultMemoCount!, "shoppingMemo": titleTextField.text!, "isChecked": false, "dateNow": time, "checkedTime": time, "imageUrl": ""])
//                titleTextField.text = ""
//            }
//
//        } else if searchSwitch == true {
//            if titleTextField.text == "" {
//                let alert: UIAlertController = UIAlertController(title: "検索できません。", message: "検索キーワードがありません。", preferredStyle: .alert)
//                alert.addAction(
//                    UIAlertAction(
//                        title: "OK",
//                        style: .default
//                    )
//                )
//                self.present(alert, animated: true, completion: nil)
//            } else {
//                searchArray = []
//                for i in 0...memoArray.count - 1 {
//                    let text = titleTextField.text
//                    let memoId = memoArray[i].memoId
//                    let memoCount = memoArray[i].memoCount
//                    let shoppingMemo = memoArray[i].shoppingMemo
//                    let isChecked = memoArray[i].isChecked
//                    let dateNow = memoArray[i].dateNow
//                    let checkedTime = memoArray[i].checkedTime
//                    let imageUrl = memoArray[i].imageUrl
//
//                    if shoppingMemo == text {
//                        self.searchArray.append((memoId: memoId, memoCount: memoCount, shoppingMemo: shoppingMemo, isChecked: isChecked, dateNow: dateNow, checkedTime: checkedTime, imageUrl: imageUrl))
//                    }
//                }
//                self.table.reloadData()
//
//                if searchArray.count == 0 {
//                    let alert: UIAlertController = UIAlertController(title: "該当項目なし。", message: "該当する項目がありません。", preferredStyle: .alert)
//                    alert.addAction(
//                        UIAlertAction(
//                            title: "OK",
//                            style: .default
//                        )
//                    )
//                    self.present(alert, animated: true, completion: nil)
//                }
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.arraySwitch = true
//                    self.userDefaults.set(self.arraySwitch, forKey: "arraySwitch")
//                }
//            }
//        }
//    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var deleteAction: UIContextualAction
        // 削除処理
        deleteAction = UIContextualAction(style: .destructive, title: "削除") { (action, view, completionHandler) in
            self.removeSwitch = true
            self.userDefaults.set(self.removeSwitch, forKey: "removeSwitch")
            if self.sectionCount == 2 {
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
            } else if self.sectionCount == 1 {
                if self.sectionTitle == "未完了" {
                    let memoId = self.memoArray[indexPath.row].memoId
                    //削除処理を記述
                    self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).removeValue()
                    self.memoArray.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.automatic)
                    // 実行結果に関わらず記述
                    completionHandler(true)
                } else if self.sectionTitle == "完了" {
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
        
        // segueのIDを確認して特定のsegueのときのみ動作させる
//        if segue.identifier == "toCheckedViewController" {
//            // 2. 遷移先のViewControllerを取得
//            let next = segue.destination as? CheckedViewController
//
//            //            print("😄checkedMemoArray:",checkedMemoArray)
//            // 3. １で用意した遷移先の変数に値を渡す
//            //            next?.checkedArray = checkedMemoArray
//            next?.list = list
//            next?.name = name
//            //            print("nextList:", next?.checkedArray)
//        } else if segue.identifier == "toImageViewVC" {
            let next = segue.destination as? ImageViewViewController
            next?.shoppingMemoName = shoppingMemoName
            next?.memoIdString = memoIdString
            next?.list = list
            next?.imageUrlString = imageUrlString
//        }
        
    }
    
    func catchData(count: Array<Any>) {
        memoArray + count
        
    }
    
    func menu() {
        print("メニューが呼ばれた。")
        let title: String!
        let image: UIImage!
        //        let Items = [
        //            UIAction(title: "追加", image: UIImage(systemName: "plus"), handler: { _ in
        //                if self.searchSwitch == true {
        //                    self.addMemoButton.setTitle("追加", for: .normal)
        //                    self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを追加",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        //                    self.searchSwitch = false
        //                    self.userDefaults.set(self.searchSwitch, forKey: "searchSwitch")
        //                    self.arraySwitch = false
        //                    self.userDefaults.set(self.arraySwitch, forKey: "arraySwitch")
        //                    self.titleTextField.text = ""
        //                    self.table.reloadData()
        //                    print("追加モード")
        //                }
        //            }),
        //            UIAction(title:"検索", image: UIImage(systemName: "magnifyingglass"), handler: { _ in
        //                if self.searchSwitch == false {
        //                    self.addMemoButton.setTitle("検索", for: .normal)
        //                    self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを検索",attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        //                    self.searchSwitch = true
        //                    self.userDefaults.set(self.searchSwitch, forKey: "searchSwitch")
        //                    self.arraySwitch = false
        //                    self.userDefaults.set(self.arraySwitch, forKey: "arraySwitch")
        //                    self.table.reloadData()
        //                    print("検索モード")
        //                }
        //            })
        //        ]
        
        let Items2 = [
            UIAction(title: "五十音順", image: UIImage(systemName: "a.circle"), handler: { _ in
                self.memoSortInt = 0
                self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                self.memoArray.sort {$0.shoppingMemo < $1.shoppingMemo}
                self.table.reloadData()
                print("ソートしました。")
            }),
            UIAction(title: "逆五十音順", image: UIImage(systemName: "z.circle"), handler: { _ in
                self.memoSortInt = 1
                self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                self.memoArray.sort {$0.shoppingMemo > $1.shoppingMemo}
                self.table.reloadData()
                print("ソートしました。")
            }),
            UIAction(title: "最近追加した順", image: UIImage(systemName: "clock"), handler: { _ in
                self.memoSortInt = 2
                self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                self.memoArray.sort {$0.dateNow > $1.dateNow}
                self.table.reloadData()
                print("ソートしました。")
            }),
            UIAction(title: "カスタム", image: UIImage(systemName: "hand.point.up"), handler: { _ in
                self.memoSortInt = 3
                self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                self.memoArray.sort {$0.memoCount < $1.memoCount}
                self.table.reloadData()
                print("ソートしました。")
            })
        ]
        
        let Items3 = [
            UIAction(title: "五十音順", image: UIImage(systemName: "a.circle"), handler: { _ in
                self.checkedSortInt = 0
                self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                self.checkedArray.sort {$0.shoppingMemo < $1.shoppingMemo}
                self.table.reloadData()
                print("ソートしました。")
            }),
            UIAction(title: "逆五十音順", image: UIImage(systemName: "z.circle"), handler: { _ in
                self.checkedSortInt = 1
                self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                self.checkedArray.sort {$0.shoppingMemo > $1.shoppingMemo}
                self.table.reloadData()
                print("ソートしました。")
            }),
            UIAction(title: "最近完了にした順", image: UIImage(systemName: "clock"), handler: { _ in
                self.checkedSortInt = 2
                self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                self.checkedArray.sort {$0.checkedTime > $1.checkedTime}
                self.table.reloadData()
                print("ソートしました。")
            }),
            UIAction(title: "カスタム", image: UIImage(systemName: "hand.point.up"), handler: { _ in
                self.checkedSortInt = 3
                self.userDefaults.set(self.checkedSortInt, forKey: "checkedSortInt")
                self.checkedArray.sort {$0.checkedCount < $1.checkedCount}
                self.table.reloadData()
                print("ソートしました。")
            })
        ]
        
        let Item4 = UIAction(title: "リストの編集", image: UIImage(systemName: "list.bullet"), handler: { _ in
            if self.table.isEditing {
                self.table.isEditing = false
            } else {
                self.table.isEditing = true
                let image = UIImage(systemName: "checkmark")
                self.menuButton.setImage(image, for: .normal)
                self.menuButton.showsMenuAsPrimaryAction = false
            }
            self.table.reloadData()
        })
        
        if checkedSwitch {
            title = "完了項目を表示"
            image = UIImage(systemName: "eye")
            
        } else {
            title = "完了項目を非表示"
            image = UIImage(systemName: "eye.slash")
        }
        
        let Item5 = UIAction(title: title, image: image, handler: { _ in
            if self.checkedSwitch {
                self.checkedSwitch = false
            } else {
                self.checkedSwitch = true
            }
            self.userDefaults.set(self.checkedSwitch, forKey: "checkedSwitch")
            self.menu()
            self.table.reloadData()
        })
        
        let Item6 = UIAction(title: "完了項目を削除", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { _ in
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
                }
            } else {
                self.alert()
            }
            self.removeSwitch = false
            self.userDefaults.set(self.removeSwitch, forKey: "removeSwitch")
        })
        
        //        let sort = UIMenu(title: "モード", children: Items)
        let sort2 = UIMenu(title: "未完了を並び替え", image: UIImage(systemName: "square"),  children: Items2)
        let sort3 = UIMenu(title: "完了を並び替え", image: UIImage(systemName: "checkmark.square"), children: Items3)
        
        print("メニューです。")
        
        menuButton.menu = UIMenu(title: "", options: .displayInline, children: [/*sort, */sort2, sort3, Item4, Item5, Item6])
        
        menuButton.showsMenuAsPrimaryAction = true
        
    }
    
    @IBAction func menuBut() {
        menuButton.showsMenuAsPrimaryAction = true
        table.isEditing = false
        let image = UIImage(systemName: "ellipsis.circle")
        menuButton.setImage(image, for: .normal)
        self.table.reloadData()
    }
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
//    @IBAction func checkedListButtonTapped(_ sender: Any) {
//        self.performSegue(withIdentifier: "toCheckedViewController", sender: nil)
//    }
//
//    @IBAction func toCheckedList2(_ sender: Any) {
//        self.performSegue(withIdentifier: "toCheckedViewController", sender: nil)
//    }
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
        // TODO: 入れ替え時の処理を実装する（データ制御など）
        if sectionCount == 2 {
            if sourceIndexPath.section == 0 {
                let memo = memoArray[sourceIndexPath.row]
                memoArray.remove(at: sourceIndexPath.row)
                memoArray.insert(memo, at: destinationIndexPath.row)
            } else {
                let memo = checkedArray[sourceIndexPath.row]
                checkedArray.remove(at: sourceIndexPath.row)
                checkedArray.insert(memo, at: destinationIndexPath.row)
            }
        } else if sectionCount == 1 {
            if sectionTitle == "未完了" {
                let memo = memoArray[sourceIndexPath.row]
                memoArray.remove(at: sourceIndexPath.row)
                memoArray.insert(memo, at: destinationIndexPath.row)
            } else if sectionTitle == "完了" {
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
        if sectionCount == 2 {
            if indexPath.section == 0 {
                memoArraySort()
            } else {
                checkedArraySort()
            }
        } else if sectionCount == 1 {
            if sectionTitle == "未完了" {
                memoArraySort()
            } else if sectionTitle == "完了" {
                checkedArraySort()
            }
        }
    }
    
    func memoArraySort() {
        if memoArray.count != 0 {
            for i in 0...memoArray.count - 1 {
                print("i:", i)
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
                print("memoId:", memoId)
                self.ref.child("users").child(userId).child(list).child(memo).child(memoId).updateChildValues(["memoCount": memoCount])
            }
        }
    }
    
    func checkedArraySort() {
        if checkedArray.count != 0 {
            for i in 0...checkedArray.count - 1 {
                print("i:", i)
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
                print("finish")
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
                style: .default,
                handler: { action in
                }))
        self.present(alert, animated: true, completion: nil)
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
            if sectionCount == 2 {
                if indexPath.section == 0 {
                    cell.checkMarkImageButton.setImage(nil, for: .normal)
                    let memoId = memoArray[indexPath.row].memoId
                    let time = Date()
                    let cTime = dateFormatter.string(from: time)
                    self.memoSortInt = 3
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["isChecked": true, "checkedTime": cTime])
                    }
                } else if indexPath.section == 1 {
                    cell.checkMarkImageButton.setImage(nil, for: .normal)
                    let memoId = checkedArray[indexPath.row].memoId
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["isChecked": false])
                    }
                }
            } else if sectionCount == 1 {
                if self.sectionTitle == "未完了" {
                    let memoId = memoArray[indexPath.row].memoId
                    let time = Date()
                    let cTime = dateFormatter.string(from: time)
                    self.memoSortInt = 3
                    self.userDefaults.set(self.memoSortInt, forKey: "memoSortInt")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["isChecked": true, "checkedTime": cTime])
                    }
                } else if self.sectionTitle == "完了" {
                    cell.checkMarkImageButton.setImage(nil, for: .normal)
                    let memoId = checkedArray[indexPath.row].memoId
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.ref.child("users").child(self.userId).child(self.list).child(self.memo).child(memoId).updateChildValues(["isChecked": false])
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
        if sectionCount == 2 {
            if indexPath.section == 0 {
                self.memoIdString = memoArray[indexPath.row].memoId
                self.shoppingMemoName = memoArray[indexPath.row].shoppingMemo
                self.imageUrlString = memoArray[indexPath.row].imageUrl
                self.performSegue(withIdentifier: "toImageViewVC", sender: nil)
            } else {
                self.memoIdString = checkedArray[indexPath.row].memoId
                self.shoppingMemoName = checkedArray[indexPath.row].shoppingMemo
                self.imageUrlString = checkedArray[indexPath.row].imageUrl
                self.performSegue(withIdentifier: "toImageViewVC", sender: nil)
            }
        } else if sectionCount == 1 {
            if self.sectionTitle == "未完了" {
                self.memoIdString = memoArray[indexPath.row].memoId
                self.shoppingMemoName = memoArray[indexPath.row].shoppingMemo
                self.imageUrlString = memoArray[indexPath.row].imageUrl
                self.performSegue(withIdentifier: "toImageViewVC", sender: nil)
            } else if self.sectionTitle == "完了" {
                self.memoIdString = checkedArray[indexPath.row].memoId
                self.shoppingMemoName = checkedArray[indexPath.row].shoppingMemo
                self.imageUrlString = checkedArray[indexPath.row].imageUrl
                self.performSegue(withIdentifier: "toImageViewVC", sender: nil)
            }
        }
    }
}


