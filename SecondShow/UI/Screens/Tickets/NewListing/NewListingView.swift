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
    
    @State private var showSuggestions: Bool = false
    
    @State private var oneOffSuggestionDisable = false
    @State private var suggestions: [Event] = []
    
    private func updateSuggestions() {
        if eventName.count < 3 {
            suggestions = []
            return
        }
        
        let filteredAndSorted = vm.events.map { event -> (Event, Int) in
                (event, LevenshteinDistance.levDisAugmented(eventName.lowercased(), event.name.lowercased()))
            }
            .filter {$0.1 <= 5}
            .sorted {$0.1 < $1.1}

        suggestions = filteredAndSorted.prefix(5).map{$0.0}
    }
    
    var body: some View {
        NavigationView {
            ZStack (alignment: .top) {
                
                Form {
                    TextField("Event Name", text: $eventName)
                        .onChange(of: eventName) {
                            eventName = String($0.prefix(30))
                            if (!oneOffSuggestionDisable) {
                                if (!showSuggestions && eventName.count >= 3) || (showSuggestions && eventName.count < 3) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        showSuggestions.toggle()
                                    }
                                }
                            } else {
                                oneOffSuggestionDisable = false
                            }
                            
                            updateSuggestions()
                        }
                        .textInputAutocapitalization(.words)
                    
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
                            .onChange(of: price) {
                                price = String($0.prefix(3)).filter{"0123456789".contains($0)}
                            }
                    }
                }
                
                VStack {
                    Text(self.newListingWarning)
                        .foregroundColor(Color(red: 0.8, green: 0, blue: 0))
                }
                .offset(y: 220)
                
                if showSuggestions {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showSuggestions = false
                        }
                }
                
                if showSuggestions {
                    VStack {
                        HStack {
                            VStack {
                                
                                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestedEvent in
                                    HStack {
                                        Button {
                                            showSuggestions = false
                                            oneOffSuggestionDisable = true
                                            eventName = suggestedEvent.name
                                            guard let nonOpDate = suggestedEvent.dateObj else {return}
                                            eventDate = nonOpDate
                                        } label: {
                                            Text(suggestedEvent.name)
                                                .foregroundColor(Color.black)
                                        }
                                        Spacer()
                                    }

                                    if index != suggestions.count - 1 {
                                        Divider()
                                            .padding(.vertical, 2)
                                    }
                                }
                                
                                
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .offset(y: 64)
                    .transition(.opacity)
                }
                
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
        // Validating fields
        if eventName.count == 0 {
            newListingWarning = "Please enter an event name"
            return
        }
        if price.count == 0 {
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
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
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
                notifyUser("Error adding event", Color(.systemRed))
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
            guard let foundEventId = foundEventId else {
                notifyUser("Error updating event: local id is nil", Color(.systemRed))
                return
            }
            
            eventDoc = FirebaseManager.shared.firestore.collection("events").document(foundEventId)
            guard let eventDoc = eventDoc else {
                notifyUser("Error updating event: event not found in database", Color(.systemRed))
                return
            }
            
            eventDoc.setData(eventData) { err in
                if let err = err {
                    notifyUser("Error updating event: \(err.localizedDescription)", Color(.systemRed))
                    return
                }
                uploadListing(eventDoc: eventDoc, eventData: eventData, listingNumber: newMaxListingNum)
            }
        }
    }
    
    private func uploadListing(eventDoc: DocumentReference, eventData: [String: Any], listingNumber: Int) {
        guard let priceInt = Int(price) else {
            notifyUser("Error converting price to integer", Color(.systemRed))
            return
        }
        guard let user = FirebaseManager.shared.currentUser else {
            notifyUser("Error retrievinig local user information", Color(.systemRed))
            return
        }
        
        let listingData = [
            ListingConstants.eventId: eventDoc.documentID,
            ListingConstants.eventName: eventData[EventConstants.name]!,
            ListingConstants.eventDate: eventData[EventConstants.date]!,
            ListingConstants.listingNumber: listingNumber,
            ListingConstants.createTime: Timestamp(),
            ListingConstants.creator: user.email,
            ListingConstants.price: priceInt,
            ListingConstants.totalQuantity: quantity,
            ListingConstants.availableQuantity: quantity,
            ListingConstants.popularity: 0,
        ] as [String: Any]
        
        
        // Add listing to event
        var listingRef: DocumentReference? = nil
        listingRef = eventDoc.collection("listings").addDocument(data: listingData) { err in
            if let err = err {
                notifyUser("Error adding new listing: \(err.localizedDescription)", Color(.systemRed))
                return
            }
            
            // Add listing to user also
            FirebaseManager.shared.firestore.collection("users").document(user.email).collection("listings").document(listingRef!.documentID).setData(listingData) { error in
                if let error = error {
                    notifyUser("Error associating listing with user: \(error.localizedDescription)", Color(.systemRed))
                } else {
                    notifyUser("Listing posted! Your listing number is: \(listingNumber)", Color(.systemGreen))
                }
            }
        }
    }
    
}

struct NewListingView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(
            showLoginView: .constant(false),
            selectedTab: .constant(0),
            userService: UserService(),
            eventService: EventService()
        )
    }
}
