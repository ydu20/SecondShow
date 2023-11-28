//
//  User.swift
//  SecondShow
//
//  Created by Alan on 11/15/23.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {

    @DocumentID var id: String?

    let uid, email: String
    let createTime: Date
    let alerts: [String]?
    
    var createDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return (formatter.string(from: createTime))
    }
}
