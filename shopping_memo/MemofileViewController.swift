//
//  MemofileViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2020/12/14.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class MemofileViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet var table: UITableView!
    
    var memofileArray = [String]()
    
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        table.dataSource = self
        
        memofileArray = []
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //セルの数を数える→セルの数を決める
        return memofileArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //IDツキノセルヲシュトクシテ、セルフゾクノTextLabelニ「テスト」トヒョウジサセテミル
        // セルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        // セルの中にラベルに配列の要素の値を代入
        cell?.textLabel?.text = memofileArray[indexPath.row]
        
        // 最後に設定したセルを表示
        return cell!
    }
    
    
    
}
