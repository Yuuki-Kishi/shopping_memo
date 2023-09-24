//
//  ShoppingMemoListViewModel.swift
//  Watch shopping_memo Watch App
//
//  Created by 岸　優樹 on 2023/09/10.
//

import Foundation
import WatchConnectivity

final class WatchViewModel: NSObject {
    var session: WCSession
        
    var memoArray = [(memoId: String, shoppingMemo: String, imageUrl: String)]()
    
    var listName = ""
    
    var delegate: WatchViewModelDelegate? = nil
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
}

extension WatchViewModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        } else {
            print("The session has completed activation.")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
           DispatchQueue.main.async {
               print("ReceiveMessage")
               let notice = message["notice"] as? String ?? ""
               if notice == "sendData" {
                   print("notice")
                   guard let listName = message["listName"] as? String else { return }
                   guard let memoIdArray = message["memoId"] as? Array<String> else { return }
                   guard let shoppingMemoArray = message["shoppingMemo"] as? Array<String> else { return }
                   guard let imageUrlArray = message["imageUrl"] as? Array<String> else { return }
                   for i in 0 ..< memoIdArray.count {
                       self.memoArray.append((memoId: memoIdArray[i], shoppingMemo: shoppingMemoArray[i], imageUrl: imageUrlArray[i]))
                   }
                   print("memoArray:", self.memoArray)
                   
                   self.listName = listName
                   
                   self.delegate?.reloadData()
                   
//                   ContentView().listName = listName
//                   ContentView().memoArray = self.memoArray
                   print("ContentView().memoArray:", ContentView().memoArray)
            } else if notice == "clear" {
                
            }
        }
    }
}

protocol WatchViewModelDelegate {
    func reloadData()
}
