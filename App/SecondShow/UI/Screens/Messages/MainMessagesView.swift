//
//  MainMessagesView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct MainMessagesView: View {
    
    
    @ObservedObject private var vm: MainMessagesViewModel
    var chatVm: ChatViewModel
    
    @State private var showChatView = false
    @State private var intraTabNavigation = false
    
    init(mainMessagesViewModel: MainMessagesViewModel, chatVm: ChatViewModel, messageService: MessageService, notifyUser: @escaping (String, Color) -> Void) {
        self.chatVm = chatVm
        self.vm = mainMessagesViewModel
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
                vm.fetchRecentMessages(oneTime: false)
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
                                Text(recentMessage.counterpartyUsername)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(.label))
                                
                                HStack {
                                    Text("\(recentMessage.eventName) #\(recentMessage.listingNumber)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(.white))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color("SecondShowBlue"))
                                .cornerRadius(10)
                                    
                            }
                            
                            Text(
                                recentMessage.sold ? "This listing has been sold" :
                                    recentMessage.deleted ? "The seller has deleted this listing" :
                                    recentMessage.expired ? "This listing has expired" :
                                    recentMessage.message
                            )
                                .font(.system(size: 15))
                                .foregroundColor(recentMessage.read ? Color("SecondShowSubtext") : Color(.label))
                                .foregroundColor(Color(.label))
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
