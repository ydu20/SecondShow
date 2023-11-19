//
//  EventViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/16/23.
//

import Foundation
import Firebase
import FirebaseFirestore

class EventViewModel: ObservableObject {
    
    @Published var eventName = ""
    @Published var listings = [Listing]()
    
    private var event: Event?
    private var listingListener: ListenerRegistration?


    init(event: Event?) {
        setEvent(event: event)
        fetchListings()
    }
    
    func fetchListings() {
        guard let event = self.event else {return}
        guard let eventId = event.id else {
            print("Error: local event does not have id")
            return
        }
        
        listingListener?.remove()
        listings.removeAll()
        
        listingListener = FirebaseManager.shared.firestore
            .collection("events")
            .document(eventId)
            .collection("listings")
            .order(by: ListingConstants.listingNumber, descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Failed to listen for events: \(error.localizedDescription)")
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                    if let listing = try? change.document.data(as: Listing.self) {
                        if change.type == .added || (change.type == .modified && listing.availableQuantity != listing.totalQuantity) {
                            if let ind = self.listings.firstIndex(where: {$0.listingNumber <= listing.listingNumber}) {
                                if (self.listings[ind].listingNumber == listing.listingNumber) {
                                    // Modify event
                                    self.listings[ind] = listing
                                } else {
                                    // Add event
                                    self.listings.insert(listing, at: ind)
                                }
                            } else {
                                // Append to end
                                self.listings.append(listing)
                            }
                        } else {
                            // If listing is removed / becomes unavailable
                            if let rmInd = self.listings.firstIndex(where: {$0.listingNumber == listing.listingNumber}) {
                                self.listings.remove(at: rmInd)
                            }
                        }
                    } else {
                        print("Failure codifying listing object")
                    }
                })
                
                // For debugging
//                self.listings.forEach { listing in
//                    print("\(String(listing.listingNumber)): \(String(listing.price))")
//                }
            }
    }
    
    func setEvent(event: Event?) {
        if let event = event {
            self.event = event
            eventName = event.name
        }
    }
    
}
