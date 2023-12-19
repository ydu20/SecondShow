//
//  RecentMessageService.swift
//  SecondShow
//
//  Created by Alan on 11/27/23.
//

import Foundation

protocol RecentMessageServiceProtocol {
    func updateRmsOnSoldoutOrDelete(userEmail: String, listingId: String, deleted: Bool, completion: @escaping((String?) -> ()))
}

class RecentMessageService: RecentMessageServiceProtocol {
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
                
//                for document in querySnapshot!.documents {
//                    guard let counterpartyEmail = document.get(MessageConstants.counterpartyEmail) as? String else {
//                        completion("Failure retrieving counterpartyEmail")
//                        return
//                    }
//                    let recentMsgId = document.documentID
//                    let updateData = deleted ? [MessageConstants.deleted: true] : [MessageConstants.sold: true]
//
//                    msgCollectionRef.document(recentMsgId).updateData(updateData) { err in
//                        if let err = err {
//                            completion("Failure updating seller's recentMessage: \(err.localizedDescription)")
//                            return
//                        }
//                    }
//
//                    FirebaseManager.shared.firestore
//                        .collection("recent_messages")
//                        .document(counterpartyEmail)
//                        .collection("messages")
//                        .document(listingId + "<->" + userEmail)
//                        .updateData(updateData) { err in
//                            if let err = err {
//                                completion("Failure updating buyer's recentMessage: \(err.localizedDescription)")
//                                return
//                            }
//                        }
//                }
//                completion(nil)
            }
        
    }
}
