//
//  SoldPopupView.swift
//  SecondShow
//
//  Created by Alan on 11/19/23.
//

import SwiftUI
import FirebaseFirestore

struct SoldPopupView: View {
    
    @Binding var showPopupView: Bool
    let listing: Listing?
    let notifyUser: (String, Color) -> ()
    
    @State private var numSold: Double = 1
    
    var body: some View {
        VStack {
            if let listing = self.listing {
                    
                    if (listing.availableQuantity == 1) {
                        Text("Please confirm that you have sold your ticket")
                            .padding(.bottom, 20)
                    } else {
                        Text("How many tickets have you sold?")
                            .padding(.bottom, 15)
                        HStack {
                            Slider(
                                value: $numSold,
                                in: 1...Double(listing.availableQuantity),
                                step: 1
                            )
                            Text(String(Int(numSold)))
                        }
                        .onAppear {
                            numSold = Double(listing.availableQuantity)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                
            } else {
                Text("Error retrieving listing information")
                    .foregroundColor(Color(.red))
                    .padding(.bottom, 20)
            }
            
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showPopupView.toggle()
                    }
                } label: {
                    Text("Cancel")
                        .frame(height: 30)
                        .frame(width: 72)
                        .foregroundColor(Color(.systemRed))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemRed))
                        )
                }
                if listing != nil {
                    Spacer()
                    Button {
                        if listing != nil {
                            // TODO
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showPopupView.toggle()
                            }
                            updateListing()
                        }
                    } label: {
                        Text("Confirm")
                            .frame(height: 30)
                            .frame(width: 76)
                            .foregroundColor(Color(.systemGreen))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGreen))
                            )
                    }
                }

            }
            .padding(.horizontal, 50)
        }
        .frame(width: 300)
        .padding(.vertical, 30)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func deleteListing() {
        guard let listing = listing else {
            notifyUser("Cannot load local listing", Color(.systemRed))
            return
        }
        
        guard let user = FirebaseManager.shared.currentUser else {
            notifyUser("Error retrieving local user information", Color(.systemRed))
            return
        }
        
        let eventRef = FirebaseManager.shared.firestore.collection("events").document(listing.eventId)
        
        let listingRef = eventRef.collection("listings").document(String(listing.listingNumber))
        
        let userListingRef = FirebaseManager.shared.firestore.collection("users").document(user.uid).collection("listings").document(listing.id ?? "")
        
        listingRef.delete { err in
            if let err = err {
                notifyUser("Error deleting listing: \(err.localizedDescription)", Color(.systemRed))
                return
            }
        }
        userListingRef.delete { err in
            if let err = err {
                notifyUser("Error deleting user listing: \(err.localizedDescription)", Color(.systemRed))
            }
            return
        }
        decreaseEventListingCount(eventRef: eventRef)
    }
    
    private func updateListing() {
        guard let listing = listing else {
            notifyUser("Cannot load local listing", Color(.systemRed))
            return
        }
        if listing.availableQuantity - Int(numSold) < 0 {
            notifyUser("Error: negative availability after selling", Color(.systemRed))
            return
        }
        
        let eventRef = FirebaseManager.shared.firestore.collection("events").document(listing.eventId)
        let listingRef = eventRef.collection("listings").document(String(listing.listingNumber))
        
        // Update listing
        listingRef.getDocument { (doc, err) in
            if let err = err {
                notifyUser("Error retrieving listing: \(err.localizedDescription)", Color(.systemRed))
                return
            }
            
            if let doc = doc, doc.exists {
                let listingUpdate = [
                    ListingConstants.availableQuantity: listing.availableQuantity - Int(numSold)
                ]
                listingRef.updateData(listingUpdate) { err in
                    if let err = err {
                        notifyUser("Error updating listing: \(err.localizedDescription)", Color(.systemRed))
                        return
                    }
                    
                    // Update user listing
                    updateUserListing(listing: listing, listingUpdate: listingUpdate)
                    
                    // Update event if listing sells out
                    if listing.availableQuantity - Int(numSold) == 0 {
                        decreaseEventListingCount(eventRef: eventRef)
                    }
                }
                
            } else {
                notifyUser("Error: listing not found in database", Color(.systemRed))
                return
            }
        }
    }
    
    private func decreaseEventListingCount(eventRef: DocumentReference) {
        let eventUpdate = [
            EventConstants.listingCount: FieldValue.increment(Int64(-1))
        ]
        eventRef.updateData(eventUpdate) { err in
            if let err = err {
                notifyUser("Error updating event: \(err.localizedDescription)", Color(.systemRed))
                return
            }
        }
    }
    
    private func updateUserListing(listing: Listing, listingUpdate: [String: Int]) {
        guard let user = FirebaseManager.shared.currentUser else {
            notifyUser("Error retrieving local user information", Color(.systemRed))
            return
        }
        
        let userListingRef = FirebaseManager.shared.firestore.collection("users").document(user.uid).collection("listings").document(listing.id ?? "")
        
        userListingRef.getDocument { (doc, err) in
            if let err = err {
                notifyUser("Error retrieving user listing: \(err.localizedDescription)", Color(.systemRed))
                return
            }
            
            if let doc = doc, doc.exists {
                userListingRef.updateData(listingUpdate) { err in
                    if let err = err {
                        notifyUser("Error updating listing: \(err.localizedDescription)", Color(.systemRed))
                        return
                    }
                }
            } else {
                notifyUser("Error: user listing not found in database", Color(.systemRed))
                return
            }
        }
    }
}

struct SoldPopupView_Previews: PreviewProvider {
    static var previews: some View {
        SoldPopupView(showPopupView: .constant(true), listing: Listing(eventId: "testtesttest", eventName: "Test Event", eventDate: "11-26-2023", listingNumber: 1, price: 15, totalQuantity: 4, availableQuantity: 1, popularity: 14, createTime: Date()), notifyUser: {msg, _ in print(msg)})
        
//        SoldPopupView(showPopupView: .constant(true), listing: nil, notifyUser: {msg, _ in print(msg)})
    }
}
