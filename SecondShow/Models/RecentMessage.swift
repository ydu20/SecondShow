//
//  RecentMessage.swift
//  SecondShow
//
//  Created by Alan on 11/21/23.
//

import Foundation
import FirebaseFirestore

struct RecentMessage: Codable, Identifiable {
    
    @DocumentID var id: String?
    
    let listingId, eventName, counterpartyEmail, message: String
    let listingNumber, price: Int
    let timestamp: Date
    
    let read, sold, deleted, expired: Bool
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
