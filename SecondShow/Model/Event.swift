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
//    var listings: [Listing]?
    
    var dateMMMdd: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        
        let dateObj = formatter.date(from: date)
        if let dateObj = dateObj {
            formatter.dateFormat = "MMM. dd"
            return formatter.string(from: dateObj)
        } else {
            return "ERROR DATE"
        }
    }
}
