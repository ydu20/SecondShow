//
//  UserService.swift
//  SecondShow
//
//  Created by Alan on 11/27/23.
//

import Foundation
import Firebase


protocol UserServiceProtocol {
    
    func uploadUser(uid: String, email: String, createTime: Date , completion: @escaping((String?) -> Void))
    
    func createUser(email: String, password: String, createTime: Date, sendEmailVerification: Bool, completion: @escaping((FirebaseAuth.User?, String?) -> Void))

    func getUser(email: String, completion: @escaping((User?, String?) -> Void))
    
    func loginUser(email: String, password: String, emailVerificationRequired: Bool, completion: @escaping((String?) -> Void))
    
    func logoutUser()
    
    func verifyLoginStatus(completion: @escaping((Bool) -> Void))
    
    func attachUserListener(completion: @escaping((User?, String?) -> Void))
    
    func removeUserListener()
}

class UserService: UserServiceProtocol {
    
    private var userListener: ListenerRegistration?
    
    func createUser(email: String, password: String, createTime: Date, sendEmailVerification: Bool, completion: @escaping((FirebaseAuth.User?, String?) -> Void)) {
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err  {
                completion(nil, "Error creating user: \(err.localizedDescription)")
                return
            }
            
            guard let currentUser = FirebaseManager.shared.auth.currentUser else {
                completion(nil, "Error creating user: User not saved locally")
                return
            }
            
            
            self.uploadUser(uid: currentUser.uid, email: email, createTime: createTime) { err in
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
    
    func uploadUser(uid: String, email: String, createTime: Date , completion: @escaping((String?) -> Void)) {
        
        let userData = [
            FirebaseConstants.uid: uid,
            FirebaseConstants.email: email,
            FirebaseConstants.createTime: createTime,
        ] as [String: Any]
        
        FirebaseManager.shared.firestore.collection("users")
            .document(email)
            .setData(userData) {err in
                if let err = err {
                    completion("Error uploading user info: \(err.localizedDescription)")
                    return
                }
                
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
    
    func verifyLoginStatus(completion: @escaping((Bool) -> Void)) {
        guard let authCurrUserEmail = FirebaseManager.shared.auth.currentUser?.email else {
            completion(false)
            return
        }
        
        if (FirebaseManager.shared.currentUser == nil) {
            self.getUser(email: authCurrUserEmail) { currUser, err in
                if let err = err {
                    print(err)
                    self.logoutUser()
                    completion(false)
                    return
                }
                FirebaseManager.shared.currentUser = currUser
                completion(true)
            }
        } else {
            completion(true)
        }
    }
    
    func attachUserListener(completion: @escaping((User?, String?) -> Void)) {
        guard let currentUser = FirebaseManager.shared.currentUser else {return}
        
        removeUserListener()
        FirebaseManager.shared.firestore.collection("users").document(currentUser.email).addSnapshotListener{ snapshot, err in
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
