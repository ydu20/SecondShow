//
//  EventService.swift
//  SecondShow
//
//  Created by Alan on 11/27/23.
//

import Foundation
import Firebase
import FirebaseFirestore

protocol EventServiceProtocol {
    
    func fetchEvents(completion: @escaping(([DocumentChange]?, String?) -> ()))
    
    func addEventAlert(eventId: String, completion: @escaping((String?) -> ()))
    
    func removeEventAlert(eventId: String, completion: @escaping((String?) -> ()))
}

class EventService: EventServiceProtocol {
    
    private var eventListener: ListenerRegistration?
    
    func fetchEvents(completion: @escaping(([DocumentChange]?, String?) -> ())) {
        eventListener?.remove()
        
        eventListener = FirebaseManager.shared.firestore
            .collection("events")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    completion(nil, error.localizedDescription)
                    return
                }
                completion(querySnapshot?.documentChanges, nil)
            }
    }
    
    func addEventAlert(eventId: String, completion: @escaping((String?) -> ())) {
        guard let user = FirebaseManager.shared.currentUser else {return}
        
        let userRef = FirebaseManager.shared.firestore.collection("users").document(user.email)
        userRef.updateData([
            FirebaseConstants.alerts: FieldValue.arrayUnion([eventId])
        ]) {err in
            if let err = err {
                completion(err.localizedDescription)
                return
            }
            completion(nil)
        }
    }
    
    func removeEventAlert(eventId: String, completion: @escaping((String?) -> ())) {
        guard let user = FirebaseManager.shared.currentUser else {return}
        
        let userRef = FirebaseManager.shared.firestore.collection("users").document(user.email)
        userRef.updateData([
            FirebaseConstants.alerts: FieldValue.arrayRemove([eventId])
        ]) {err in
            if let err = err {
                completion(err.localizedDescription)
                return
            }
            completion(nil)
        }
    }

}
