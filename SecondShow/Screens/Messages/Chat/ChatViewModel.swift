//
//  ChatViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/21/23.
//

import Foundation
import Firebase

class ChatViewModel: ObservableObject {
    
    @Published var inputText = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var autoScrollCount = 0
    @Published var sold = false
    @Published var deleted = false
    
    private var listingId, eventName, toId: String?
    private var listingNumber: Int?
    
    var messagesListener: ListenerRegistration?
    
    var titleText: String {
        guard let eventName = eventName else {
            return ""
        }
        guard let listingNumber = listingNumber else {
            return ""
        }
        return "\(eventName) #\(listingNumber)"
    }
    
    // This should only be called from the Tickets page
    func updateWithListing(listing: Listing) {
        guard let listingId = listing.id else {return}
        
        self.listingId = listingId
        self.eventName = listing.eventName
        self.listingNumber = listing.listingNumber
        self.toId = listing.creator
        self.sold = false
        self.deleted = false
        
        self.inputText = ""
    }
    
    // This should only be called from the Messages page
    func updateWithRecentMessage(rm: RecentMessage) {
        self.listingId = rm.listingId
        self.eventName = rm.eventName
        self.listingNumber = rm.listingNumber
        self.toId = rm.counterpartyUid
        self.sold = rm.sold
        self.deleted = rm.deleted
        
        self.inputText = ""
    }
    
    func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = self.toId else {return}
        guard let listingId = self.listingId else {return}
        
        messagesListener?.remove()
        chatMessages.removeAll()
                
        messagesListener = FirebaseManager.shared.firestore
            .collection(MessageConstants.messages)
            .document(fromId)
            .collection(ListingConstants.listings)
            .document(listingId)
            .collection(toId)
            .order(by: MessageConstants.timestamp)
            .addSnapshotListener { querySnapshot, err in
                if let err = err {
                    print("Error listening for messages: \(err.localizedDescription)")
                    print(err)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({change in
                    if change.type == .added {
                        guard let message = try? change.document.data(as: ChatMessage.self) else {
                            print("Failure codifying ChatMessage object")
                            return
                        }
                        self.chatMessages.append(message)
                    }
                })
                
                DispatchQueue.main.async {
                    self.autoScrollCount += 1
                }
            }
    }
    
    func handleSend() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = self.toId else {return}
        guard let listingId = self.listingId else {return}
        let timestamp = Date()
        
//        print("Handling send...")
        
        let msgData = [
            ListingConstants.listingId: listingId,
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
            
            self.persistRecentMessage(timestamp: timestamp)
            print("Sender message saved")
            self.inputText = ""
            self.autoScrollCount += 1
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
            print("Recipient message saved")
        }
    }
    
    private func persistRecentMessage(timestamp: Date) {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = self.toId else {return}
        guard let listingId = self.listingId else {return}
        guard let eventName = self.eventName else {return}
        guard let listingNumber = self.listingNumber else {return}
        
//        print("Persisting recent message...")
        
        let senderRecentMessages = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(fromId)
            .collection(MessageConstants.messages)
            .document(listingId + "<->" + toId)
        
        let senderRmData = [
            ListingConstants.listingId: listingId,
            ListingConstants.eventName: eventName,
            MessageConstants.counterpartyUid: toId,
            ListingConstants.listingNumber: listingNumber,
            MessageConstants.timestamp: timestamp,
            MessageConstants.message: inputText,
            MessageConstants.sold: sold,
            MessageConstants.deleted: deleted
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
            ListingConstants.listingId: listingId,
            ListingConstants.eventName: eventName,
            MessageConstants.counterpartyUid: fromId,
            ListingConstants.listingNumber: listingNumber,
            MessageConstants.timestamp: timestamp,
            MessageConstants.message: inputText,
            MessageConstants.sold: sold,
            MessageConstants.deleted: deleted
        ] as [String: Any]
        
        recipientRecentMessages.setData(recipientRmData) { err in
            if let err = err {
                print("Error saving recipient's recent message: \(err.localizedDescription)")
                return
            }
        }
    }
}
