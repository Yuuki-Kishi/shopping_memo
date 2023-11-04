//
//  SettingViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/12.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var ref: DatabaseReference!
    var userId: String!
    var dateFormatter = DateFormatter()
    let userDefaults: UserDefaults = UserDefaults.standard
    var sectionArray = ["自分の情報", "設定"]
    var rowArray = [(Item: String, ItemData: String)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "情報・設定"
        tableViewSetUp()
        setUpAndObserveRealtimeDatabase()
    }
    
    func tableViewSetUp() {
        tableView.register(UINib(nibName: "SettingTableViewCell", bundle: nil), forCellReuseIdentifier: "SettingTableViewCell")
        tableView.register(UINib(nibName: "ImageTableViewCell", bundle: nil), forCellReuseIdentifier: "ImageTableViewCell")
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setUpAndObserveRealtimeDatabase() {
        ref = Database.database().reference()
        userId = Auth.auth().currentUser?.uid
        
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let email = Auth.auth().currentUser?.email
        let create = Auth.auth().currentUser?.metadata.creationDate
        let creationDate = dateFormatter.string(from: create!)
        let lastSignInDate = dateFormatter.string(from: (Auth.auth().currentUser?.metadata.lastSignInDate)!)
        let operationDays = (Calendar.current.dateComponents([.day], from: create!, to: Date()).day)! + 1
        
        ref.child("users").child(userId).child("metadata").observeSingleEvent(of: .value, with: { [self] snapshot in
            let userName = (snapshot.childSnapshot(forPath: "userName").value as? String) ?? "未設定"
            rowArray.append((Item: "ユーザーネーム", ItemData: userName))
            rowArray.append((Item: "メールアドレス", ItemData: email!))
            rowArray.append((Item: "ユーザーID", ItemData: userId!))
            rowArray.append((Item: "自分のQRコード", ItemData: ""))
            rowArray.append((Item: "アカウント作成日", ItemData: creationDate))
            rowArray.append((Item: "最終ログイン日", ItemData: lastSignInDate))
            rowArray.append((Item: "運用日数", ItemData: String(operationDays) + "日目"))
            tableView.reloadData()
        })
        
        ref.child("users").child(userId).observe(.childChanged, with: { [self] snapshot in
            guard let userName = snapshot.childSnapshot(forPath: "userName").value as? String else { return }
            rowArray[0].ItemData = userName
            tableView.reloadData()
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = 50.0
        if indexPath.section == 0 && indexPath.row == 3 { height = 360.0 }
        return height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30)
        
        let title = UILabel()
        title.text = sectionArray[section]
        title.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        title.textColor = .label
        title.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        title.sizeToFit()
        headerView.addSubview(title)

        title.translatesAutoresizingMaskIntoConstraints = false
        title.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        title.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true

        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return rowArray.count }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell") as! SettingTableViewCell
            let imageCell = tableView.dequeueReusableCell(withIdentifier: "ImageTableViewCell") as! ImageTableViewCell
            switch indexPath.row {
            case 0:
                cell.selectionStyle = .default
                cell.ItemLabel.text = rowArray[indexPath.row].Item
                cell.DataLabel.text = rowArray[indexPath.row].ItemData
                return cell
            case 3:
                imageCell.selectionStyle = .none
                imageCell.qrImageView.image = makeQRImage(str: rowArray[2].ItemData)
                imageCell.ItemLabel.text = rowArray[indexPath.row].Item
                imageCell.DataLabel.text = rowArray[indexPath.row].ItemData
                return imageCell
            default:
                cell.selectionStyle = .none
                cell.ItemLabel.text = rowArray[indexPath.row].Item
                cell.DataLabel.text = rowArray[indexPath.row].ItemData
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell") as! SwitchTableViewCell
            cell.ItemLabel.text = "メモを表示しているときスリープをオフにする"
            cell.Switch.isOn = userDefaults.bool(forKey: "notSleepSwitch")
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            var alertTextField: UITextField!
            let userName = rowArray[indexPath.row].ItemData
            tableView.deselectRow(at: indexPath, animated: true)
            let alert: UIAlertController = UIAlertController(title: "ユーザーネームを設定", message: "新しいユーザーネームを入力してください。", preferredStyle: .alert)
            alert.addTextField { textField in
                alertTextField = textField
                alertTextField.returnKeyType = .done
                alertTextField.clearButtonMode = .always
                if userName != "未設定" { alertTextField.text = userName }
                alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
                alert.addAction(UIAlertAction(title: "設定", style: .default, handler: { action in
                            if textField.text != "" {
                                let text = textField.text
                                self.ref.child("users").child(self.userId).child("metadata").updateChildValues(["userName": text!])
                                textField.text = ""
                            }}))}
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func makeQRImage(str: String) -> UIImage {
        let data = str.data(using: String.Encoding.utf8)!
        let qr = CIFilter(name: "CIQRCodeGenerator", parameters: ["inputMessage": data, "inputCorrectionLevel": "M"])!
        let sizeTransform = CGAffineTransform(scaleX: 10, y: 10)
        let qrImage = qr.outputImage!.transformed(by: sizeTransform)
        let context = CIContext()
        let cgImage = context.createCGImage(qrImage, from: qrImage.extent)
        let uiImage = UIImage(cgImage: cgImage!)
        return uiImage
    }
}
