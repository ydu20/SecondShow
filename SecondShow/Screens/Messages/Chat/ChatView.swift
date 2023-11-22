//
//  ChatLogView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct ChatView: View {
    
    @StateObject var vm: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    static let emptyScrollToString = "BottomAnchor"
    
    var body: some View {
        ZStack {
            messageView
        }
        .navigationTitle(vm.titleText)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.trailing, -2)
                        Text("Back")
                    }
                }
            }
        }
        .onAppear {
            vm.fetchMessages()
        }
        .onDisappear {
            // TODO
            vm.messagesListener?.remove()
        }
    }
    
    private var inputDockView: some View {
        HStack {
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $vm.inputText)
                    .opacity(self.vm.inputText.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
    }
    
    private struct DescriptionPlaceholder: View {
        var body: some View {
            HStack {
                Text("Message")
                    .foregroundColor(Color(.gray))
                    .font(.system(size: 17))
                    .padding(.leading, 5)
                    .padding(.top, -4)
                Spacer()
            }
        }
    }
    
    private var messageView: some View {
        ScrollView {
            ScrollViewReader { scrollViewProxy in
                VStack {
                    ForEach(self.vm.chatMessages) { chatMessage in
                        
                        if (chatMessage.fromId == FirebaseManager.shared.auth.currentUser?.uid) {
                            HStack {
                                Spacer()
                                HStack {
                                    Text(chatMessage.message).foregroundColor(.white)
                                }
                                .padding(12)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        } else {
                            HStack {
                                HStack {
                                    Text(chatMessage.message).foregroundColor(.black)
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    
                    HStack{Spacer()}
                        .id(Self.emptyScrollToString)
                }
                .onReceive(vm.$autoScrollCount) { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
        .safeAreaInset(edge: .bottom) {
            inputDockView
                .background(Color(.systemBackground).ignoresSafeArea())
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
//        ChatView()
        MainMessagesView(notifyUser: {_, _ in}, chatVm: ChatViewModel())
    }
}
