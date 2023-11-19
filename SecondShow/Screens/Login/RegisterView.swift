//
//  RegisterView.swift
//  SecondShow
//
//  Created by Alan on 11/14/23.
//

import SwiftUI
import FirebaseFirestore

struct RegisterView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var registerEmail = ""
    @State private var registerPassword = ""
    @State private var registerConfirmPassword = ""
    
    @State private var signupStatusMessage = ""
    @State private var showSignUpCompleteAlert = false
    
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Sign Up")
                    .font(.system(size: 32, weight: .semibold))
                Spacer()
            }
            .padding(.bottom, 20)

            Group {
                TextField("Email", text: $registerEmail)
                    .font(.system(size: 18))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.quaternaryLabel), lineWidth: 2)
                    )

                SecureField("Password", text: $registerPassword)
                    .font(.system(size: 18))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.quaternaryLabel), lineWidth: 2)
                    )
                
                SecureField("Confirm password", text: $registerConfirmPassword)
                    .font(.system(size: 18))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.quaternaryLabel), lineWidth: 2)
                    )
            }
            .background(Color.white)
            .cornerRadius(10)
            
            Button {
                createAccount()
            } label: {
                Text("Sign Up")
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(.white))
                    .background(Color(.systemBlue))
                    .cornerRadius(10)
            }
            
            Text(self.signupStatusMessage)
                .foregroundColor(Color(red: 0.8, green: 0, blue: 0))
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showSignUpCompleteAlert) {
            Alert(
                title: Text("Email Verification"),
                message: Text("Thank you for signing up! Please check your email for a verification link."),
                dismissButton: .default(Text("Close")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func createAccount() {
        // Validation
        if (!registerEmail.hasSuffix("gmail.com")) {
            signupStatusMessage = "Please register with an gmail address"
            return
        }
        if (registerPassword.count < 8) {
            signupStatusMessage = "Password needs to be at least 8 characters"
            return
        }
        if (registerPassword != registerConfirmPassword) {
            signupStatusMessage = "Passwords do not match"
            return
        }
        signupStatusMessage = ""
        
        // Create user
        FirebaseManager.shared.auth.createUser(withEmail: registerEmail, password: registerPassword) { result, err in
            if let err = err {
                print("Failed to create user: ", err)
                self.signupStatusMessage = "Failed to create user: \(err)"
                return
            }
            
            print("Successfully created user: \(result?.user.uid ?? "")")
            
            guard let currentUser = FirebaseManager.shared.auth.currentUser else {return}
            
            // Upload user to FireStore
            let userData = [FirebaseConstants.uid: currentUser.uid, FirebaseConstants.email: registerEmail, FirebaseConstants.createTime: Timestamp()] as [String: Any]
            
            FirebaseManager.shared.firestore.collection("users")
                .document(currentUser.uid).setData(userData) { err in
                    if let err = err {
                        print(err)
                        self.signupStatusMessage = "\(err)"
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
                    
                    didCompleteSignUp()
                }
        }
    }
    
    private func didCompleteSignUp() {
        registerEmail = ""
        registerPassword = ""
        registerConfirmPassword = ""
        
        showSignUpCompleteAlert.toggle()
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
//        LoginView()
        RegisterView()
    }
}
