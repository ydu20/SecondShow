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
    @ObservedObject var vm: MyListingsViewModel
    let notifyUser: (String, Color) -> ()
    
    @State private var numSold: Double = 1
    
    var body: some View {
        VStack {
            if let listing = vm.selectedListing {
                    
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
                if vm.selectedListing != nil {
                    Spacer()
                    Button {
                        if vm.selectedListing != nil {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showPopupView.toggle()
                            }
                            vm.updateListing(numSold: Int(numSold))
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
    
//    private func deleteListing() {
//        guard let listing = listing else {
//            notifyUser("Cannot load local listing", Color(.systemRed))
//            return
//        }
//
//        guard let user = FirebaseManager.shared.currentUser else {
//            notifyUser("Error retrieving local user information", Color(.systemRed))
//            return
//        }
//
//        let eventRef = FirebaseManager.shared.firestore.collection("events").document(listing.eventId)
//
//        let listingRef = eventRef.collection("listings").document(String(listing.listingNumber))
//
//        let userListingRef = FirebaseManager.shared.firestore.collection("users").document(user.uid).collection("listings").document(listing.id ?? "")
//
//        listingRef.delete { err in
//            if let err = err {
//                notifyUser("Error deleting listing: \(err.localizedDescription)", Color(.systemRed))
//                return
//            }
//        }
//        userListingRef.delete { err in
//            if let err = err {
//                notifyUser("Error deleting user listing: \(err.localizedDescription)", Color(.systemRed))
//            }
//            return
//        }
//
////        decreaseEventListingCount(eventRef: eventRef)
//        handleSoldOutAndRemoval(eventRef: eventRef, deleted: true)
//    }
    
//    private func updateListing() {
//        guard let listing = listing else {
//            notifyUser("Cannot load local listing", Color(.systemRed))
//            return
//        }
//
////        print(listing.id)
//        if listing.availableQuantity - Int(numSold) < 0 {
//            notifyUser("Error: negative availability after selling", Color(.systemRed))
//            return
//        }
//
//        let eventRef = FirebaseManager.shared.firestore.collection("events").document(listing.eventId)
//        let listingRef = eventRef.collection("listings").document(listing.id ?? "")
//
//        // Update listing
//        listingRef.getDocument { (doc, err) in
//            if let err = err {
//                notifyUser("Error retrieving listing: \(err.localizedDescription)", Color(.systemRed))
//                return
//            }
//
//            if let doc = doc, doc.exists {
//                let listingUpdate = [
//                    ListingConstants.availableQuantity: listing.availableQuantity - Int(numSold)
//                ]
//                listingRef.updateData(listingUpdate) { err in
//                    if let err = err {
//                        notifyUser("Error updating listing: \(err.localizedDescription)", Color(.systemRed))
//                        return
//                    }
//
//                    // Update user listing
//                    updateUserListing(listing: listing, listingUpdate: listingUpdate)
//
//                    // Update event if listing sells out
//                    if listing.availableQuantity - Int(numSold) == 0 {
////                        decreaseEventListingCount(eventRef: eventRef)
//                        handleSoldOut(eventRef: eventRef)
//                    }
//                }
//
//            } else {
//                notifyUser("Error: listing not found in database", Color(.systemRed))
//                return
//            }
//        }
//    }
    
//    private func handleSoldOut(eventRef: DocumentReference) {
//        decreaseEventListingCount(eventRef: eventRef)
//
//        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
//        guard let listingId = listing?.id else {return}
//
//        let msgCollectionRef = FirebaseManager.shared.firestore
//            .collection("recent_messages")
//            .document(uid)
//            .collection("messages")
//
//        msgCollectionRef
//            .whereField(ListingConstants.listingId, isEqualTo: listingId)
//            .getDocuments { querySnapshot, err in
//                if let err = err {
//                    notifyUser("Error retrieving recent messages: \(err.localizedDescription)", Color(.systemRed))
//                    return
//                }
//
//                for document in querySnapshot!.documents {
//                    guard let counterpartyUid = document.get(MessageConstants.counterpartyUid) as? String else {
//                        notifyUser("Failure retrieving counterpartyUid", Color(.systemRed))
//                        return
//                    }
//                    let recentMsgId = document.documentID
//
//                    let updateData = [MessageConstants.sold: true]
//
//                    msgCollectionRef.document(recentMsgId).updateData(updateData) { err in
//                        if let err = err {
//                            notifyUser("Failure updating seller's recentMessage: \(err.localizedDescription)", Color(.systemRed))
//                        }
//                    }
//
//                    FirebaseManager.shared.firestore
//                        .collection("recent_messages")
//                        .document(counterpartyUid)
//                        .collection("messages")
//                        .document(listingId + "<->" + uid)
//                        .updateData(updateData) { err in
//                            if let err = err {
//                                notifyUser("Failure updating buyer's recentMessage: \(err.localizedDescription)", Color(.systemRed))
//                            }
//                        }
//                }
//            }
//    }
    
//    private func decreaseEventListingCount(eventRef: DocumentReference) {
//        let eventUpdate = [
//            EventConstants.listingCount: FieldValue.increment(Int64(-1))
//        ]
//        eventRef.updateData(eventUpdate) { err in
//            if let err = err {
//                notifyUser("Error updating event: \(err.localizedDescription)", Color(.systemRed))
//                return
//            }
//        }
//    }
    
//    private func updateUserListing(listing: Listing, listingUpdate: [String: Int]) {
//        guard let user = FirebaseManager.shared.currentUser else {
//            notifyUser("Error retrieving local user information", Color(.systemRed))
//            return
//        }
//
//        let userListingRef = FirebaseManager.shared.firestore.collection("users").document(user.uid).collection("listings").document(listing.id ?? "")
//
//        userListingRef.getDocument { (doc, err) in
//            if let err = err {
//                notifyUser("Error retrieving user listing: \(err.localizedDescription)", Color(.systemRed))
//                return
//            }
//
//            if let doc = doc, doc.exists {
//                userListingRef.updateData(listingUpdate) { err in
//                    if let err = err {
//                        notifyUser("Error updating listing: \(err.localizedDescription)", Color(.systemRed))
//                        return
//                    }
//                }
//            } else {
//                notifyUser("Error: user listing not found in database", Color(.systemRed))
//                return
//            }
//        }
//    }
}

struct SoldPopupView_Previews: PreviewProvider {
    static var previews: some View {
        SoldPopupView(showPopupView: .constant(true), vm: MyListingsViewModel(), notifyUser: {msg, _ in print(msg)})
        
//        SoldPopupView(showPopupView: .constant(true), vm: MyListingsViewModel(), notifyUser: {msg, _ in print(msg)})
    }
}
