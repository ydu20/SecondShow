//
//  ConfigManager.swift
//  SecondShow
//
//  Created by Alan on 1/23/24.
//

import Foundation

class ConfigManager {
    
    var requireVerification: Bool
    var requirePennEmail: Bool
    
    static let shared = ConfigManager()
    
    init() {
        self.requireVerification = false
        self.requirePennEmail = true
        
        FirebaseManager.shared.firestore
            .collection("config")
            .document("config")
            .getDocument() { document, err in
                if let err = err {
                    print(err)
                    return
                }
                if let data = document?.data() {
                    self.requireVerification = data["requireVerification"] as? Bool ?? true
                    self.requirePennEmail = data["requirePennEmail"] as? Bool ?? true
                }
            }
    }
}
