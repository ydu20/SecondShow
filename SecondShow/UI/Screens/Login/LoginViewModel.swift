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
        userService.createUser(email: signupEmail, password: signupPassword, createTime: Date(), sendEmailVerification: requireVerification) { _, err in
            if let err = err {
                self.statusMessage = err
                // Only want to create user, not sign in
                self.userService.logoutUser()
                return
            }
            self.didCompleteSignUp()
            self.userService.logoutUser()
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
        
        userService.loginUser(email: loginEmail, password: loginPassword, emailVerificationRequired: requireVerification) { err in
            if let err = err {
                self.statusMessage = err
                return
            }
            onSuccess()
        }
    }
}
