//
//  LoginViewModel.swift
//  SecondShow
//
//  Created by Alan on 11/27/23.
//

import Foundation
import FirebaseAuth


class LoginViewModel: ObservableObject {

    private let userService: UserService
    
    
    init(userService: UserService) {
        self.userService = userService
    }
    
    @Published var showSignupView = false
    @Published var showSignupCompleteAlert = false
    
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var statusMessage = ""
    @Published var signupUsername = ""
    @Published var signupEmail = ""
    @Published var signupPassword = ""
    @Published var signupConfirmPassword = ""
    
    @Published var disableSubmit = false;
    
    // Switch to true for production
    private var requireVerification = false
    
    
    private func containsOnlyAlphanumericCharacters(in string: String) -> Bool {
        let regex = "^[A-Za-z0-9]+$"
        let predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        return predicate.evaluate(with: string)
    }
    
    func createAccount() {
        disableSubmit = true
        // Validation
        if (signupUsername.count < 3) {
            self.statusMessage = "Please enter a longer username"
            disableSubmit = false
            return
        }
        
        if (!containsOnlyAlphanumericCharacters(in: signupUsername)) {
            self.statusMessage = "Username cannot contain special characters"
            disableSubmit = false
            return
        }
//        if (signupUsername.contains("[^A-Za-z0-9]")) {
//            self.statusMessage = "Username cannot contain special characters"
//            return
//        }
        
        if (signupUsername.count > 10) {
            self.statusMessage = "Username is too long"
            disableSubmit = false
            return
        }
        
        if (!signupEmail.hasSuffix("gmail.com")) {
            self.statusMessage = "Please sign up with a gmail address"
            disableSubmit = false
            return
        }
        if (signupPassword.count < 8) {
            self.statusMessage = "Password needs to be at least 8 characters"
            disableSubmit = false
            return
        }
        if (signupPassword != signupConfirmPassword) {
            self.statusMessage = "Passwords do not match"
            disableSubmit = false
            return
        }
        self.statusMessage = ""
        
        // Create user
        userService.createUser(username: signupUsername, email: signupEmail, password: signupPassword, createTime: Date(), sendEmailVerification: requireVerification) { _, err in
            if let err = err {
                self.statusMessage = err
                // Only want to create user, not sign in
                self.userService.logoutUser()
                self.disableSubmit = false
                return
            }
            self.disableSubmit = false
            self.didCompleteSignUp()
            self.userService.logoutUser()
        }
    }
    
    private func didCompleteSignUp() {
        signupUsername = ""
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
        
        userService.loginUser(email: loginEmail, password: loginPassword, emailVerificationRequired: requireVerification) { err in
            if let err = err {
                self.statusMessage = err
                return
            }
            self.statusMessage = ""
            onSuccess()
        }
    }
}
