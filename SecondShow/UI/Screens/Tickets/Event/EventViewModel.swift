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
    private let listingService: ListingService
    
    private var notifyUser: (String, Color) -> ()
    private var updateChatOnRemoval: ((String, String, Bool) -> ())
    
    
    var listingListener: ListenerRegistration?
    
    init(eventService: EventService, listingService: ListingService, notifyUser: @escaping (String, Color) -> (), updateChatOnRemoval: @escaping (String, String, Bool) -> ()) {
        
        print("Initilizing eventViewModel...")
        self.eventService = eventService
        self.listingService = listingService
        self.notifyUser = notifyUser
        self.updateChatOnRemoval = updateChatOnRemoval
    }
    
    func registerEventAlerts() {
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
        guard let eventId = self.event?.id else {
            print("Error: event id is nil")
            return
        }
        
        print("Fetching listings...")
        
        listings.removeAll()
        listingService.fetchEventListings(eventId: eventId) { documentChanges, err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
            guard let documentChanges = documentChanges else {
                self.notifyUser("Error fetching listings", Color(.systemRed))
                return
            }
            
            documentChanges.forEach { change in
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
            }
        }
    }
    
    func setEvent(event: Event?) {
        if let event = event {
            self.event = event
            self.eventName = event.name
            
            guard let eventId = self.event?.id else {return}
            guard let userAlerts = FirebaseManager.shared.currentUser?.alerts else {return}
    
            self.eventAlerts = userAlerts.contains(eventId)
        }
    }
    
}
