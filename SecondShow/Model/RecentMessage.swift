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
    
    let listingId, eventName, counterpartyUid, message: String
    let listingNumber: Int
    let timestamp: Date
    
    let sold, deleted: Bool
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
