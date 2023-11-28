//
//  MainTicketsViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/15/23.
//

import Foundation
import Firebase
import FirebaseFirestore

class MainTicketsViewModel: ObservableObject {
    
    @Published var eventDates = [EventDate]()
    var events: [Event] {
        var ret: [Event] = []
        eventDates.forEach { eventDate in
            ret += eventDate.events
        }
        return ret
    }
    
    private var eventListener: ListenerRegistration?
    
    init() {
        print("Initilizing mainTicketsViewModel...")
        fetchEvents()
    }
    
    func fetchEvents() {
        eventListener?.remove()
        eventDates.removeAll()
        
        eventListener = FirebaseManager.shared.firestore
            .collection("events")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                querySnapshot?.documentChanges.forEach({change in
                    if let event = try? change.document.data(as: Event.self) {
                        if change.type != .removed {
                            // Add/modify event
                            if let ind = self.eventDates.firstIndex(where: {$0.date == event.date}) {
                                // Date already exists
                                if let eventInd = self.eventDates[ind].events.firstIndex(where: {$0.name >= event.name}) {
                                    if (self.eventDates[ind].events[eventInd].name == event.name) {
                                        // Modify event
                                        self.eventDates[ind].events[eventInd] = event
                                    } else {
                                        // Add event
                                        self.eventDates[ind].events.insert(event, at: eventInd)
                                    }
                                } else {
                                    self.eventDates[ind].events.append(event)
                                }
                            } else {
                                // Date doesn't exist
                                let newEventDate = EventDate(date: event.date, events: [event])
                                
                                if let ind = self.eventDates.firstIndex(where: {$0.date > event.date}) {
                                    self.eventDates.insert(newEventDate, at: ind)
                                } else {
                                    self.eventDates.append(newEventDate)
                                }
                            }
                        } else {
                            // Remove event
                            if let rmInd = self.eventDates.firstIndex(where: {$0.date == event.date}) {
                                if let rmEventInd = self.eventDates[rmInd].events.firstIndex(where: {$0.name == event.name}) {
                                    self.eventDates[rmInd].events.remove(at: rmEventInd)
                                    // Remove eventDate if it doesn't contain any events anymore
                                    if self.eventDates[rmInd].events.count == 0 {
                                        self.eventDates.remove(at: rmInd)
                                    }
                                }
                            }
                        }

                    } else {
                        print("Failure codifying event object")
                    }
                })
            }
        
    }
    
}
