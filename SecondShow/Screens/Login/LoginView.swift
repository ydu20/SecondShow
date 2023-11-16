//
//  LoginView.swift
//  SecondShow
//
//  Created by Alan on 11/14/23.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    
    @Binding var showLoginView: Bool
    @State var showRegisterView = false
    
    @State private var email = ""
    @State private var password = ""
    @State private var loginStatusMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    HStack {
                        Spacer()
                        Button {
                            self.showRegisterView.toggle()
                        } label: {
                            Text("Register")
                        }
                    }
                    
                    Text("Second Show")
                        .font(.system(size: 38, weight: .bold))
                        .padding(.top, 25)
                    Text("Your second chance at that show")
                        .font(.system(size: 16, weight: .thin))
                        .padding(.top, 5)
                        .padding(.bottom, 26)
                    
                    Group {
                        TextField("Email", text: $email)
                            .font(.system(size: 18))
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.quaternaryLabel), lineWidth: 2)
                            )
                        
                        SecureField("Password", text: $password)
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
                        loginUser()
                    } label: {
                        Text("Log in")
                            .frame(height: 45)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color(.white))
                            .background(Color(.systemBlue))
                            .cornerRadius(10)
                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(Color(red: 0.8, green: 0, blue: 0))
                    
                    Spacer()
                }
                .padding()
                .navigationBarHidden(true)
                .navigationDestination(isPresented: $showRegisterView) {
                    RegisterView()
                }
            }
        }
    }
    
    private func loginUser() {
        // Validation
        if (email.count < 5) {
            loginStatusMessage = "Please enter a valid email"
            return
        }
        if (password.count == 0) {
            loginStatusMessage = "Please enter a password"
            return
        }
        loginStatusMessage = ""
        
//        let usersCollectionRef = FirebaseManager.shared.firestore.collection("users")
//        usersCollectionRef.getDocuments { (snapshot, error) in
//            if let error = error {
//                print("Error getting documents: \(error)")
//            } else {
//                for document in snapshot!.documents {
//                    print("\(document.documentID) => \(document.data())")
//                }
//            }
//        }
//        return
        
        // Login user
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err as NSError? {
                if err.domain == "FIRAuthErrorDomain", err.code == 17999 {
                    loginStatusMessage = "Incorrect email or password"
                } else {
                    loginStatusMessage = err.localizedDescription
                }
                return
            }
            
            
            guard let resultUser = result?.user else {
                loginStatusMessage = "Error logging in"
                return
            }
            
            
            // Temporarily disabled for development
//            if (!resultUser.isEmailVerified) {
//                loginStatusMessage = "Please verify your email account"
//                return
//            }
            
            // Update currentUser in FirebaseManager
            FirebaseManager.shared.firestore.collection("users").document(resultUser.uid).getDocument { document, err in
                if let err = err {
                    print(err)
                    loginStatusMessage = err.localizedDescription
                    try? FirebaseManager.shared.auth.signOut()
                    return
                }
                
                if let currentUser = try? document?.data(as: User.self) {
                    // Great success
                    FirebaseManager.shared.currentUser = currentUser
                    loginStatusMessage = "Successfully logged in as \(result?.user.email ?? "")"
                    showLoginView.toggle()
                } else {
                    try? FirebaseManager.shared.auth.signOut()
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
//        LoginView(showLoginView: .constant(true))
        RootView()
    }
}
