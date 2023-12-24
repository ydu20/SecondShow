//
//  MainMessagesView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct MainMessagesView: View {
    
    
    @StateObject private var vm: MainMessagesViewModel
    var chatVm: ChatViewModel
    
    @State private var showChatView = false
    
    @State private var intraTabNavigation = false
    
    init(chatVm: ChatViewModel, messageService: MessageService, notifyUser: @escaping (String, Color) -> Void) {
        self.chatVm = chatVm
        _vm = StateObject(wrappedValue: MainMessagesViewModel(chatVm: chatVm, messageService: messageService, notifyUser: notifyUser))
    }
    
    
    var body: some View {
        VStack {
            NavBar<EmptyView>(title: "Messages", subtitle: nil)
                .padding(.horizontal)
            
            if vm.recentMessages.count == 0 {
                Text("Message a listing to start a chat!")
                    .padding(.top, 200)
                Spacer()
            } else {
                messageList
            }
            
            NavigationLink(destination: ChatView(vm: chatVm), isActive: $showChatView) {
                EmptyView()
            }
            .hidden()
        }
        .padding(.vertical)
        .onAppear {
            if (!intraTabNavigation) {
                vm.fetchRecentMessages()
            }
        }
        .onDisappear {
            if !(showChatView) {
                vm.removeListener()
                intraTabNavigation = false
            }
        }
    }
    
    private var messageList: some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                Button {
                    vm.updateReadStatus(rm: recentMessage)
                    chatVm.updateWithRecentMessage(rm: recentMessage)
                    showChatView.toggle()
                    intraTabNavigation = true
                } label: {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            
                            HStack (spacing: 10) {
                                Text(recentMessage.counterpartyEmail.split(separator: "@").first ?? "")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(.label))
                                
                                HStack {
                                    Text("\(recentMessage.eventName) #\(recentMessage.listingNumber)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(.white))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(.systemIndigo))
                                .cornerRadius(10)
                                    
                            }
                            
                            Text(
                                recentMessage.sold ? "This listing has been sold" :
                                    recentMessage.deleted ? "The seller has deleted this listing" :
                                    recentMessage.message
                            )
                                .font(.system(size: 13))
                                .foregroundColor(recentMessage.read ? Color(.darkGray) : Color(.black))
                                .fontWeight(recentMessage.read ? .regular : .semibold)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Text(recentMessage.timeAgo)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.top, 7)
                    .padding(.horizontal)
                }
                Divider()
                    .padding(.vertical, 5)
                    .padding(.horizontal)
            }
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
//        MainMessagesView()
//        TabBarView(
//            showLoginView: .constant(false),
//            selectedTab: .constant(0),
//            userService: UserService(),
//            eventService: EventService()
//        )
        EmptyView()
    }
}
