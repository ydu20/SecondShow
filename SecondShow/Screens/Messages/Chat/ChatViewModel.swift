//
//  ChatViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/21/23.
//

import Foundation

class ChatViewModel: ObservableObject {
    
    @Published var inputText = ""
    @Published var chatMessages = [ChatMessage]()
    
    
//    private var counterParty: User?
//    private var event: Event?
//    private var listing: Listing?
    private var listingId, eventName, toId: String?
    private var listingNumber: Int?
    
//    // This initializer should only be called from the Tickets page
//    init(listing: Listing?) {
//        guard let listing = listing else {return}
//        guard let listingId = listing.id else {return}
//
//        self.listingId = listingId
//        self.eventName = listing.eventName
//        self.listingNumber = listing.listingNumber
//        self.counterPartyUid = listing.creator
//
//        fetchMessages()
//    }
//
//    // This initializer should only be called from the Messages page
//    init(eventId: String, listingNumber: String, counterPartyUid: String) {
//
//    }
    
    // This should only be called from the Tickets page
    func updateWithListing(listing: Listing) {
        guard let listingId = listing.id else {return}
        
        self.listingId = listingId
        self.eventName = listing.eventName
        self.listingNumber = listing.listingNumber
        self.toId = listing.creator
        
        fetchMessages()
    }
    
    // This should only be called from the Messages page
    func updateWithRecentMessage(rm: RecentMessage) {
        self.listingId = rm.listingId
        self.eventName = rm.eventName
        self.listingNumber = rm.listingNumber
        self.toId = rm.counterPartyUid
        
        fetchMessages()
    }
    
    func fetchMessages() {
        
    }
    
    func handleSend() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = self.toId else {return}
        guard let listingId = self.listingId else {return}
        let timestamp = Date()
        
        
        let msgData = [
            MessageConstants.listingId: listingId,
            MessageConstants.fromId: fromId,
            MessageConstants.toId: toId,
            MessageConstants.message: inputText,
            MessageConstants.timestamp: timestamp
        ] as [String: Any]
        
        let outgoingDoc = FirebaseManager.shared.firestore
            .collection(MessageConstants.messages)
            .document(fromId)
            .collection(ListingConstants.listings)
            .document(listingId)
            .collection(toId)
            .document()
        
        outgoingDoc.setData(msgData) { err in
            if let err = err {
                print("Error saving outgoing message: \(err.localizedDescription)")
                return
            }
            // TODO
        }
        
        
        let incomingDoc = FirebaseManager.shared.firestore
            .collection(MessageConstants.messages)
            .document(toId)
            .collection(ListingConstants.listings)
            .document(listingId)
            .collection(fromId)
            .document()
        
        incomingDoc.setData(msgData) { err in
            if let err = err {
                print("Error saving incoming message: \(err.localizedDescription)")
                return
            }
            // TODO
            
        }
    }
    
    private func persistRecentMessage(timestamp: Date) {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = self.toId else {return}
        guard let listingId = self.listingId else {return}
        guard let eventName = self.eventName else {return}
        guard let listingNumber = self.listingNumber else {return}
        
        let senderRecentMessages = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(fromId)
            .collection(MessageConstants.messages)
            .document(listingId + "<->" + toId)
        
        let senderRmData = [
            MessageConstants.listingId: listingId,
            ListingConstants.eventName: eventName,
            MessageConstants.counterPartyUid: toId,
            ListingConstants.listingNumber: listingNumber,
            MessageConstants.timestamp: timestamp
        ] as [String: Any]
        
        senderRecentMessages.setData(senderRmData) { err in
            if let err = err {
                print("Error saving sender's recent message: \(err.localizedDescription)")
                return
            }
        }
        
        let recipientRecentMessages = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(toId)
            .collection(MessageConstants.messages)
            .document(listingId + "<->" + fromId)
        
        let recipientRmData = [
            MessageConstants.listingId: listingId,
            ListingConstants.eventName: eventName,
            MessageConstants.counterPartyUid: fromId,
            ListingConstants.listingNumber: listingNumber,
            MessageConstants.timestamp: timestamp
        ] as [String: Any]
        
        recipientRecentMessages.setData(recipientRmData) { err in
            if let err = err {
                print("Error saving recipient's recent message: \(err.localizedDescription)")
                return
            }
        }
        
    }
}
