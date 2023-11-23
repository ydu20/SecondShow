//
//  MainMessagesViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/22/23.
//

import Foundation
import Firebase

class MainMessagesViewModel: ObservableObject {
    
    @Published var recentMessages = [RecentMessage]()
    
    var recentMessagesListener: ListenerRegistration?
    
    var chatVm: ChatViewModel?
    
    init() {
        fetchRecentMessages()
    }
    
    func fetchRecentMessages() {
        guard let userEmail = FirebaseManager.shared.currentUser?.email else {return}
        
        self.recentMessagesListener?.remove()
        self.recentMessages.removeAll()
        
        print("Fetching recent messages...")
        
        recentMessagesListener = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(userEmail)
            .collection(MessageConstants.messages)
            .order(by: MessageConstants.timestamp)
            .addSnapshotListener { [self] querySnapshot, err in
                if let err = err {
                    print("Error fetching recent messages: \(err.localizedDescription)")
                    return
                }
                
                querySnapshot?.documentChanges.forEach({change in
                    guard let recentMessage = try? change.document.data(as: RecentMessage.self) else {
                        print("Failure codifying RecentMessage object")
                        return
                    }
                    
                    if let ind = self.recentMessages.firstIndex(where: {$0.id == recentMessage.id}) {
                        self.recentMessages.remove(at: ind)
                    }
                    
                    self.recentMessages.insert(recentMessage, at: 0)
                    
                    if recentMessage.listingId == self.chatVm?.listingId, recentMessage.counterpartyEmail == self.chatVm?.counterpartyEmail {
                        self.chatVm?.updateWithRecentMessage(rm: recentMessage)
                    }
                })
            }
    }
    
}
