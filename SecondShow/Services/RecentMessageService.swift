//
//  RecentMessageService.swift
//  SecondShow
//
//  Created by Alan on 11/27/23.
//

import Foundation
import Firebase
import FirebaseFirestore

protocol RecentMessageServiceProtocol {
    
    func fetchRecentMessages(completion: @escaping(([DocumentChange]?, String?) -> ()))
    
    func updateRmsOnSoldoutOrDelete(userEmail: String, listingId: String, deleted: Bool, completion: @escaping((String?) -> ()))
    
    func removeRecentMessagesListener()
}

class RecentMessageService: RecentMessageServiceProtocol {
    
    private var recentMessagesListener: ListenerRegistration?
    
    func fetchRecentMessages(completion: @escaping(([DocumentChange]?, String?) -> ())) {
        guard let userEmail = FirebaseManager.shared.currentUser?.email else {return}
        
        removeRecentMessagesListener()
        
        recentMessagesListener = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(userEmail)
            .collection(MessageConstants.messages)
            .order(by: MessageConstants.timestamp)
            .addSnapshotListener { querySnapshot, err in
                if let err = err {
                    completion(nil, "Error fetching recent messages: \(err.localizedDescription)")
                    return
                }
                
                completion(querySnapshot?.documentChanges, nil)
                
            }
        
    }
    
    func removeRecentMessagesListener() {
        self.recentMessagesListener?.remove()
    }

    
    func updateRmsOnSoldoutOrDelete(userEmail: String, listingId: String, deleted: Bool, completion: @escaping((String?) -> ())) {
        
        let msgCollectionRef = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(userEmail)
            .collection("messages")
        
        msgCollectionRef
            .whereField(ListingConstants.listingId, isEqualTo: listingId)
            .getDocuments { querySnapshot, err in
                if let err = err {
                    completion("Error retrieving recent messages: \(err.localizedDescription)")
                    return
                }
                
                let group = DispatchGroup()

                for document in querySnapshot!.documents {
                    guard let counterpartyEmail = document.get(MessageConstants.counterpartyEmail) as? String else {
                        completion("Failure retrieving counterpartyEmail")
                        return
                    }
                    let recentMsgId = document.documentID
                    let updateData = deleted ? [MessageConstants.deleted: true] : [MessageConstants.sold: true]
                    
                    group.enter()
                    msgCollectionRef.document(recentMsgId).updateData(updateData) { err in
                        if let err = err {
                            completion("Failure updating seller's recentMessage: \(err.localizedDescription)")
                            return
                        }
                        group.leave()
                    }
                    
                    group.enter()
                    FirebaseManager.shared.firestore
                        .collection("recent_messages")
                        .document(counterpartyEmail)
                        .collection("messages")
                        .document(listingId + "<->" + userEmail)
                        .updateData(updateData) { err in
                            if let err = err {
                                completion("Failure updating buyer's recentMessage: \(err.localizedDescription)")
                                return
                            }
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    completion(nil)
                }
            }
    }
}
