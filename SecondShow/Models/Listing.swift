//
//  Listing.swift
//  SecondShow
//
//  Created by Alan on 11/15/23.
//

import Foundation
import FirebaseFirestore

struct Listing: Codable, Identifiable {
    
    @DocumentID var id: String?
    
    let eventId, eventName, eventDate: String
    let listingNumber, price, totalQuantity, availableQuantity, popularity: Int
    let createTime: Date
    let creatorUsername, creatorEmail: String
    
    var eventDateMMMdd: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let dateObj = formatter.date(from: eventDate)
        if let dateObj = dateObj {
            formatter.dateFormat = "MMM. dd"
            return formatter.string(from: dateObj)
        } else {
            return "ERROR DATE"
        }
    }
}
