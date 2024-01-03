//
//  ProfileViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/21/23.
//

import Foundation
import FirebaseFirestore
import SwiftUI


class ProfileViewModel: ObservableObject {
    
    @Published var myAlerts = [Event]()
    @Published var feedbackInput = ""
    @Published var feedbackStatusMsg = ""
    @Published var feedbackError = true
    
    var eventListener: ListenerRegistration?
    
    private let eventService: EventService
    private let userService: UserService
    private let notifyUser: (String, Color) -> ()
    
    init(eventService: EventService, userService: UserService, notifyUser: @escaping (String, Color) -> ()) {
        self.eventService = eventService
        self.userService = userService
        self.notifyUser = notifyUser
    }
    
    func submitFeedback() {
        if feedbackInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            feedbackError = true
            feedbackStatusMsg = "Please enter feedback"
            return
        }
        
        userService.submitFeedback(feedback: feedbackInput) { err in
            if let err = err {
                self.feedbackError = true
                self.feedbackStatusMsg = err
                return
            }
            self.feedbackError = false
            self.feedbackInput = ""
            self.feedbackStatusMsg = "Thank you for your feedback!"
        }
    }
    
    func deregisterAlert(event: Event) {
        guard let eventId = event.id else {return}

        eventService.removeEventAlert(eventId: eventId) { err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
            self.myAlerts.removeAll(where: {$0.id == eventId})
        }
    }
    
    func removeListener() {
        eventService.removeEventListenerForAlerts()
    }
    
    func fetchMyAlerts() {
        guard let userAlerts = FirebaseManager.shared.currentUser?.alerts else {return}
        
        eventService.fetchEventsForAlerts { documentChanges, err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
            var listenedSet = Set<String>()
            
            documentChanges?.forEach({change in
                if let event = try? change.document.data(as: Event.self) {
                    if !userAlerts.contains(where: {$0 == event.id}) {
                        return
                    }
                    if change.type != .removed {
                        if let eventId = event.id {
                            listenedSet.insert(eventId)
                        }
                        if let ind = self.myAlerts.firstIndex(where: {$0.id ?? "ZZZZ" >= event.id ?? "0000"}) {
                            if (self.myAlerts[ind].id == event.id) {
                                self.myAlerts[ind] = event
                            } else {
                                self.myAlerts.insert(event, at: ind)
                            }
                        } else {
                            self.myAlerts.append(event)
                        }
                    }
                    else {
                        self.myAlerts.removeAll(where: {$0.id == event.id})
                    }
                }
            })
            
            self.myAlerts = self.myAlerts.filter { listenedSet.contains($0.id ?? "_")}
        }
    }
}
