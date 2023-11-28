//
//  LoginViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/27/23.
//

import Foundation
import FirebaseAuth


class LoginViewModel: ObservableObject {

    @Published var showSignupView = false
    @Published var showSignupCompleteAlert = false
    
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var statusMessage = ""
    @Published var signupEmail = ""
    @Published var signupPassword = ""
    @Published var signupConfirmPassword = ""
    
    // Switch to true for production
    private var requireVerification = false
    
    func createAccount() {
        // Validation
        if (!signupEmail.hasSuffix("gmail.com")) {
            self.statusMessage = "Please sign up with an gmail address"
            return
        }
        if (signupPassword.count < 8) {
            self.statusMessage = "Password needs to be at least 8 characters"
            return
        }
        if (signupPassword != signupConfirmPassword) {
            self.statusMessage = "Passwords do not match"
            return
        }
        self.statusMessage = ""
        
        // Create user
        
        FirebaseManager.shared.auth.createUser(withEmail: signupEmail, password: signupPassword) { result, err in
            if let err = err {
                print("Failed to create user: ", err)
                self.statusMessage = "Failed to create user: \(err)"
                return
            }
            
            print("Successfully created user: \(self.signupEmail)")
            
            guard let currentUser = FirebaseManager.shared.auth.currentUser else {return}
            
            // Upload user to FireStore
            let userData = [FirebaseConstants.uid: currentUser.uid, FirebaseConstants.email: self.signupEmail, FirebaseConstants.createTime: Date()] as [String: Any]
            
            FirebaseManager.shared.firestore.collection("users")
                .document(self.signupEmail).setData(userData) { err in
                    if let err = err {
                        print(err)
                        self.statusMessage = "\(err)"
                        return
                    }

                    print("Uploaded to Firebase")

                    // Disabled for development
//                    currentUser.sendEmailVerification() { err in
//                        if let err = err {
//                            print(err)
//                            self.signupStatusMessage = "\(err)"
//                            return
//                        }
//                        print ("Email verification sent")
//                        didCompleteSignUp()
//                    }
                    
                    self.didCompleteSignUp()
                }
        }
    }
    
    private func didCompleteSignUp() {
        signupEmail = ""
        signupPassword = ""
        signupConfirmPassword = ""
        
        showSignupCompleteAlert.toggle()
    }
    
    
    func loginUser(onSuccess: @escaping () -> ()) {
            // Validation
            if (loginEmail.count < 5) {
                statusMessage = "Please enter a valid email"
                return
            }
            if (loginPassword.count == 0) {
                statusMessage = "Please enter a password"
                return
            }
            statusMessage = ""
            
            // Login user
            FirebaseManager.shared.auth.signIn(withEmail: loginEmail, password: loginPassword) {
                result, err in
                if let err = err as NSError? {
                    if err.domain == "FIRAuthErrorDomain", err.code == 17999 {
                        self.statusMessage = "Incorrect email or password"
                    } else {
                        self.statusMessage = err.localizedDescription
                    }
                    return
                }
                
                
                // Temporarily disabled for development
    //            guard let resultUser = result?.user else {
    //                loginStatusMessage = "Login error: Auth user not found"
    //                return
    //            }

    //            if (!resultUser.isEmailVerified) {
    //                loginStatusMessage = "Please verify your email account"
    //                return
    //            }
                
                // Update currentUser in FirebaseManager
                FirebaseManager.shared.firestore.collection("users").document(self.loginEmail).getDocument { document, err in
                    if let err = err {
                        print(err)
                        self.statusMessage = err.localizedDescription
                        try? FirebaseManager.shared.auth.signOut()
                        return
                    }
                    
                    if let document = document {
                        if let currentUser = try? document.data(as: User.self) {
                            // Great success
                            FirebaseManager.shared.currentUser = currentUser
                            self.statusMessage = "Successfully logged in as \(self.loginEmail)"
                            onSuccess()
                        } else {
                            self.statusMessage = "Error converting user info to local object"
                            try? FirebaseManager.shared.auth.signOut()
                        }
                    } else {
                        self.statusMessage = "User not found in database"
                        try? FirebaseManager.shared.auth.signOut()
                    }
                }
            }
    }
}
