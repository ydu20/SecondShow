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
    
    func fetchEventListings(eventId: String, completion: @escaping([DocumentChange]?, String?) -> ())
    
    func fetchUserListings(completion: @escaping([DocumentChange]?, String?) -> ())
    
    func updateListingAvailability(listing: Listing, numSold: Int, completion: @escaping((String?) -> ()))
    
    func increaseListingPopularity(creatorEmail: String, listingId: String, completion: @escaping((String?) -> ()))
    
    func deleteListing(listing: Listing, completion: @escaping((String?) -> ()))
    
    func removeListingListener()
}

class ListingService: ListingServiceProtocol {
    
    private var listingListener: ListenerRegistration?
    
    func increaseListingPopularity(creatorEmail: String, listingId: String, completion: @escaping((String?) -> ())) {
        guard let lastIndex = listingId.lastIndex(of: "_") else { return }
        
        let eventId = String(listingId[..<lastIndex])
        
        let updateData = [
            ListingConstants.popularity: FieldValue.increment(Int64(1))
        ]
        
        
        FirebaseManager.shared.firestore
            .collection("events")
            .document(eventId)
            .collection("listings")
            .document(listingId)
            .updateData(updateData) {err in
                if let err = err {
                    completion("Error incrementing listing popularity: \(err.localizedDescription)")
                    return
                }
                FirebaseManager.shared.firestore
                    .collection("users")
                    .document(creatorEmail)
                    .collection("listings")
                    .document(listingId)
                    .updateData(updateData) {err in
                        if let err = err {
                            completion("Error incrementing user listing popularity: \(err.localizedDescription)")
                            return
                        }
                        completion(nil)
                    }
            }
    }

    func deleteListing(listing: Listing, completion: @escaping((String?) -> ())) {
        guard let user = FirebaseManager.shared.currentUser else {
            completion("Error retrieving local user information")
            return
        }
        
        let listingRef = FirebaseManager.shared.firestore
            .collection("events")
            .document(listing.eventId)
            .collection("listings")
            .document(listing.id ?? "")
        let userListingRef = FirebaseManager.shared.firestore
            .collection("users")
            .document(user.email)
            .collection("listings")
            .document(listing.id ?? "")
        
        listingRef.delete {err in
            if let err = err {
                completion("Error deleting listing: \(err.localizedDescription)")
                return
            }
            userListingRef.delete {err in
                if let err = err {
                    completion("Error deleting user listing: \(err.localizedDescription)")
                    return
                }
                completion(nil)
            }
        }
    }

    
    func updateListingAvailability(listing: Listing, numSold: Int, completion: @escaping((String?) -> ())) {
        
        guard let user = FirebaseManager.shared.currentUser else {
            completion("Error retrieving local user information")
            return
        }
        let listingUpdate = [
            ListingConstants.availableQuantity: listing.availableQuantity - numSold
        ]
        
        let listingRef = FirebaseManager.shared.firestore
            .collection("events")
            .document(listing.eventId)
            .collection("listings")
            .document(listing.id ?? "")
        let userListingRef = FirebaseManager.shared.firestore
            .collection("users")
            .document(user.email)
            .collection("listings")
            .document(listing.id ?? "")
        
        listingRef.updateData(listingUpdate) {err in
            if let err = err {
                completion("Error updating listing: \(err.localizedDescription)")
                return
            }
                
            // Update user listing
            userListingRef.updateData(listingUpdate) {err in
                if let err = err {
                    completion("Error updating user's listing: \(err.localizedDescription)")
                    return
                }
                completion(nil)
            }
        }
    }
    
    
    func fetchUserListings(completion: @escaping([DocumentChange]?, String?) -> ()) {
        guard let user = FirebaseManager.shared.currentUser else {return}
        
        removeListingListener()
        
        listingListener = FirebaseManager.shared.firestore
            .collection("users")
            .document(user.email)
            .collection("listings")
            .addSnapshotListener { querySnapshot, err in
                if let err = err {
                    completion(nil, err.localizedDescription)
                    return
                }
                completion(querySnapshot?.documentChanges, nil)
            }
    }

    func fetchEventListings(eventId: String, completion: @escaping([DocumentChange]?, String?) -> ()) {
        removeListingListener()
        listingListener = FirebaseManager.shared.firestore
            .collection("events")
            .document(eventId)
            .collection("listings")
            .order(by: "listingNumber", descending: false)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    completion(nil, error.localizedDescription)
                    return
                }
                guard let snapshot = querySnapshot else {
                    completion(nil, "Error fetching listings")
                    return
                }
                completion(snapshot.documentChanges, nil)
            }
    }
    
    func removeListingListener() {
        listingListener?.remove()
    }
    
    func createListing(eventId: String, eventName: String, eventDate: String, listingNumber: Int, price: Int, quantity: Int, completion: @escaping((String?) -> ())) {
        guard let user = FirebaseManager.shared.currentUser else {
            completion("Error retrieving local user information")
            return
        }
        
        let listingId = eventId + "_" + String(listingNumber)
        let listingData = [
            ListingConstants.eventId: eventId,
            ListingConstants.eventName: eventName,
            ListingConstants.eventDate: eventDate,
            ListingConstants.listingNumber: listingNumber,
            ListingConstants.createTime: Timestamp(),
            ListingConstants.creatorUsername: user.username,
            ListingConstants.creatorEmail: user.email,
            ListingConstants.price: price,
            ListingConstants.totalQuantity: quantity,
            ListingConstants.availableQuantity: quantity,
            ListingConstants.popularity: 0,
            ListingConstants.expired: false,
        ] as [String: Any]
        
        FirebaseManager.shared.firestore
            .collection("events")
            .document(eventId)
            .collection("listings")
            .document(listingId)
            .setData(listingData) { err in
                if let err = err {
                    completion(err.localizedDescription)
                    return
                }
                // Add listing to user also
                FirebaseManager.shared.firestore
                    .collection("users")
                    .document(user.email)
                    .collection("listings")
                    .document(listingId)
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
