//
//  User.swift
//  SecondShow
//
//  Created by Alan on 11/15/23.
//

import Foundation
import FirebaseFirestoreSwift

struct User: Codable, Identifiable {

    @DocumentID var id: String?

    let uid, email: String
    let createDate: Date

    var createDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return (formatter.string(from: createDate))
    }
}
