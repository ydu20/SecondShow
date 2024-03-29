//
//  ChatMessage.swift
//  SecondShow
//
//  Created by Alan on 11/21/23.
//

import Foundation
import FirebaseFirestore

struct ChatMessage: Codable, Identifiable {
    
    @DocumentID var id: String?
    
    let listingId, fromEmail, toEmail, message: String
    let timestamp: Date
}
