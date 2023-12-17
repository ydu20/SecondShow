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
    
    private let listingService: ListingService
    
    init(listingService: ListingService, notifyUser: @escaping (String, Color) -> ()) {
        print("Initilizing MyListingViewModel...")
        self.listingService = listingService
        self.notifyUser = notifyUser
        
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
        
        let eventRef = FirebaseManager.shared.firestore
            .collection("events")
            .document(eventId)
        
        decreaseEventListingCount(eventRef: eventRef)
        
        guard let userEmail = FirebaseManager.shared.currentUser?.email else {return}
        guard let listingId = selectedListing?.id else {return}
        
        let msgCollectionRef = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(userEmail)
            .collection("messages")
        
        msgCollectionRef
            .whereField(ListingConstants.listingId, isEqualTo: listingId)
            .getDocuments { querySnapshot, err in
                if let err = err {
                    self.notifyUser("Error retrieving recent messages: \(err.localizedDescription)", Color(.systemRed))
                    return
                }
                
                for document in querySnapshot!.documents {
                    guard let counterpartyEmail = document.get(MessageConstants.counterpartyEmail) as? String else {
                        self.notifyUser("Failure retrieving counterpartyEmail", Color(.systemRed))
                        return
                    }
                    let recentMsgId = document.documentID
                    
                    let updateData = deleted ? [MessageConstants.deleted: true] : [MessageConstants.sold: true]
                    
                    msgCollectionRef.document(recentMsgId).updateData(updateData) { err in
                        if let err = err {
                            self.notifyUser("Failure updating seller's recentMessage: \(err.localizedDescription)", Color(.systemRed))
                        }
                    }
                    
                    FirebaseManager.shared.firestore
                        .collection("recent_messages")
                        .document(counterpartyEmail)
                        .collection("messages")
                        .document(listingId + "<->" + userEmail)
                        .updateData(updateData) { err in
                            if let err = err {
                                self.notifyUser("Failure updating buyer's recentMessage: \(err.localizedDescription)", Color(.systemRed))
                            }
                        }
                }
            }
    }
    
    private func decreaseEventListingCount(eventRef: DocumentReference) {
        let eventUpdate = [
            EventConstants.listingCount: FieldValue.increment(Int64(-1))
        ]
        eventRef.updateData(eventUpdate) { err in
            if let err = err {
                self.notifyUser("Error updating event: \(err.localizedDescription)", Color(.systemRed))
                return
            }
        }
    }
    
    private func fetchMyListings() {
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
