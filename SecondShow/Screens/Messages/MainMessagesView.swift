//
//  MainMessagesView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct MainMessagesView: View {
    
    let notifyUser: (String, Color) -> ()
    
    @StateObject private var vm = MainMessagesViewModel()
    var chatVm: ChatViewModel
    
    @State private var showChatView = false
    
    var body: some View {
        VStack {
            NavBar<EmptyView>(title: "Messages", subtitle: nil)
            messageList
            NavigationLink(destination: ChatView(vm: chatVm), isActive: $showChatView) {
                EmptyView()
            }
            .hidden()
        }
        .padding()
        .onAppear {
            vm.fetchRecentMessages()
        }
        .onDisappear {
            vm.recentMessagesListener?.remove()
        }
    }
    
    private var messageList: some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                Button {
                    chatVm.updateWithRecentMessage(rm: recentMessage)
                    showChatView.toggle()
                } label: {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(recentMessage.eventName) #\(recentMessage.listingNumber)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(.label))
                            Text(recentMessage.message)
                                .font(.system(size: 13))
                                .foregroundColor(Color(.darkGray))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Text(recentMessage.timeAgo)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                Divider()
                    .padding(.vertical, 8)
            }
            
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
//        MainMessagesView()
        TabBarView(showLoginView: .constant(false), selectedTab: .constant(1))
    }
}
