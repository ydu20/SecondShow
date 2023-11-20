//
//  DeletePopupView.swift
//  SecondShow
//
//  Created by Alan on 11/20/23.
//

import SwiftUI
import FirebaseFirestore

struct DeletePopupView: View {
    
    @Binding var showPopupView: Bool
    let listing: Listing?
    let notifyUser: (String, Color) -> ()
    
    var body: some View {
        VStack {
            if listing != nil {
                Text("Are you sure you want to delete this listing?")
                    .padding(.bottom, 20)
            } else {
                Text("Error retrieving listing information")
                    .foregroundColor(Color(.red))
                    .padding(.bottom, 20)
            }
            
            HStack {
                Button {
                    showPopupView.toggle()
                } label: {
                    Text("Cancel")
                        .frame(height: 30)
                        .frame(width: 72)
                        .foregroundColor(Color(.secondaryLabel))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.secondaryLabel))
                        )
                }
                if listing != nil {
                    Spacer()
                    Button {
                        if listing != nil {
                            // TODO
                            showPopupView.toggle()
                            deleteListing()
                        }
                    } label: {
                        Text("Delete")
                            .frame(height: 30)
                            .frame(width: 76)
                            .foregroundColor(Color(.systemRed))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemRed))
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
        .shadow(radius: 5)
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

}

struct DeletePopupView_Previews: PreviewProvider {
    static var previews: some View {
        DeletePopupView(showPopupView: .constant(true), listing: Listing(eventId: "testtesttest", eventName: "Test Event", eventDate: "11-26-2023", listingNumber: 1, price: 15, totalQuantity: 4, availableQuantity: 1, popularity: 14, createTime: Date()), notifyUser: {msg, _ in print(msg)})
    }
}
