//
//  ListViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2022/11/20.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var listLabel: UILabel!
    
    var listArray = [String]()
    var keyArray = [String]()
    
    
    var ref: DatabaseReference!
    
    var userId: String!
    
    var list: String!
    
    var name: String!
    
    var listCountInt: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listCountInt = userDefaults.integer(forKey: "listCount")
        
        collectionView.register(UINib(nibName: "CustomCell", bundle: nil), forCellWithReuseIdentifier: "CustomCell")
        
        let screenSizeWidth = UIScreen.main.bounds.width
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: screenSizeWidth * 0.39, height: 100)
        collectionView.collectionViewLayout = layout
        
        layout.sectionInset = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
        layout.minimumLineSpacing = 30
        
        userId = Auth.auth().currentUser?.uid
        
        ref = Database.database().reference()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        

        ref.child("users").child(userId).observe(.childAdded, with: { [self] snapshot in
            
            print("⚡️childAdded:")
            
            print("snapshot.key:", snapshot.key)
            print("snapshot.value:", snapshot.childSnapshot(forPath: "name").value!)
            
            let listName = snapshot.childSnapshot(forPath: "name").value as! String
            
            print("🗾listName:", listName)
        
            self.listArray.append(listName)
            
            self.keyArray.append(snapshot.key)
            
            
            print("ぬ1")
            
            
            print("☕️listArray:", self.listArray)
            print("☕️keyArray:", self.keyArray)
            
            print("ぬlistArray:", self.listArray)
            
            print("ぬ3")
            
            self.collectionView.reloadData()
        })
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listArray.count + 1
//        return 12
    }
                                                 
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                                                     
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCell

        if indexPath.row == listArray.count {
            cell.listLabel?.text = "＋"
            
            return cell

        } else {
            cell.listLabel?.text = listArray[indexPath.row]
            
            return cell
        }
        
//
//        let label = cell.contentView.viewWithTag(1) as! UILabel
//
//        label.text = listArray[indexPath.row]

//        let cell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
//
//            //セル上のTag(1)とつけたUILabelを生成
//            let label = cell.contentView.viewWithTag(1) as! UILabel
//
//            //今回は簡易的にセルの番号をラベルのテキストに反映させる
//            label.text = String(indexPath.row + 1)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "toViewControllerFromCollectionView" {
            // 2. 遷移先のViewControllerを取得
            let next = segue.destination as? ViewController
            // 3. １で用意した遷移先の変数に値を渡す
            next?.list = list
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        print("indexPath.row:", indexPath.row)
        print("listArray.count:", listArray.count)
        
        if indexPath.row == listArray.count {
            
            var alertTextField: UITextField!
            
            let alert: UIAlertController = UIAlertController(title: "リストの新規作成", message: "新しく作るリストの名前を入力してください。", preferredStyle: .alert)
            alert.addTextField { textField in
                alertTextField = textField
                alertTextField.returnKeyType = .done
                alert.addAction(
                    UIAlertAction(
                        title: "キャンセル",
                        style: .default,
                        handler: { action in
                        }
                    )
                )
                alert.addAction(
                    UIAlertAction(
                        title: "新規作成",
                        style: .default,
                        handler: { action in
                            if textField.text != "" {
                                let text = textField.text!
                                let checked = ["チェック済み": text]
                                let nonCheck = ["未チェック": text]
                                
                                let data = ["\(text)": text]
                                        
                                self.ref.child("users").child(self.userId).child("list\(self.listCountInt!)").updateChildValues(["name": text, "未チェック": text, "チェック済": text])
                                
                                
                                print("追加なりけり")
                                
                                self.listCountInt += 1
                                self.userDefaults.set(self.listCountInt, forKey: "listCount")
                                
                                
                                textField.text = ""
                            }
                        }
                    )
                )
            }
            self.present(alert, animated: true, completion: nil)
        } else {
            let cell = collectionView.cellForItem(at: indexPath) as! CustomCell
            let key = keyArray[indexPath.row]
            list = key
            print("めぐみんlsit:", list!)
            self.performSegue(withIdentifier: "toViewControllerFromCollectionView", sender: cell.listLabel?.text)
        }
    }
    
    @IBAction func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        self.dismiss(animated: true, completion: nil)
        
    }
}
