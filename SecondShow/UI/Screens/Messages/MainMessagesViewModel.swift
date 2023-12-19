//
//  MainMessagesViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/22/23.
//

import Foundation
import SwiftUI

class MainMessagesViewModel: ObservableObject {
    
    @Published var recentMessages = [RecentMessage]()
        
    let chatVm: ChatViewModel
    let messageService: MessageService
    let notifyUser: (String, Color) -> ()
    
    init(chatVm: ChatViewModel, messageService: MessageService, notifyUser: @escaping (String, Color) -> Void) {
        
        self.chatVm = chatVm
        self.messageService = messageService
        self.notifyUser = notifyUser
        
        fetchRecentMessages()
    }
    
    func removeListener() {
        messageService.removeRecentMessagesListener()
    }
    
    func fetchRecentMessages() {
        self.recentMessages.removeAll()
        
        print("Fetching recent messages...")
        
        messageService.fetchRecentMessages { documentChanges, err in
            if let err = err {
                self.notifyUser(err, Color(.systemRed))
                return
            }
            
            documentChanges?.forEach({change in
                guard let recentMessage = try? change.document.data(as: RecentMessage.self) else {
                    print("Failure codifying RecentMessage object")
                    return
                }
                
                if let ind = self.recentMessages.firstIndex(where: {$0.id == recentMessage.id}) {
                    self.recentMessages.remove(at: ind)
                }
                
                self.recentMessages.insert(recentMessage, at: 0)
                
                if recentMessage.listingId == self.chatVm.listingId, recentMessage.counterpartyEmail == self.chatVm.counterpartyEmail {
                    self.chatVm.updateWithRecentMessage(rm: recentMessage)
                }
            })
        }
    }
    
}
