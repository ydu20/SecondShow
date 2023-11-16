//
//  ListingIdentifier.swift
//  SecondShow
//
//  Created by Alan on 11/15/23.
//

import Foundation
import FirebaseFirestoreSwift

struct ListingIdentifier: Codable, Identifiable {
    
    @DocumentID var id: String?
    
    let showId: String
    let listingNumber: Int
    
}
