//
//  ShoppingMemoListViewModel.swift
//  Watch shopping_memo Watch App
//
//  Created by 岸　優樹 on 2023/09/10.
//

import Foundation
import WatchConnectivity

final class ShoppingMemoListViewModel: NSObject {
    var session: WCSession
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
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
}
