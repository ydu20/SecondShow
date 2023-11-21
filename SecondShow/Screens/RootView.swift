//
//  RootView.swift
//  SecondShow
//
//  Created by Alan on 11/14/23.
//

import SwiftUI

struct RootView: View {
    
    @State private var showLoginView: Bool = false
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            if !showLoginView {
                TabBarView(showLoginView: $showLoginView, selectedTab: $selectedTab)
            }
        }
        .onAppear {
            guard let authCurrentUser = FirebaseManager.shared.auth.currentUser else {
                showLoginView = true
                return
            }
            if (FirebaseManager.shared.currentUser == nil) {
                // Load FirebaseManager CurrentUser
                FirebaseManager.shared.firestore.collection("users").document(authCurrentUser.uid).getDocument { document, err in
                    if let err = err {
                        print("Error retrieving user info: \(err)")
                        try? FirebaseManager.shared.auth.signOut()
                        showLoginView = true
                        return
                    }
                    
                    if let currentUser = try? document?.data(as: User.self) {
                        // Great success
                        FirebaseManager.shared.currentUser = currentUser
                        attachFirebaseUserSnapshot()
                        print("Successfully logged in")
                    } else {
                        try? FirebaseManager.shared.auth.signOut()
                        showLoginView = false
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView(showLoginView: $showLoginView)
        }
    }
    
    private func attachFirebaseUserSnapshot () {
        guard let currentUser = FirebaseManager.shared.currentUser else {return}

        FirebaseManager.shared.firestore.collection("users").document(currentUser.uid).addSnapshotListener { snapshot, err in
            if let err = err {
                print("Error retrieving user info: \(err)")
                return
            }
            
            if let currentUser = try? snapshot?.data(as: User.self) {
                // Great success
                FirebaseManager.shared.currentUser = currentUser
            } else {
                print("Error fetching user snapshot")
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
