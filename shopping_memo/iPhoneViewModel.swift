//
//  ShoppingMemoListViewModel.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/10.
//

import Foundation
import WatchConnectivity
import UIKit

final class iPhoneViewModel: NSObject {
    var memoArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    var session: WCSession
    
    var iPhoneDelegate: iPhoneViewModelDelegate? = nil

    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
}

extension iPhoneViewModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        } else {
            print("The session has completed activation.")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            let request = message["request"] as? String ?? ""
            if request == "check" {
                guard let index = message["index"] as? Int else { return }
                let indexPath = IndexPath(row: index, section: 0)
                self.iPhoneDelegate?.check(indexPath: indexPath)
            } else if request == "getData" {
                self.iPhoneDelegate?.getData()
            } else if request == "clearData" {
                self.iPhoneDelegate?.cleared()
            }
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}

protocol iPhoneViewModelDelegate {
    func check(indexPath: IndexPath)
    func getData()
    func cleared()
}
