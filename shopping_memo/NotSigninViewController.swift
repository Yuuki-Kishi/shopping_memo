//
//  NotSigninViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2021/04/08.
//

import UIKit

class NotSigninViewController: UIViewController, UITableViewDataSource {
    
    
    @IBOutlet var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let alert: UIAlertController = UIAlertController (title: "ログインについて",
                                                          message: "このアプリを使うにはログインが必要です。ログインしないと一部機能が使えなくなります。",
                                                          preferredStyle:  .alert)
        
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default,
                                      handler: { action in
                                                 print("OKボタンが押されました。")
        
                                               }
                                            )
                                        )
        present(alert, animated: true, completion: nil)
        
        table.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        cell?.textLabel?.text = "メモ"
        
        return cell!
    }
    
    func tableView(_ tableVew: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = table.cellForRow(at: indexPath)
        self.performSegue(withIdentifier: "toDemoMemo", sender: cell?.textLabel?.text!)
    }
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }



}
