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
    
    var eventListener: ListenerRegistration?
    
    private let eventService: EventService
    private let notifyUser: (String, Color) -> ()
    
    init(eventService: EventService, notifyUser: @escaping (String, Color) -> ()) {
        self.eventService = eventService
        self.notifyUser = notifyUser
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
            documentChanges?.forEach({change in
                if let event = try? change.document.data(as: Event.self) {
                    if !userAlerts.contains(where: {$0 == event.id}) {
                        return
                    }
                    if change.type != .removed {
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
        }
    }
}
