//
//  TicketsTabView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct TabBarView: View {
    
    @Binding var showLoginView: Bool
    @Binding var selectedTab: Int
    
    @State private var bannerText = ""
    @State private var bannerColor = Color.orange
    @State private var showBanner = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                MainTicketsView(notifyUser: self.notifyUser)
                    .tabItem {Image(systemName: "ticket")}
                    .tag(0)
                
                MainMessagesView(notifyUser: self.notifyUser)
                    .tabItem {Image(systemName: "message")}
                    .tag(1)
                
                MyListingsView(notifyUser: self.notifyUser)
                    .tabItem {Image(systemName: "list.bullet")}
                    .tag(2)
                
                ProfileView(notifyUser: self.notifyUser, showLoginView: $showLoginView)
                    .tabItem {Image(systemName: "person")}
                    .tag(3)
            }
            
            NotificationBanner(bannerText: bannerText, bannerColor: bannerColor)
                .offset(y: showBanner ?
                        -UIScreen.main.bounds.height / 2.5 :
                            -UIScreen.main.bounds.height)
                .animation(Animation.easeInOut(duration: 0.8), value: showBanner)
        }
    }
    
    private func notifyUser(notification: String, notificationColor: Color) {
        
        bannerText = notification
        bannerColor = notificationColor
        withAnimation {
            showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showBanner = false
            }
        }
    }
}

struct TicketsTabView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(showLoginView: .constant(false), selectedTab: .constant(0))
    }
}
