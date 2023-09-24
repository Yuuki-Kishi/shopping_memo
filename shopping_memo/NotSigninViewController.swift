//
//  NotSigninViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2021/04/08.
//

import UIKit

class NotSigninViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var table: UITableView!
    
    var memoArray = [String]()
    let userDefaults: UserDefaults = UserDefaults.standard
    var menuBarButtonItem: UIBarButtonItem!
    var backBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "メモ"
        
        table.register(UINib(nibName: "CustomTableViewCell", bundle: nil), forCellReuseIdentifier: "CustomTableViewCell")
                
        self.titleTextField.attributedPlaceholder = NSAttributedString(string: "アイテムを追加",attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        
        if userDefaults.array(forKey: "memoArray") != nil {
            memoArray = userDefaults.array(forKey: "memoArray") as! [String]
            self.table.reloadData()
        }
                
        table.delegate = self
        table.dataSource = self
        titleTextField.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memoArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell") as! CustomTableViewCell
        cell.memoLabel?.text = memoArray[indexPath.row]
        cell.checkMarkImageButton.setImage(UIImage(systemName: "square"), for: .normal)
        cell.checkMarkImageButton.tintColor = .label
        cell.checkMarkImageButton.isUserInteractionEnabled = false
        cell.imageButton.isHidden = true
        return cell
    }
    
    func tableView(_ tableVew: UITableView, didSelectRowAt indexPath: IndexPath) {
        memoArray.remove(at: indexPath.row)
        userDefaults.set(memoArray, forKey: "memoArray")
        self.table.reloadData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField.text == "" {
            let alert: UIAlertController = UIAlertController(title: "メモを追加できません。", message: "記入欄が空白です。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        } else {
            memoArray.insert(textField.text!, at: 0)
            userDefaults.set(memoArray, forKey: "memoArray")
            textField.text = ""
            self.table.reloadData()
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var editAction: UIContextualAction
        let memo = memoArray[indexPath.row]
        // 削除処理
        editAction = UIContextualAction(style: .destructive, title: "編集") { (action, view, completionHandler) in
            var alertTextField: UITextField!
            let alert: UIAlertController = UIAlertController(title: "メモの名称変更", message: "新しいメモの名前を入力してください。", preferredStyle: .alert)
            alert.addTextField { textField in
                alertTextField = textField
                alertTextField.clearButtonMode = UITextField.ViewMode.always
                alertTextField.returnKeyType = .done
                alertTextField.text = memo
                alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            if alertTextField.text != "" {
                                let text = alertTextField.text!
                                self.memoArray[indexPath.row] = text
                                self.userDefaults.set(self.memoArray, forKey: "memoArray")
                                self.table.reloadData()
                            }
                        }))
                self.present(alert, animated: true, completion: nil)
            }
            completionHandler(true)
        }
        editAction.backgroundColor = UIColor.systemBlue
        return UISwipeActionsConfiguration(actions: [editAction])
    }
}
