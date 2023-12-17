//
//  ListingService.swift
//  SecondShow
//
//  Created by Alan on 11/29/23.
//

import Foundation
import FirebaseFirestore

protocol ListingServiceProtocol {
    
    func createListing(eventId: String, eventName: String, eventDate: String, listingNumber: Int, price: Int, quantity: Int, completion: @escaping((String?) -> ()))
    
}

class ListingService: ListingServiceProtocol {
    
    func createListing(eventId: String, eventName: String, eventDate: String, listingNumber: Int, price: Int, quantity: Int, completion: @escaping((String?) -> ())) {
        guard let user = FirebaseManager.shared.currentUser else {
            completion("Error retrieving local user information")
            return
        }
        
        let listingData = [
            ListingConstants.eventId: eventId,
            ListingConstants.eventName: eventName,
            ListingConstants.eventDate: eventDate,
            ListingConstants.listingNumber: listingNumber,
            ListingConstants.createTime: Timestamp(),
            ListingConstants.creator: user.email,
            ListingConstants.price: price,
            ListingConstants.totalQuantity: quantity,
            ListingConstants.availableQuantity: quantity,
            ListingConstants.popularity: 0,
        ] as [String: Any]
        
        // Add listing to event
        var listingRef: DocumentReference? = nil
        listingRef = FirebaseManager.shared.firestore
            .collection("events")
            .document(eventId)
            .collection("listings")
            .addDocument(data: listingData) { err in
                if let err = err {
                    completion(err.localizedDescription)
                    return
                }
                // Add listing to user also
                FirebaseManager.shared.firestore
                    .collection("users")
                    .document(user.email)
                    .collection("listings")
                    .document(listingRef!.documentID)
                    .setData(listingData) { err in
                        if let err = err {
                            completion(err.localizedDescription)
                            return
                        }
                        completion(nil)
                    }
            }
    }
}
