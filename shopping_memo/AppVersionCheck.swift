//
//  AppVersionCheck.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/06/22.
//

import UIKit

class AppVersionCheck {
    
    static var result = false
    
    static func appVersionCheck() async -> Bool {
        guard let info = Bundle.main.infoDictionary,
            let appVersion = info["CFBundleShortVersionString"] as? String,
            let url = URL(string: "https://itunes.apple.com/jp/lookup?id=6448711012") else { return false }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else { return false}
            
            switch httpResponse.statusCode {
            case 200:
                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
                guard let result = (json?["results"] as? [Any])?.first as? [String: Any],
                      let storeVersion = result["version"] as? String else { return false }
                if appVersion < storeVersion {
                    return true
                }
            default:
                return false
            }
        } catch let error {
            print(error)
        }
        return false
    }
}
