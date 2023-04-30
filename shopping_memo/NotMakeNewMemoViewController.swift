//
//  NotMakeNewMemoViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2021/04/09.
//

import UIKit

class NotMakeNewMemoViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let alert: UIAlertController = UIAlertController (title: "メモの新規作成機能について",
                                                          message: "この機能を使うにはログインが必要です。",
                                                          preferredStyle:  .alert)
        
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default,
                                      handler: { action in
                                        print("OKボタンが押されました。")
                                        
                                      }
        )
        )
        present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func make() {
        let alert: UIAlertController = UIAlertController (title: "メモの新規作成機能について",
                                                          message: "この機能を使うにはログインが必要です。",
                                                          preferredStyle:  .alert)
        
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default,
                                      handler: { action in
                                        print("OKボタンが押されました。")
                                        
                                      }
        )
        )
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
