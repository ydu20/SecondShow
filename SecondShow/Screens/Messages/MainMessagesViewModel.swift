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
    
    init() {
        fetchRecentMessages()
    }
    
    func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        
        self.recentMessagesListener?.remove()
        self.recentMessages.removeAll()
        
        print("Fetching recent messages...")
        
        recentMessagesListener = FirebaseManager.shared.firestore
            .collection(MessageConstants.recentMessages)
            .document(uid)
            .collection(MessageConstants.messages)
            .order(by: MessageConstants.timestamp)
            .addSnapshotListener { querySnapshot, err in
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
                })
            }
    }
    
}
