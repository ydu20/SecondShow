//
//  MessageService.swift
//  SecondShow
//
//  Created by Alan on 11/27/23.
//

import Foundation
import FirebaseFirestore

protocol MessageServiceProtocol {
    
    func fetchRecentMessages(completion: @escaping(([DocumentChange]?, String?) -> ()))
    
    func updateRmsOnSoldoutOrDelete(userEmail: String, listingId: String, deleted: Bool, completion: @escaping((String?) -> ()))
    
    func removeRecentMessagesListener()
    
    func fetchChatMessages(counterPartyEmail: String, listingId: String, completion: @escaping(([DocumentChange]?, String?) -> ()))
    
    func sendMessage(toEmail: String, listingId: String, message: String, timestamp: Date, completion: @escaping((String?) -> ()))
    
    func persistRecentMessage(toUsername: String, toEmail: String, listingId: String, eventName: String, listingNumber: Int, price: Int, message: String, timestamp: Date, completion: @escaping((String?) -> ()))
    
    func updateReadStatus(counterPartyEmail: String, listingId: String, completion: @escaping((String?) -> ()))
    
    func removeChatMessagesListener()
    
}

class MessageService: MessageServiceProtocol {
    
    private var recentMessagesListener: ListenerRegistration?
    private var chatMessagesListener: ListenerRegistration?
    
    func updateReadStatus(counterPartyEmail: String, listingId: String, completion: @escaping((String?) -> ())) {
        guard let userEmail = FirebaseManager.shared.currentUser?.email else {return}
        
        let updateData = [
            MessageConstants.read: true
        ]
        
        FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(userEmail)
            .collection(MessageConstants.userRecentMessages)
            .document(listingId + "<->" + counterPartyEmail)
            .updateData(updateData) { err in
                if let err = err {
                    completion(err.localizedDescription)
                    return
                }
                completion(nil)
            }
    }
    
    func persistRecentMessage(toUsername: String, toEmail: String, listingId: String, eventName: String, listingNumber: Int, price: Int, message: String, timestamp: Date, completion: @escaping((String?) -> ())) {
        
        guard let fromUsername = FirebaseManager.shared.currentUser?.username else {return}
        guard let fromEmail = FirebaseManager.shared.currentUser?.email else {return}
        
        let group = DispatchGroup()
        
        let senderRmData = [
            ListingConstants.listingId: listingId,
            ListingConstants.eventName: eventName,
            MessageConstants.counterpartyUsername: toUsername,
            MessageConstants.counterpartyEmail: toEmail,
            ListingConstants.listingNumber: listingNumber,
            MessageConstants.timestamp: timestamp,
            MessageConstants.message: message.replacingOccurrences(of: "\n", with: "").prefix(30),
            MessageConstants.read: true,
            MessageConstants.sold: false,
            MessageConstants.deleted: false,
            MessageConstants.expired: false,
            ListingConstants.price: price,
        ] as [String: Any]
        
        let senderRmRef = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(fromEmail)
            .collection(MessageConstants.userRecentMessages)
            .document(listingId + "<->" + toEmail)
        
        group.enter()
        senderRmRef.setData(senderRmData) {err in
            if let err = err {
                completion("Error saving sender's recent message: \(err.localizedDescription)")
                return
            }
            group.leave()
        }
        
        let recipientRmData = [
            ListingConstants.listingId: listingId,
            ListingConstants.eventName: eventName,
            MessageConstants.counterpartyUsername: fromUsername,
            MessageConstants.counterpartyEmail: fromEmail,
            ListingConstants.listingNumber: listingNumber,
            MessageConstants.timestamp: timestamp,
            MessageConstants.message: message.replacingOccurrences(of: "\n", with: "").prefix(30),
            MessageConstants.read: false,
            MessageConstants.sold: false,
            MessageConstants.deleted: false,
            MessageConstants.expired: false,
            ListingConstants.price: price,
        ] as [String: Any]
        
        let recipientRmRef = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(toEmail)
            .collection(MessageConstants.userRecentMessages)
            .document(listingId + "<->" + fromEmail)
        
        group.enter()
        recipientRmRef.setData(recipientRmData) { err in
            if let err = err {
                completion("Error saving recipient's recent message: \(err.localizedDescription)")
                return
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(nil)
        }
    }

    
    func sendMessage(toEmail: String, listingId: String, message: String, timestamp: Date, completion: @escaping((String?) -> ())) {
        
        guard let fromEmail = FirebaseManager.shared.currentUser?.email else {return}
        
        let msgData = [
            ListingConstants.listingId: listingId,
            MessageConstants.fromEmail: fromEmail,
            MessageConstants.toEmail: toEmail,
            MessageConstants.message: message,
            MessageConstants.timestamp: timestamp
        ] as [String : Any]
        
        let group = DispatchGroup()
        
        let outgoingDocRef = FirebaseManager.shared.firestore
            .collection(MessageConstants.messages)
            .document(fromEmail)
            .collection(ListingConstants.listings)
            .document(listingId)
            .collection(toEmail)
            .document()
        
        group.enter()
        outgoingDocRef.setData(msgData) { err in
            if let err = err {
                completion("Error saving msg for sender: \(err.localizedDescription)")
                return
            }
            group.leave()
        }
        
        let incomingDocRef = FirebaseManager.shared.firestore
            .collection(MessageConstants.messages)
            .document(toEmail)
            .collection(ListingConstants.listings)
            .document(listingId)
            .collection(fromEmail)
            .document()
        
        group.enter()
        incomingDocRef.setData(msgData) { err in
            if let err = err {
                completion("Error saving msg for recipient: \(err.localizedDescription)")
                return
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(nil)
        }
    }

    
    func fetchChatMessages(counterPartyEmail: String, listingId: String, completion: @escaping(([DocumentChange]?, String?) -> ())) {
        
        guard let userEmail = FirebaseManager.shared.currentUser?.email else {return}
        
        removeChatMessagesListener()
        
        chatMessagesListener = FirebaseManager.shared.firestore
            .collection("messages")
            .document(userEmail)
            .collection("listings")
            .document(listingId)
            .collection(counterPartyEmail)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, err in
                if let err = err {
                    completion(nil, "Error listening for messages: \(err.localizedDescription)")
                    return
                }
                completion(querySnapshot?.documentChanges, nil)
            }
    }
    
    func removeChatMessagesListener() {
        self.chatMessagesListener?.remove()
    }
    
    func fetchRecentMessages(completion: @escaping(([DocumentChange]?, String?) -> ())) {
        guard let userEmail = FirebaseManager.shared.currentUser?.email else {return}
        
        removeRecentMessagesListener()
        
        recentMessagesListener = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(userEmail)
            .collection(MessageConstants.userRecentMessages)
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
                    var updateData = deleted ? [MessageConstants.deleted: true] : [MessageConstants.sold: true]
                    updateData[MessageConstants.read] = true

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
