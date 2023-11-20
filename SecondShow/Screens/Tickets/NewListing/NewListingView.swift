//
//  NewListingView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI
import FirebaseFirestore

struct NewListingView: View {
    
    let notifyUser: (String, Color) -> ()
    
    @EnvironmentObject var vm: MainTicketsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var eventName = ""
    @State private var eventDate = Date()
    @State private var quantity = 1
    @State private var price = ""
    
    @State private var newListingWarning = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    TextField("Event Name", text: $eventName)
                        .onReceive(eventName.publisher.collect()) {
                            eventName = String($0.prefix(30))
                        }
                    DatePicker("Event Date", selection: $eventDate, in: Date()..., displayedComponents: .date)
                    
                    Stepper("Number of tickets:  \(quantity)", value: $quantity, in: 1...10)
                    HStack {
                        Text("Price (per ticket)")
                        Spacer()
                        TextField("", text: $price)
                            .frame(width: 46)
                            .frame(height: 30)
                            .multilineTextAlignment(.center)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.quaternaryLabel), lineWidth: 2)
                            )
                            .keyboardType(.numberPad)
                            .onReceive(price.publisher.collect()) {
                                price = String($0.prefix(3)).filter{"0123456789".contains($0)}
                            }
                    }
                }
                Text(self.newListingWarning)
                    .foregroundColor(Color(red: 0.8, green: 0, blue: 0))
                    .offset(y: -UIScreen.main.bounds.height / 2.8 + 200)
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        createListing()
                    } label: {
                        Text("Post")
                    }
                }
            }
        }
    }
    
    private func createListing() {
        // Check price field
        if price == "" {
            newListingWarning = "Please enter a price"
            return
        }
        guard let priceInt = Int(price) else {
            newListingWarning = "Error converting price to integer"
            return
        }
        if priceInt == 0 {
            newListingWarning = "Price cannot be 0"
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        
        var newMaxListingNum = 1
        var newListingCount = 1
        
        var foundEventId: String?
        
        for eventDate in vm.eventDates {
            if let eventInd = eventDate.events.firstIndex(where: {$0.name == eventName}) {
                // Edge case: eventName matches, but eventDate doesn't
                if (eventDate.events[eventInd].date != dateFormatter.string(from: self.eventDate)) {
                    newListingWarning = "An event with the same name already exists on \(eventDate.events[eventInd].date)"
                    return
                }
                newMaxListingNum = eventDate.events[eventInd].maxListingNum + 1
                newListingCount = eventDate.events[eventInd].listingCount + 1
                foundEventId = eventDate.events[eventInd].id
                break
            }
        }
        
        newListingWarning = ""
        presentationMode.wrappedValue.dismiss()
        
        let eventData = [
            EventConstants.name: eventName,
            EventConstants.date: dateFormatter.string(from: eventDate),
            EventConstants.maxListingNum: newMaxListingNum,
            EventConstants.listingCount: newListingCount
        ] as [String: Any]
        
        let eventId = eventName.replacingOccurrences(of: " ", with: "_") + "_" + dateFormatter.string(from: eventDate)
        
        var eventDoc: DocumentReference? = nil
        
        if (newMaxListingNum == 1) {
            // Add new event
            eventDoc = FirebaseManager.shared.firestore
                .collection("events")
                .document(eventId)
            
            guard let eventDoc = eventDoc else {
                notifyUser("Error addinge event", Color(.systemRed))
                return
            }
            eventDoc.setData(eventData) { err in
                if let err = err {
                    notifyUser("Error adding new event: \(err.localizedDescription)", Color(.systemRed))
                    return
                }
                uploadListing(eventDoc: eventDoc, eventData: eventData, listingNumber: newMaxListingNum)
            }
        } else {
            // Update existing event
            if let foundEventId = foundEventId {
                eventDoc = FirebaseManager.shared.firestore.collection("events").document(foundEventId)
                
                if let eventDoc = eventDoc {
                    eventDoc.setData(eventData) { err in
                        if let err = err {
                            notifyUser("Error updating event: \(err.localizedDescription)", Color(.systemRed))
                            return
                        }
                        uploadListing(eventDoc: eventDoc, eventData: eventData, listingNumber: newMaxListingNum)
                    }
                } else {
                    notifyUser("Error updating event: event not found in database", Color(.systemRed))
                    return
                }
            } else {
                notifyUser("Error updating event: local id is nil", Color(.systemRed))
            }
        }
    }
    
    private func uploadListing(eventDoc: DocumentReference, eventData: [String: Any], listingNumber: Int) {
        guard let priceInt = Int(price) else {
            notifyUser("Error converting price to integer", Color(.systemRed))
            return
        }
        let listingData = [
            ListingConstants.eventId: eventDoc.documentID,
            ListingConstants.eventName: eventData[EventConstants.name]!,
            ListingConstants.eventDate: eventData[EventConstants.date]!,
            ListingConstants.listingNumber: listingNumber,
            ListingConstants.createTime: Timestamp(),
            ListingConstants.price: priceInt,
            ListingConstants.totalQuantity: quantity,
            ListingConstants.availableQuantity: quantity,
            ListingConstants.popularity: 0
        ] as [String: Any]
        
        eventDoc.collection("listings").document(String(listingNumber)).setData(listingData) { err in
            if let err = err {
                notifyUser("Error adding new listing: \(err.localizedDescription)", Color(.systemRed))
            } else {
                // Adding listing to user also
                guard let user = FirebaseManager.shared.currentUser else {
                    notifyUser("Error retrievinig local user information", Color(.systemRed))
                    return
                }
                
                FirebaseManager.shared.firestore.collection("users").document(user.uid).collection("listings").addDocument(data: listingData) { error in
                    if let error = error {
                        notifyUser("Error associating listing with user: \(error.localizedDescription)", Color(.systemRed))
                    } else {
                        notifyUser("Listing posted! Your listing number is: \(listingNumber)", Color(.systemGreen))
                    }
                }
            }
        }
        
    }
    
}

struct NewListingView_Previews: PreviewProvider {
    static var previews: some View {
//        NewListingView()
        MainTicketsView(notifyUser: {_, _ in})
    }
}
