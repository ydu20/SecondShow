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
    
}
