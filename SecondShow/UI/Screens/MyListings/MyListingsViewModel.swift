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
        
        let eventRef = FirebaseManager.shared.firestore.collection("events").document(listing.eventId)
        let listingRef = eventRef.collection("listings").document(listing.id ?? "")
        
        // Update listing
        listingRef.getDocument { (doc, err) in
            if let err = err {
                self.notifyUser("Error retrieving listing: \(err.localizedDescription)", Color(.systemRed))
                return
            }
            
            if let doc = doc, doc.exists {
                let listingUpdate = [
                    ListingConstants.availableQuantity: listing.availableQuantity - numSold
                ]
                listingRef.updateData(listingUpdate) { err in
                    if let err = err {
                        self.notifyUser("Error updating listing: \(err.localizedDescription)", Color(.systemRed))
                        return
                    }
                    
                    // Update user listing
                    self.updateUserListing(listing: listing, listingUpdate: listingUpdate)
                    
                    // Update event if listing sells out
                    if listing.availableQuantity - Int(numSold) == 0 {
                        self.handleSoldOutAndDelete(eventRef: eventRef, deleted: false)
                    }
                }
                
            } else {
                self.notifyUser("Error: listing not found in database", Color(.systemRed))
                return
            }
        }
    }
    
    private func updateUserListing(listing: Listing, listingUpdate: [String: Int]) {
        guard let user = FirebaseManager.shared.currentUser else {
            notifyUser("Error retrieving local user information", Color(.systemRed))
            return
        }
        
        let userListingRef = FirebaseManager.shared.firestore.collection("users").document(user.email).collection("listings").document(listing.id ?? "")
        
        userListingRef.getDocument { (doc, err) in
            if let err = err {
                self.notifyUser("Error retrieving user listing: \(err.localizedDescription)", Color(.systemRed))
                return
            }
            
            if let doc = doc, doc.exists {
                userListingRef.updateData(listingUpdate) { err in
                    if let err = err {
                        self.notifyUser("Error updating listing: \(err.localizedDescription)", Color(.systemRed))
                        return
                    }
                }
            } else {
                self.notifyUser("Error: user listing not found in database", Color(.systemRed))
                return
            }
        }
    }
    
    func deleteListing() {
        guard let listing = selectedListing else {
            notifyUser("Cannot load local listing", Color(.systemRed))
            return
        }
        
        guard let user = FirebaseManager.shared.currentUser else {
            notifyUser("Error retrieving local user information", Color(.systemRed))
            return
        }
        
        let eventRef = FirebaseManager.shared.firestore.collection("events").document(listing.eventId)
        
        let listingRef = eventRef.collection("listings").document(listing.id ?? "")
        
        let userListingRef = FirebaseManager.shared.firestore.collection("users").document(user.email).collection("listings").document(listing.id ?? "")
        
        listingRef.delete { err in
            if let err = err {
                self.notifyUser("Error deleting listing: \(err.localizedDescription)", Color(.systemRed))
                return
            }
        }
        userListingRef.delete { err in
            if let err = err {
                self.notifyUser("Error deleting user listing: \(err.localizedDescription)", Color(.systemRed))
            }
            return
        }
        handleSoldOutAndDelete(eventRef: eventRef, deleted: true)
    }
    
    private func handleSoldOutAndDelete(eventRef: DocumentReference, deleted: Bool) {
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
