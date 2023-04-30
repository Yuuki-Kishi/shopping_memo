//
//  NotViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2021/04/09.
//

import UIKit

class NotViewController: UIViewController {
    
    var demoArray = [String]()
    
    @IBOutlet weak var TextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 10
            
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
            
            cell?.textLabel?.text = demoArray[indexPath.row].self
            
            cell?.textLabel?.text = "メモ"
            
            return cell!
        }
        
        func Tuika() {
            demoArray.append(TextField.text!)
            
            TextField.text = ""
            
        }
        
    }
}
