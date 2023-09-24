//
//  AddMemberViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/14.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class AddMemberViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addButton: UIButton!
    
    var ref = DatabaseReference()
    var dateFormatter = DateFormatter()
    var userIdString: String!
    var email: String!
    var userName: String!
    var roomIdString: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "メンバーを追加"
        
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: "SettingTableViewCell", bundle: nil), forCellReuseIdentifier: "SettingTableViewCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        addButton.layer.cornerRadius = 18.0
        addButton.layer.cornerCurve = .continuous
        addButton.layer.cornerRadius = 10.0
                
        observeRealtimeDatabase()
    }
    
    func observeRealtimeDatabase() {
        ref = Database.database().reference()
        
        ref.child("rooms").child(roomIdString).child("members").observe(.childAdded, with: { [self] snapshot in
            let userId = snapshot.key
            if userId != userIdString {
                ref.child("users").child(userIdString!).observe(.childAdded, with: { snapshot in
                    let item = snapshot.key
                    let email = snapshot.childSnapshot(forPath: "email").value as? String
                    let userName = snapshot.childSnapshot(forPath: "userName").value as? String
                    if item == "metadata" {
                        self.email = email
                        self.userName = userName
                    }
                    self.tableView.reloadData()
                })}
        })
        
        ref.child("users").child(userIdString).observe(.childChanged, with: { [self] snapshot in
            let item = snapshot.key
            guard let email = snapshot.childSnapshot(forPath: "email").value as? String else { return }
            guard let userName = snapshot.childSnapshot(forPath: "userName").value as? String else { return }
            if item == "metadata" {
                self.email = email
                self.userName = userName
            }
            self.tableView.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30)
        
        let title = UILabel()
        title.text = "追加するメンバーの情報"
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
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell") as! SettingTableViewCell
        switch indexPath.row {
        case 0:
            cell.ItemLabel.text = "ユーザーID"
            cell.DataLabel.text = userIdString
        case 1:
            cell.ItemLabel.text = "メールアドレス"
            cell.DataLabel.text = email
        default:
            cell.ItemLabel.text = "ユーザーネーム"
            cell.DataLabel.text = userName
        }
        cell.selectionStyle = .none
        return cell
    }
    
    @IBAction func add() {
        ref.child("rooms").child(roomIdString).child("members").getData(completion:  { error, snapshot in
            guard error == nil else { return }
            let userId = snapshot!.key
            let thisUser = self.userIdString
            let alert: UIAlertController = UIAlertController(title: "本当にこのユーザーを招待しますか？", message: "後から招待したユーザーをルームから追放することができます。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.ref.child("users").child(self.userIdString).observe(.childAdded, with: { snapshot in
                    let item = snapshot.key
                    let email = snapshot.childSnapshot(forPath: "email").value as? String
                    if item == "metadata" {
                        self.ref.child("rooms").child(self.roomIdString).child("members").child(self.userIdString).updateChildValues(["authority": "guest", "email": email!])
                        self.ref.child("users").child(self.userIdString).child("rooms").updateChildValues(["\(self.roomIdString!)": "guset"])
                        self.dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
                        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        self.dateFormatter.timeZone = TimeZone(identifier: "UTC")
                        let time = self.dateFormatter.string(from: Date())
                    }})
                let viewControllers = self.navigationController?.viewControllers
                self.navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
            }))
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    @IBAction func cancel() {
        let viewControllers = self.navigationController?.viewControllers
        self.navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
    }
}
