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
    
    var listingId, eventName, counterpartyEmail: String?
    var listingNumber, price: Int?
    
    var messagesListener: ListenerRegistration?
    
    var titleText: String {
        return String(counterpartyEmail?.split(separator: "@").first ?? "")
    }
    
    // This should only be called from the Tickets page
    func updateWithListing(listing: Listing) {
        guard let listingId = listing.id else {return}
        
        self.listingId = listingId
        self.eventName = listing.eventName
        self.listingNumber = listing.listingNumber
        self.counterpartyEmail = listing.creator
        self.sold = false
        self.deleted = false
        self.price = listing.price
    }
    
    // This should only be called from the Messages page
    func updateWithRecentMessage(rm: RecentMessage) {
        self.listingId = rm.listingId
        self.eventName = rm.eventName
        self.listingNumber = rm.listingNumber
        self.counterpartyEmail = rm.counterpartyEmail
        self.sold = rm.sold
        self.deleted = rm.deleted
        self.price = rm.price
    }
    
    func fetchMessages() {
        guard let fromEmail = FirebaseManager.shared.currentUser?.email else {return}
        guard let toEmail = self.counterpartyEmail else {return}
        guard let listingId = self.listingId else {return}
        
        messagesListener?.remove()
        chatMessages.removeAll()
                
        messagesListener = FirebaseManager.shared.firestore
            .collection(MessageConstants.messages)
            .document(fromEmail)
            .collection(ListingConstants.listings)
            .document(listingId)
            .collection(toEmail)
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
        guard let fromEmail = FirebaseManager.shared.currentUser?.email else {return}
        guard let toEmail = self.counterpartyEmail else {return}
        guard let listingId = self.listingId else {return}
        let timestamp = Date()
        
//        print("Handling send...")
        
        let msgData = [
            ListingConstants.listingId: listingId,
            MessageConstants.fromEmail: fromEmail,
            MessageConstants.toEmail: toEmail,
            MessageConstants.message: inputText,
            MessageConstants.timestamp: timestamp
        ] as [String: Any]
        
        let outgoingDoc = FirebaseManager.shared.firestore
            .collection(MessageConstants.messages)
            .document(fromEmail)
            .collection(ListingConstants.listings)
            .document(listingId)
            .collection(toEmail)
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
            .document(toEmail)
            .collection(ListingConstants.listings)
            .document(listingId)
            .collection(fromEmail)
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
        guard let fromEmail = FirebaseManager.shared.currentUser?.email else {return}
        guard let toEmail = self.counterpartyEmail else {return}
        guard let listingId = self.listingId else {return}
        guard let eventName = self.eventName else {return}
        guard let listingNumber = self.listingNumber else {return}
        guard let price = self.price else {return}

        
//        print("Persisting recent message...")
        
        let senderRecentMessages = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(fromEmail)
            .collection(MessageConstants.messages)
            .document(listingId + "<->" + toEmail)
        
        let senderRmData = [
            ListingConstants.listingId: listingId,
            ListingConstants.eventName: eventName,
            MessageConstants.counterpartyEmail: toEmail,
            ListingConstants.listingNumber: listingNumber,
            MessageConstants.timestamp: timestamp,
            MessageConstants.message: inputText.replacingOccurrences(of: "\n", with: "").prefix(30),
            MessageConstants.sold: sold,
            MessageConstants.deleted: deleted,
            ListingConstants.price: price,
        ] as [String: Any]
        
        senderRecentMessages.setData(senderRmData) { err in
            if let err = err {
                print("Error saving sender's recent message: \(err.localizedDescription)")
                return
            }
        }
        
        let recipientRecentMessages = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(toEmail)
            .collection(MessageConstants.messages)
            .document(listingId + "<->" + fromEmail)
        
        let recipientRmData = [
            ListingConstants.listingId: listingId,
            ListingConstants.eventName: eventName,
            MessageConstants.counterpartyEmail: fromEmail,
            ListingConstants.listingNumber: listingNumber,
            MessageConstants.timestamp: timestamp,
            MessageConstants.message: inputText,
            MessageConstants.sold: sold,
            MessageConstants.deleted: deleted,
            ListingConstants.price: price,
        ] as [String: Any]
        
        recipientRecentMessages.setData(recipientRmData) { err in
            if let err = err {
                print("Error saving recipient's recent message: \(err.localizedDescription)")
                return
            }
        }
    }
}
