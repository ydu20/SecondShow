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
    @Published var mySoldOutListings = [Listing]()
    
    var selectedListing: Listing? = nil
    private var myListingListener: ListenerRegistration?
    var notifyUser: (String, Color) -> ()
    
    private let eventService: EventService
    private let listingService: ListingService
    private let rmService: RecentMessageService
    
    init(eventService: EventService, listingService: ListingService, rmService: RecentMessageService, notifyUser: @escaping (String, Color) -> ()) {
        print("Initializing MyListingViewModel...")
        
        self.eventService = eventService
        self.listingService = listingService
        self.notifyUser = notifyUser
        self.rmService = rmService
        
        fetchMyListings()
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
        
        eventService.decreaseEventListingCount(eventId: eventId) { err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
        }
        
        guard let userEmail = FirebaseManager.shared.currentUser?.email else {return}
        guard let listingId = selectedListing?.id else {return}
  
        rmService.updateRmsOnSoldoutOrDelete(userEmail: userEmail, listingId: listingId, deleted: deleted) { err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
        }
    }

    func fetchMyListings() {
        myAvailableListings.removeAll()
        mySoldOutListings.removeAll()
        
        listingService.fetchUserListings { documentChanges, err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
            documentChanges?.forEach({change in
                if let myListing = try? change.document.data(as: Listing.self) {
                    if change.type == .added {
                        if (myListing.availableQuantity != 0) {
                            self.insertInPlace(listing: myListing, listings: &self.myAvailableListings)
                        } else {
                            self.insertInPlace(listing: myListing, listings: &self.mySoldOutListings)
                        }
                    }
                    else if change.type == .modified {
                        let availableInd = self.myAvailableListings.firstIndex(where: {$0.id == myListing.id})
                        let soldOutInd = self.mySoldOutListings.firstIndex(where: {$0.id == myListing.id})
                        
                        if (myListing.availableQuantity != 0) {
                            // Listing still available
                            if let availableInd = availableInd {
                                self.myAvailableListings[availableInd] = myListing
                            } else {
                                self.insertInPlace(listing: myListing, listings: &self.myAvailableListings)
                            }
                        } else {
                            // Listing sold out
                            if availableInd != nil {
                                self.myAvailableListings.removeAll(where: {$0.id == myListing.id})
                                self.insertInPlace(listing: myListing, listings: &self.mySoldOutListings)
                            } else {
                                if let soldOutInd = soldOutInd {
                                    self.mySoldOutListings[soldOutInd] = myListing
                                } else {
                                    self.insertInPlace(listing: myListing, listings: &self.mySoldOutListings)
                                }
                            }
                        }
                    }
                    else {
                        self.myAvailableListings.removeAll(where: {$0.id == myListing.id})
                        self.mySoldOutListings.removeAll(where: {$0.id == myListing.id})
                    }
                } else {
                    print("Failure codifying listing object")
                }
            })
        }
    }
    
    private func insertInPlace(listing: Listing, listings: inout [Listing]) {
        if let ind = listings.firstIndex(where: {$0.createTime < listing.createTime}) {
            listings.insert(listing, at: ind)
        } else {
            listings.append(listing)
        }
    }
}
