//
//  Event.swift
//  SecondShow
//
//  Created by Alan on 11/15/23.
//

import Foundation
import FirebaseFirestore

struct Event: Codable, Identifiable {
    
    @DocumentID var id: String?
    
    var name: String
    var date: String
    var maxListingNum: Int
    var listingCount: Int
    
    var dateObj: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
    
    var dateMMMdd: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM. dd"

        if let dateObj = dateObj {
            return formatter.string(from: dateObj)
        } else {
            return "ERROR DATE"
        }
    }
}
