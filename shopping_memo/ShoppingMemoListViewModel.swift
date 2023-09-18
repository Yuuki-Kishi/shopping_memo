//
//  ShoppingMemoListViewModel.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/10.
//

import Foundation
import WatchConnectivity
import UIKit

final class ShoppingMemoListViewModel: NSObject {
    
    var VC = ViewController()
    
    var memoArray = [(memoId: String, memoCount: Int, checkedCount: Int, shoppingMemo: String, isChecked: Bool, dateNow: Date, checkedTime: Date, imageUrl: String)]()
    
    var session: WCSession

    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
        
        memoArray = VC.memoArray
    }
}

extension ShoppingMemoListViewModel: WCSessionDelegate {
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
            
            if request == "sendData" {
                let messages: [String: Any] = ["memoId": self.memoArray.map {$0.memoId}, "shoppingMemo": self.memoArray.map {$0.shoppingMemo}, "isChecked": self.memoArray.map {$0.isChecked}, "imageUrl": self.memoArray.map {$0.imageUrl}]
                session.sendMessage(messages, replyHandler: nil) { (error) in
                    print(error.localizedDescription)
                }
            } else if request == "check" {
                guard let index = message["index"] as? IndexPath else { return }
                self.VC.buttonTapped(indexPath: index)
            }
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    func sessionDidDeactivate(_ session: WCSession) {
    }
}
