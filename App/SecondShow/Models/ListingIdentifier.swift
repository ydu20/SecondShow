//
//  ListingIdentifier.swift
//  SecondShow
//
//  Created by Alan on 11/15/23.
//

import Foundation
import FirebaseFirestore

struct ListingIdentifier: Codable, Identifiable {
    
    @DocumentID var id: String?
    
    let eventId: String
    let listingNumber: Int
    
}
