//
//  MyListingsViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/18/23.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class MyListingsViewModel: ObservableObject {
    
    @Published var myAvailableListings = [Listing]()
    @Published var myUnavailableListings = [Listing]()
    
    var selectedListing: Listing? = nil
    let notifyUser: (String, Color) -> ()
    
    private let eventService: EventService
    private let listingService: ListingService
    private let messageService: MessageService
    
    init(eventService: EventService, listingService: ListingService, messageService: MessageService, notifyUser: @escaping (String, Color) -> ()) {
        print("Initializing MyListingViewModel...")
        
        self.eventService = eventService
        self.listingService = listingService
        self.notifyUser = notifyUser
        self.messageService = messageService
    }
    
    func updateListing(numSold: Int) {
        guard let listing = selectedListing else {
            notifyUser("Cannot load local listing", Color(.systemRed))
            return
        }
        if listing.availableQuantity - numSold < 0 {
            notifyUser("Error: negative availability after selling", Color(.systemRed))
            return
        }
        listingService.updateListingAvailability(listing: listing, numSold: numSold) { err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
            if (listing.availableQuantity - numSold) == 0 {
                self.handleSoldOutAndDelete(eventId: listing.eventId, deleted: false)
            }
        }
    }
    
    func deleteListing() {
        guard let listing = selectedListing else {
            notifyUser("Cannot load local listing", Color(.systemRed))
            return
        }
        listingService.deleteListing(listing: listing) { err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
            self.handleSoldOutAndDelete(eventId: listing.eventId, deleted: true)
        }
    }
    
    private func handleSoldOutAndDelete(eventId: String, deleted: Bool) {
        guard let userEmail = FirebaseManager.shared.currentUser?.email else {return}
        guard let listingId = selectedListing?.id else {return}
        
        eventService.decreaseEventListingCount(eventId: eventId) { err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
      
            self.messageService.updateRmsOnSoldoutOrDelete(userEmail: userEmail, listingId: listingId, deleted: deleted) { err in
                if let err = err {
                    self.notifyUser(err, Color(.systemRed))
                    return
                }
            }
        }
    }
    
    func removeListener() {
        listingService.removeListingListener()
    }

    func fetchMyListings() {
        listingService.fetchUserListings { documentChanges, err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
            documentChanges?.forEach({change in
                if let myListing = try? change.document.data(as: Listing.self) {
                    if change.type != .removed {
                        if myListing.availableQuantity != 0 && !myListing.expired {
                            // Listing is still available
                            self.insertInPlace(listing: myListing, listings: &self.myAvailableListings)
                        } else {
                            // Listing is no longer available
                            self.myAvailableListings.removeAll(where: {$0.id == myListing.id})
                            self.insertInPlace(listing: myListing, listings: &self.myUnavailableListings)
                        }
                    } else {
                        // Remove all signs of listing
                        self.myAvailableListings.removeAll(where: {$0.id == myListing.id})
                        self.myUnavailableListings.removeAll(where: {$0.id == myListing.id})
                    }
                } else {
                    print("Failure codifying listing object")
                }
            })
        }
    }
    
    private func insertInPlace(listing: Listing, listings: inout [Listing]) {
        if let ind = listings.firstIndex(where: {$0.id ?? "0000" <= listing.id ?? "ZZZZ"}) {
            if (listings[ind].id == listing.id) {
                listings[ind] = listing
            } else {
                listings.insert(listing, at: ind)
            }
        } else {
            listings.append(listing)
        }
    }
}
