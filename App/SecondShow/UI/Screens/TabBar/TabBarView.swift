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
    private let userService: UserService
    private let eventService: EventService
    private let listingService: ListingService
    private let messageService: MessageService
    
    @State private var bannerText = ""
    @State private var bannerColor = Color.orange
    @State private var showBanner = false
    
    private var mainTicketsViewModel: MainTicketsViewModel
    private var mainMessagesViewModel: MainMessagesViewModel
    private var chatViewModel: ChatViewModel
    private var myListingsViewModel: MyListingsViewModel
    
    private static var shared: TabBarView?
            
    init(
        showLoginView: Binding<Bool>,
        selectedTab: Binding<Int>,
        userService: UserService,
        eventService: EventService,
        listingService: ListingService,
        messageService: MessageService
        ) {
            _showLoginView = showLoginView
            _selectedTab = selectedTab
            self.userService = userService
            self.eventService = eventService
            self.listingService = listingService
            self.messageService = messageService
            
            self.chatViewModel = ChatViewModel(listingService: listingService, messageService: messageService)
            
            self.mainTicketsViewModel = MainTicketsViewModel(
                eventService: eventService
            )
            self.mainMessagesViewModel = MainMessagesViewModel(
                chatVm: self.chatViewModel,
                messageService: messageService,
                notifyUser: Self.notifyUser
            )
            self.myListingsViewModel = MyListingsViewModel(
                eventService: eventService,
                listingService: listingService,
                messageService: messageService,
                notifyUser: Self.notifyUser
            )
            
            Self.shared = self
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                TabView(selection: $selectedTab) {
                    MainTicketsView(
                        mainTicketsViewModel: mainTicketsViewModel,
                        chatVm: chatViewModel,
                        eventService: eventService,
                        listingService: listingService,
                        notifyUser: Self.notifyUser
                    )
                        .tabItem {Image(systemName: "ticket")}
                        .tag(0)
                        .navigationBarTitle("")
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(true)
                    
                    MainMessagesView(
                        mainMessagesViewModel: mainMessagesViewModel,
                        chatVm: chatViewModel,
                        messageService: messageService,
                        notifyUser: Self.notifyUser
                    )
                        .tabItem {Image(systemName: "message")}
                        .tag(1)
                        .navigationBarTitle("")
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(true)
                    
                    MyListingsView(
                        myListingsViewModel: myListingsViewModel,
                        eventService: eventService,
                        listingService: listingService,
                        messageService: messageService,
                        notifyUser: Self.notifyUser
                    )
                        .tabItem {Image(systemName: "list.bullet")}
                        .tag(2)
                        .navigationBarTitle("")
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(true)
                    
                    ProfileView(
                        showLoginView: $showLoginView,
                        eventService: eventService,
                        listingService: listingService,
                        messageService: messageService,
                        userService: userService,
                        notifyUser: Self.notifyUser
                    )
                        .tabItem {Image(systemName: "person")}
                        .tag(3)
                        .navigationBarTitle("")
                        .navigationBarBackButtonHidden(true)
                        .navigationBarHidden(true)
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            
            NotificationBanner(bannerText: bannerText, bannerColor: bannerColor)
                .offset(y: showBanner ?
                        -UIScreen.main.bounds.height / 2.5 :
                            -UIScreen.main.bounds.height)
                .animation(Animation.easeInOut(duration: 0.8), value: showBanner)
        }
    }
    
    private static func notifyUser(notification: String, notificationColor: Color) {
        
        shared?.bannerText = notification
        shared?.bannerColor = notificationColor
        withAnimation {
            shared?.showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                shared?.showBanner = false
            }
        }
    }
}

struct TicketsTabView_Previews: PreviewProvider {
    static var previews: some View {
//        TabBarView(
//            showLoginView: .constant(false),
//            selectedTab: .constant(0),
//            userService: UserService(),
//            eventService: EventService()
//        )
        EmptyView()
    }
}
