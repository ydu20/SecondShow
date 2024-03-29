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
    
    func fetchEventsForAlerts(completion: @escaping(([DocumentChange]?, String?) -> ()))
    
    func addEventAlert(eventId: String, completion: @escaping((String?) -> ()))
    
    func removeEventAlert(eventId: String, completion: @escaping((String?) -> ()))
    
    func removeEventListener()
    
    func removeEventListenerForAlerts()
    
    func decreaseEventListingCount(eventId: String, completion: @escaping((String?) -> ()))
}

class EventService: EventServiceProtocol {
    
    private var eventListener: ListenerRegistration?
    private var eventListenerForAlerts: ListenerRegistration?
    
    func decreaseEventListingCount(eventId: String, completion: @escaping ((String?) -> ())) {
        let update = [
            EventConstants.listingCount: FieldValue.increment(Int64(-1))
        ]
        
        FirebaseManager.shared.firestore
            .collection("events")
            .document(eventId)
            .updateData(update) { err in
                if let err = err {
                    completion("Error updating event: \(err.localizedDescription)")
                    return
                }
                completion(nil)
            }
    }
    
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        eventListener = FirebaseManager.shared.firestore
            .collection("events")
            .whereField(EventConstants.date, isGreaterThanOrEqualTo: dateFormatter.string(from: Date()))
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    completion(nil, error.localizedDescription)
                    return
                }
                completion(querySnapshot?.documentChanges, nil)
            }
    }
    
    func fetchEventsForAlerts(completion: @escaping(([DocumentChange]?, String?) -> ())) {
        removeEventListenerForAlerts()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        eventListenerForAlerts = FirebaseManager.shared.firestore
            .collection("events")
            .whereField(EventConstants.date, isGreaterThanOrEqualTo: dateFormatter.string(from: Date()))
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    completion(nil, error.localizedDescription)
                    return
                }
                completion(querySnapshot?.documentChanges, nil)
            }
    }
    
    func removeEventListenerForAlerts() {
        eventListenerForAlerts?.remove()
    }
    
    func addEventAlert(eventId: String, completion: @escaping((String?) -> ())) {
        guard let user = FirebaseManager.shared.currentUser else {return}
        
        let group = DispatchGroup()
        
        group.enter()
        FirebaseManager.shared.firestore
            .collection("users")
            .document(user.email)
            .updateData([
                FirebaseConstants.alerts: FieldValue.arrayUnion([eventId])
            ]) {err in
                if let err = err {
                    completion(err.localizedDescription)
                    return
                }
                group.leave()
            }
        
        let subscriberData = [
            "subscribed": true
        ]
        
        group.enter()
        FirebaseManager.shared.firestore
            .collection("events")
            .document(eventId)
            .collection("subscribers")
            .document(user.email)
            .setData(subscriberData) { err in
                if let err = err {
                    completion(err.localizedDescription)
                    return
                }
                group.leave()
            }
        
        group.notify(queue: .main) {
            completion(nil)
        }
    }
    
    func removeEventAlert(eventId: String, completion: @escaping((String?) -> ())) {
        guard let user = FirebaseManager.shared.currentUser else {return}
        
        let group = DispatchGroup()
        
        group.enter()
        FirebaseManager.shared.firestore
            .collection("users")
            .document(user.email)
            .updateData([
                FirebaseConstants.alerts: FieldValue.arrayRemove([eventId])
            ]) {err in
                if let err = err {
                    completion(err.localizedDescription)
                    return
                }
                group.leave()
            }
        
        group.enter()
        FirebaseManager.shared.firestore
            .collection("events")
            .document(eventId)
            .collection("subscribers")
            .document(user.email)
            .delete() { err in
                if let err = err {
                    completion(err.localizedDescription)
                    return
                }
                group.leave()
            }
        
        group.notify(queue: .main) {
            completion(nil)
        }
    }
    
    func removeEventListener() {
        eventListener?.remove()
    }

}
