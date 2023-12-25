//
//  RootView.swift
//  SecondShow
//
//  Created by Alan on 11/14/23.
//

import SwiftUI
import FirebaseMessaging

struct RootView: View {
    
    @State private var showLoginView: Bool = false
    @State private var selectedTab: Int = 0
    
    private let userService = UserService()
    private let eventService = EventService()
    private let listingService = ListingService()
    private let messageService = MessageService()
    
    var body: some View {
        ZStack {
            if !showLoginView {
                TabBarView(
                    showLoginView: $showLoginView,
                    selectedTab: $selectedTab,
                    userService: userService,
                    eventService: eventService,
                    listingService: listingService,
                    messageService: messageService
                )
            }
        }
        .onAppear {
            // Verify login status & attach listener
            if (FirebaseManager.shared.auth.currentUser != nil) {
                if let fcmToken = Messaging.messaging().fcmToken {
                    userService.updateFcmToken(fcmToken: fcmToken) { err in
                        if let err = err {
                            print(err)
                            return
                        }
                    }
                }
                
                userService.attachUserListener { updatedUser, err in
                    if let err = err {
                        print(err)
                        return
                    }
                    FirebaseManager.shared.currentUser = updatedUser
                }
            } else {
                showLoginView = true
            }
        }
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView(showLoginView: $showLoginView, userService: userService)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
