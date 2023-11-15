//
//  SwitchTableViewCell.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/19.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    
    @IBOutlet var ItemLabel: UILabel!
    @IBOutlet var Switch: UISwitch!
    
    let userDefaults: UserDefaults = UserDefaults.standard

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        ItemLabel.adjustsFontSizeToFitWidth = true
    }
    
    @IBAction func notSleepSwitchTapped(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: "notSleepSwitch")
    }
    
}
