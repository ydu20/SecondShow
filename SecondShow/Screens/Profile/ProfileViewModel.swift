//
//  ProfileViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/21/23.
//

import Foundation
import FirebaseFirestore


class ProfileViewModel: ObservableObject {
    
    @Published var myAlerts = [Event]()
    
    private var eventListener: ListenerRegistration?
    
    
    init() {
        fetchMyAlerts()
    }
    
    func deregisterAlert(event: Event) {
        guard let user = FirebaseManager.shared.currentUser else {return}
        guard let eventId = event.id else {return}
        
        let userRef = FirebaseManager.shared.firestore.collection("users").document(user.uid)
        userRef.updateData([
            FirebaseConstants.alerts: FieldValue.arrayRemove([eventId])
        ]) {err in
            if let err = err {
                print(err.localizedDescription)
                return
            }
            self.myAlerts.removeAll(where: {$0.id == eventId})
        }
    }
    
    func fetchMyAlerts() {
        guard let userAlerts = FirebaseManager.shared.currentUser?.alerts else {return}
        
        eventListener?.remove()
        myAlerts.removeAll()
        
        eventListener = FirebaseManager.shared.firestore.collection("events").addSnapshotListener { snapshot, err in
            if let err = err {
                print(err.localizedDescription)
                return
            }
            
            snapshot?.documentChanges.forEach({change in
                if let event = try? change.document.data(as: Event.self) {
                    if !userAlerts.contains(where: {$0 == event.id}) {
                        return
                    }
                    if change.type != .removed {
                        if let ind = self.myAlerts.firstIndex(where: {$0.date >= event.date}) {
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
