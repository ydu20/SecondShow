//
//  ChatViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/21/23.
//

import Foundation
import Firebase
import SwiftUI

class ChatViewModel: ObservableObject {
    
    let listingService: ListingService
    let messageService: MessageService
    
    @Published var inputText = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var autoScrollCount = 0
    @Published var sold = false
    @Published var deleted = false
    @Published var expired = false
    
    private var enteredFromListing = false
    
    var listingId, eventName, counterpartyUsername, counterpartyEmail: String?
    var listingNumber, price: Int?
    
//    var messagesListener: ListenerRegistration?
    
    var titleText: String {
        return counterpartyUsername ?? ""
    }
    
    init(listingService: ListingService, messageService: MessageService) {
        self.listingService = listingService
        self.messageService = messageService
    }
    
    // This should only be called from the Tickets page
    func updateWithListing(listing: Listing) {
        guard let listingId = listing.id else {return}
        
        self.listingId = listingId
        self.eventName = listing.eventName
        self.listingNumber = listing.listingNumber
        self.counterpartyUsername = listing.creatorUsername
        self.counterpartyEmail = listing.creatorEmail
        self.sold = listing.availableQuantity == 0
        self.deleted = false
        self.expired = listing.expired
        self.price = listing.price
        self.enteredFromListing = true
    }
    
    // This should only be called from the Messages page
    func updateWithRecentMessage(rm: RecentMessage) {
        self.listingId = rm.listingId
        self.eventName = rm.eventName
        self.listingNumber = rm.listingNumber
        self.counterpartyUsername = rm.counterpartyUsername
        self.counterpartyEmail = rm.counterpartyEmail
        self.sold = rm.sold
        self.deleted = rm.deleted
        self.expired = rm.expired
        self.price = rm.price
        self.enteredFromListing = false
    }
    
    func removeListener() {
        messageService.removeChatMessagesListener()
    }
    
    func fetchMessages() {
        guard let counterPartyEmail = self.counterpartyEmail else {return}
        guard let listingId = self.listingId else {return}
        
        chatMessages.removeAll()
        
        messageService.fetchChatMessages(counterPartyEmail: counterPartyEmail, listingId: listingId) { documentChanges, err in
            if let err = err {
                print(err)
                return
            }
            
            documentChanges?.forEach({change in
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
        if inputText.count == 0 {
            return
        }
        
        guard let toEmail = self.counterpartyEmail else {return}
        guard let listingId = self.listingId else {return}
        let timestamp = Date()
        
        if (enteredFromListing && chatMessages.isEmpty) {
            listingService.increaseListingPopularity(creatorEmail: toEmail, listingId: listingId) { err in
                if let err = err {
                    print(err)
                    return
                }
            }
        }
        


        messageService.sendMessage(toEmail: toEmail, listingId: listingId, message: inputText, timestamp: timestamp) { err in
            if let err = err {
                print(err)
                return
            }
            
            self.persistRecentMessage(timestamp: timestamp)
            self.inputText = ""
            self.autoScrollCount += 1
        }
    }
    
    private func persistRecentMessage(timestamp: Date) {
        
        guard let toUsername = self.counterpartyUsername else {return}
        guard let toEmail = self.counterpartyEmail else {return}
        guard let listingId = self.listingId else {return}
        guard let eventName = self.eventName else {return}
        guard let listingNumber = self.listingNumber else {return}
        guard let price = self.price else {return}
        
        messageService.persistRecentMessage(
            toUsername: toUsername,
            toEmail: toEmail,
            listingId: listingId,
            eventName: eventName,
            listingNumber: listingNumber,
            price: price,
            message: inputText,
            timestamp: timestamp) { err in
            if let err = err {
                print(err)
                return
            }
        }
    }
}
