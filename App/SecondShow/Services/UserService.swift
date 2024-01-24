//
//  UserService.swift
//  SecondShow
//
//  Created by Alan on 11/27/23.
//

import Foundation
import Firebase


protocol UserServiceProtocol {
    
    func uploadUser(uid: String, username: String, email: String, createTime: Date , completion: @escaping((String?) -> Void))
    
    func createUser(username: String, email: String, password: String, createTime: Date, sendEmailVerification: Bool, completion: @escaping((FirebaseAuth.User?, String?) -> Void))
    
    func getUser(email: String, completion: @escaping((User?, String?) -> Void))
    
    func loginUser(email: String, password: String, emailVerificationRequired: Bool, completion: @escaping((String?) -> Void))
    
    func logoutUser()
    
//    func verifyLoginStatus(completion: @escaping((Bool) -> Void))
    
    func attachUserListener(completion: @escaping((User?, String?) -> Void))
    
    func removeUserListener()
    
    func submitFeedback(feedback: String, completion: @escaping ((String?) -> Void))
    
    func updateFcmToken(fcmToken: String, completion: @escaping ((String?) -> Void))
    
    func removeFcmToken(completion: @escaping ((String?) -> Void))
    
    func removeUserData(completion: @escaping((String?) -> Void))
}

class UserService: UserServiceProtocol {
    
    private var userListener: ListenerRegistration?
    
    func removeUserData(completion: @escaping ((String?) -> Void)) {
        guard let email = FirebaseManager.shared.auth.currentUser?.email else {
            completion("Error deleting account: User not logged in")
            return
        }
        FirebaseManager.shared.firestore
            .collection("users")
            .document(email)
            .delete() { err in
            if let err = err {
                completion("Error deleting account: \(err.localizedDescription)")
                return
            }
            completion(nil)
        }
    }
    
    func removeFcmToken(completion: @escaping ((String?) -> Void)) {
        guard let email = FirebaseManager.shared.auth.currentUser?.email else { return }
        FirebaseManager.shared.firestore
            .collection("users")
            .document(email)
            .updateData([FirebaseConstants.fcmToken: FieldValue.delete()]) { err in
                if let err = err {
                    completion("Error deleting fcm token: \(err.localizedDescription)")
                    return
                }
                completion(nil)
            }
    }
    
    func updateFcmToken(fcmToken: String, completion: @escaping ((String?) -> Void)) {
        guard let email = FirebaseManager.shared.auth.currentUser?.email else { return }
        
        FirebaseManager.shared.firestore
            .collection("users")
            .document(email)
            .updateData([FirebaseConstants.fcmToken: fcmToken]) { err in
                if let err = err {
                    completion("Error updating fcm token: \(err.localizedDescription)")
                    return
                }
                completion(nil)
            }
    }

    
    func submitFeedback(feedback: String, completion: @escaping ((String?) -> Void)) {
        guard let email = FirebaseManager.shared.auth.currentUser?.email else {
            completion("Error submitting feedback: User not logged in")
            return
        }
        
        let feedbackData = [
            FirebaseConstants.email: email,
            FirebaseConstants.feedback: feedback,
        ]
        
        FirebaseManager.shared.firestore.collection(FirebaseConstants.feedback)
            .addDocument(data: feedbackData) { err in
                if let err = err {
                    completion("Error submitting feedback: \(err.localizedDescription)")
                    return
                }
                completion(nil)
            }
    }

    
    func createUser(username: String, email: String, password: String, createTime: Date, sendEmailVerification: Bool, completion: @escaping((FirebaseAuth.User?, String?) -> Void)) {
        
        FirebaseManager.shared.firestore
            .collection("usernames")
            .document(username)
            .getDocument {doc, err in
                if let doc = doc, doc.exists {
                    completion(nil, "Username is already taken")
                    return
                }
                
                FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
                    if let err = err  {
                        completion(nil, "Error creating user: \(err.localizedDescription)")
                        return
                    }
                    
                    guard let currentUser = FirebaseManager.shared.auth.currentUser else {
                        completion(nil, "Error creating user: User not saved locally")
                        return
                    }
                    
                    
                    self.uploadUser(uid: currentUser.uid, username: username, email: email, createTime: createTime) { err in
                        if let err = err {
                            completion(nil, err)
                            return
                        }
                        
                        // send verification email
                        currentUser.sendEmailVerification() { err in
                            if let err = err {
                                completion(nil, "Error sending email verification: \(err.localizedDescription)")
                                return
                            }
                            completion(currentUser, nil)
                        }
                    }
                }
                
            }
    }
    
    func uploadUser(uid: String, username: String, email: String, createTime: Date , completion: @escaping((String?) -> Void)) {
        
        let userData = [
            FirebaseConstants.uid: uid,
            FirebaseConstants.username: username,
            FirebaseConstants.email: email,
            FirebaseConstants.createTime: createTime,
        ] as [String: Any]
        
        let group = DispatchGroup()
        
        group.enter()
        FirebaseManager.shared.firestore
            .collection("usernames")
            .document(username)
            .setData([
                "username": username,
            ]) { err in
                if let err = err {
                    completion("Error uploading username: \(err.localizedDescription)")
                    return
                }
                group.leave()
            }
        
        group.enter()
        FirebaseManager.shared.firestore.collection("users")
            .document(email)
            .setData(userData) {err in
                if let err = err {
                    completion("Error uploading user info: \(err.localizedDescription)")
                    return
                }
                group.leave()
            }
        
        group.notify(queue: .main) {
            completion(nil)
        }
    }
    
    func getUser(email: String, completion: @escaping((User?, String?) -> Void)) {
        FirebaseManager.shared.firestore.collection("users").document(email).getDocument { document, err in
            if let err = err {
                completion(nil, "Error retrieving user: \(err.localizedDescription)")
                return
            }
            
            if let currentUser = try? document?.data(as: User.self) {
                completion(currentUser, nil)
            } else {
                completion(nil, "Error codifying user data")
            }
        }
    }
    
    func loginUser(email: String, password: String, emailVerificationRequired: Bool, completion: @escaping((String?) -> Void)) {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {result, err in
            if let err = err as NSError? {
                if err.domain == "FIRAuthErrorDomain", err.code == 17999 {
                    completion("Incorrect email or password")
                } else {
                    completion("Error logging in: \(err.localizedDescription)")
                }
                return
            }
            
            // Check for email verification
            if emailVerificationRequired, FirebaseManager.shared.auth.currentUser?.isEmailVerified != true {
                self.logoutUser()
                completion("Please verify your email")
                return
            }
            
            // Retrieve user data from firestore and update FirebaseManager
            self.getUser(email: email) { currentUser, err in
                if let err = err {
                    self.logoutUser()
                    completion(err)
                    return
                }
                FirebaseManager.shared.currentUser = currentUser
                completion(nil)
            }
        }
    }
    
    func logoutUser() {
        try? FirebaseManager.shared.auth.signOut()
    }
    
    func attachUserListener(completion: @escaping((User?, String?) -> Void)) {
        guard let email = FirebaseManager.shared.auth.currentUser?.email else {return}
        
        removeUserListener()
        FirebaseManager.shared.firestore.collection("users").document(email).addSnapshotListener{ snapshot, err in
            if let err = err {
                completion(nil, "Snapshot error: \(err.localizedDescription)")
                return
            }
            
            if let updatedUser = try? snapshot?.data(as: User.self) {
                completion(updatedUser, nil)
            } else {
                completion(nil, "Error codifying user snapshot")
            }
        }
    }
    
    func removeUserListener() {
        userListener?.remove()
    }
}
