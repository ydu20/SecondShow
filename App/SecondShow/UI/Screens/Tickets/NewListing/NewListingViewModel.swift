//
//  NewListingViewModel.swift
//  SecondShow
//
//  Created by Alan on 12/16/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class NewListingViewModel: ObservableObject {
    
    @Published var eventName = ""
    @Published var eventDate = Date()
    @Published var quantity = 1
    @Published var price = ""
    @Published var newListingWarning = ""
    @Published var showSuggestions = false
    @Published var suggestions: [Event] = []
    @Published var oneOffSuggestionDisable = false
    
    private let eventService: EventService
    private let listingService: ListingService
    
    private let notifyUser: (String, Color) -> ()
    private let getEvents: () -> [Event]
    private let getEventDates: () -> [EventDate]
    private let dismissView: () -> ()
    
    init(
        eventService: EventService,
        listingService: ListingService,
        notifyUser: @escaping (String, Color) -> (),
        getEvents: @escaping () -> [Event],
        getEventDates: @escaping () -> [EventDate],
        dismissView: @escaping () -> ()
    ) {
        self.eventService = eventService
        self.listingService = listingService
        
        self.notifyUser = notifyUser
        self.getEvents = getEvents
        self.getEventDates = getEventDates
        self.dismissView = dismissView
    }
    
    func updateSuggestions() {
        if eventName.count < 3 {
            suggestions = []
            return
        }
        
        let filteredAndSorted = self.getEvents().map { event -> (Event, Int) in
                (event, LevenshteinDistance.levDisAugmented(eventName.lowercased(), event.name.lowercased()))
            }
            .filter {$0.1 <= 5}
            .sorted {$0.1 < $1.1}

        suggestions = filteredAndSorted.prefix(5).map{$0.0}
    }
    
    
    func createListing() {
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
        
        // Check if event already exists
        var foundEvent: Event?
        for eventDate in self.getEventDates() {
            if let eventInd = eventDate.events.firstIndex(where: {$0.name == eventName}) {
                // Edge case: eventName matches, but eventDate doesn't
                if (eventDate.events[eventInd].date != dateFormatter.string(from: self.eventDate)) {
                    newListingWarning = "An event with the same name already exists on \(eventDate.events[eventInd].date)"
                    return
                }
                foundEvent = eventDate.events[eventInd]
                break
            }
        }
        
        newListingWarning = ""
        self.dismissView()
        
        let eventDateStr = dateFormatter.string(from: eventDate)
        let eventId = eventDateStr + "_" + eventName.replacingOccurrences(of: " ", with: "_")
        
        // Create or update event in firestore
        eventService.createOrUpdateEvent(
            id: eventId,
            name: eventName,
            date: eventDateStr,
            maxListingNum: (foundEvent?.maxListingNum ?? 0) + 1,
            listingCount: (foundEvent?.listingCount ?? 0) + 1
        ) { err in
            if let err = err {
                self.notifyUser("Error creating/updating event: \(err)", Color(.systemRed))
                return
            }
            // Create listing
            self.uploadListing(
                eventId: eventId,
                eventName: self.eventName,
                eventDate: eventDateStr,
                listingNumber: (foundEvent?.maxListingNum ?? 0) + 1
            )
        }
    }
    
    private func uploadListing(eventId: String, eventName: String, eventDate: String, listingNumber: Int) {
        guard let priceInt = Int(price) else {
            notifyUser("Error converting price to integer", Color(.systemRed))
            return
        }
        listingService.createListing(
            eventId: eventId,
            eventName: eventName,
            eventDate: eventDate,
            listingNumber: listingNumber,
            price: priceInt,
            quantity: quantity
        ) { err in
            if let err = err {
                self.notifyUser("Error creating listing: \(err)", Color(.systemRed))
                return
            }
            self.notifyUser("Listing posted! Your listing number is: \(listingNumber)", Color(.systemGreen))
        }
        
    }
}
