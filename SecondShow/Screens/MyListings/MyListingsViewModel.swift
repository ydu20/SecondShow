//
//  MyListingsViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/18/23.
//

import Foundation
import FirebaseFirestore

class MyListingsViewModel: ObservableObject {
    
    @Published var myAvailableListings = [Listing]()
    @Published var mySoldOutListings = [Listing]()

    private var myListingListener: ListenerRegistration?
    
    init() {
        fetchMyListings()
    }
    
    func fetchMyListings() {
        guard let user = FirebaseManager.shared.currentUser else {return}
        
        myListingListener?.remove()
        myAvailableListings.removeAll()
        mySoldOutListings.removeAll()
        
        myListingListener = FirebaseManager.shared.firestore
            .collection("users")
            .document(user.uid)
            .collection("listings")
//            .order(by: ListingConstants.createTime)
            .addSnapshotListener{ querySnapshot, error in
                if let error = error {
                    print("Failed to listen for user listings: \(error.localizedDescription)")
                }
                
                querySnapshot?.documentChanges.forEach({ change in
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
                
                // For debugging
                print("Snapshot change processed")
                self.myAvailableListings.forEach { myListing in
                    print("\(String(myListing.eventName)): \(String(myListing.price))")
                }
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
