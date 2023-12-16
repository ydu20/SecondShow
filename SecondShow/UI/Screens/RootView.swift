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
    
    private let userService = UserService()
    private let eventService = EventService()
    
    var body: some View {
        ZStack {
            if !showLoginView {
                TabBarView(
                    showLoginView: $showLoginView,
                    selectedTab: $selectedTab,
                    userService: userService,
                    eventService: eventService
                )
            }
        }
        .onAppear {
            // Verify login status & attach listener
            userService.verifyLoginStatus { loggedIn in
                if !loggedIn {
                    showLoginView = true
                } else {
                    userService.attachUserListener { updatedUser, err in
                        if let err = err {
                            print(err)
                            return
                        }
                        FirebaseManager.shared.currentUser = updatedUser
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView(showLoginView: $showLoginView, userService: userService)
        }
//        .environmentObject(userService)
//        .environmentObject(eventService)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
