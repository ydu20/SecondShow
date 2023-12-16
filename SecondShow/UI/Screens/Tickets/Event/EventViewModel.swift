//
//  EventViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/16/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI

class EventViewModel: ObservableObject {

    @Published var eventName = ""
    @Published var listings = [Listing]()
    @Published var eventAlerts = false

    private var event: Event? = nil
    private let eventService: EventService
    
    private var notifyUser: (String, Color) -> ()
    private var updateChatOnRemoval: ((String, String, Bool) -> ())
    
    
    var listingListener: ListenerRegistration?
    
    
    init(eventService: EventService, notifyUser: @escaping (String, Color) -> (), updateChatOnRemoval: @escaping (String, String, Bool) -> ()) {
        print("Initilizing eventViewModel...")
        
        self.eventService = eventService
        self.notifyUser = notifyUser
        self.updateChatOnRemoval = updateChatOnRemoval
    }
    
    func registerEventAlerts() {
//        guard let user = FirebaseManager.shared.currentUser else {return}
//        guard let eventId = self.event?.id else {return}
//
//        let userRef = FirebaseManager.shared.firestore.collection("users").document(user.email)
//        userRef.updateData([
//            FirebaseConstants.alerts: FieldValue.arrayUnion([eventId])
//        ]) {err in
//            if let err = err {
////                if let notifyUser = self.notifyUser {
//                self.notifyUser(err.localizedDescription, Color(.systemRed))
////                } else {
////                    print(err.localizedDescription)
////                }
//                return
//            }
//            self.eventAlerts = true
//        }
        
        guard let eventId = self.event?.id else {return}
        
        eventService.addEventAlert(eventId: eventId) { err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
            self.eventAlerts = true
        }
    }
    
    func deregisterEventAlerts() {
//        guard let user = FirebaseManager.shared.currentUser else {return}
//        guard let eventId = self.event?.id else {return}
//
//        let userRef = FirebaseManager.shared.firestore.collection("users").document(user.email)
//        userRef.updateData([
//            FirebaseConstants.alerts: FieldValue.arrayRemove([eventId])
//        ]) {err in
//            if let err = err {
////                if let notifyUser = self.notifyUser {
//                self.notifyUser(err.localizedDescription, Color(.systemRed))
////                } else {
////                    print(err.localizedDescription)
////                }
//                return
//            }
//            self.eventAlerts = false
//        }
        
        guard let eventId = self.event?.id else {return}
        
        eventService.removeEventAlert(eventId: eventId) { err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
            self.eventAlerts = false
        }
    }
    
    func fetchListings() {
        guard let event = self.event else {return}
        guard let eventId = event.id else {
            print("Error: local event does not have id")
            return
        }
        
        print("Fetching listings...")
        
        listingListener?.remove()
        listings.removeAll()
        
        listingListener = FirebaseManager.shared.firestore
            .collection("events")
            .document(eventId)
            .collection("listings")
            .whereField(ListingConstants.availableQuantity, isNotEqualTo: 0)
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
                                    // Modify listing
                                    self.listings[ind] = listing
                                } else {
                                    // Add listing
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
                            
                            self.updateChatOnRemoval(listing.id ?? "", listing.creator, change.type == .removed)
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
            self.eventName = event.name
            
            guard let userAlerts = FirebaseManager.shared.currentUser?.alerts else {return}
            guard let eventId = self.event?.id else {return}
    
            self.eventAlerts = userAlerts.contains(eventId)
        }
    }
    
}
