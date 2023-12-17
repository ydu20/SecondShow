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
    
    func createOrUpdateEvent(id: String, name: String, date: String, maxListingNum: Int, listingCount: Int, completion: @escaping((String?) -> ()))
    
    func fetchEvents(completion: @escaping(([DocumentChange]?, String?) -> ()))
    
    func addEventAlert(eventId: String, completion: @escaping((String?) -> ()))
    
    func removeEventAlert(eventId: String, completion: @escaping((String?) -> ()))
    
    func removeEventListener()
    
    
}

class EventService: EventServiceProtocol {
    
    private var eventListener: ListenerRegistration?
    
    func createOrUpdateEvent(id: String, name: String, date: String, maxListingNum: Int, listingCount: Int, completion: @escaping((String?) -> ())) {
        let eventData = [
            EventConstants.name: name,
            EventConstants.date: date,
            EventConstants.maxListingNum: maxListingNum,
            EventConstants.listingCount: listingCount
        ] as [String : Any]
        
        FirebaseManager.shared.firestore
            .collection("events")
            .document(id)
            .setData(eventData) { err in
                if let err = err {
                    completion(err.localizedDescription)
                    return
                }
                completion(nil)
            }
    }
        
    func fetchEvents(completion: @escaping(([DocumentChange]?, String?) -> ())) {
        removeEventListener()
        
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
        
        let userRef = FirebaseManager.shared.firestore
            .collection("users")
            .document(user.email)
        
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
        
        let userRef = FirebaseManager.shared.firestore
            .collection("users")
            .document(user.email)
        
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
    
    func removeEventListener() {
        eventListener?.remove()
    }

}
