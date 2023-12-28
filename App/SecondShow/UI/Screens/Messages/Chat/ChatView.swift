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
    
    @State var textEditorHeight : CGFloat = 40
    var maxHeight : CGFloat = 250
    
    init(vm: ChatViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack (alignment: .top) {
            messageView
            descriptionBarView
        }
        .navigationTitle(vm.titleText)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.inputText = ""
            vm.fetchMessages()
        }
        .onDisappear {
            vm.removeListener()
        }
    }
    
    private var descriptionBarView: some View {
        HStack (spacing: 10) {
            if vm.eventName != nil, vm.listingNumber != nil {
                HStack {
                    Text("\(vm.eventName!) #\(String(vm.listingNumber!))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(.white))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color("SecondShowBlue"))
                .cornerRadius(10)
            }

            if vm.price != nil {
                HStack {
                    Text("$\(String(vm.price!))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(.white))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(.systemOrange))
                .cornerRadius(10)
            }
        }
        .frame(height: 36)
        .padding(.horizontal)
        .padding(.bottom, 6)
    }
    
    private var messageView: some View {
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    VStack {
                        ForEach(self.vm.chatMessages) { chatMessage in
                            
                            if (chatMessage.fromEmail == FirebaseManager.shared.currentUser?.email) {
                                HStack {
                                    Spacer()
                                    HStack {
                                        Text(chatMessage.message).foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color("SecondShowMain"))
                                    .cornerRadius(18)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 3)
                            } else {
                                HStack {
                                    HStack {
                                        Text(chatMessage.message).foregroundColor(.black)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(18)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 3)
                            }
                        }
                        
                        if (vm.deleted) {
                            Text("The seller has deleted this listing")
                                .foregroundColor(Color.gray)
                        }
                        if (vm.sold) {
                            Text("This listing has been sold")
                                .foregroundColor(Color.gray)
                        }
                        
                        HStack{Spacer()}
                            .id(Self.emptyScrollToString)
                    }
                    .padding(.top, 34)
                    .onReceive(vm.$autoScrollCount) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color("SecondShowChatBackground"))
            .safeAreaInset(edge: .bottom) {
                inputDockView
                    .background(Color("SecondShowChatBackground").ignoresSafeArea())
            }
    }
    
    private var inputDockView: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                
                DescriptionPlaceholder()
                    .padding(.horizontal, 8)

                Text(vm.inputText.count == 0 ? " " : vm.inputText)
                    .foregroundColor(.clear)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewHeightKey.self,
                           value: $0.frame(in: .local).size.height)
                    })
                
                if #available(iOS 16.0, *) {
                    TextEditor(text: $vm.inputText)
                        .frame(height: min(textEditorHeight, maxHeight))
                        .padding(.horizontal, 8)
                        .disabled(vm.sold || vm.deleted)
                        .scrollContentBackground(.hidden)
                        .background(Color.white)
                        .foregroundColor(Color.black)
                        .opacity(self.vm.inputText.isEmpty ? 0.5 : 1)
                } else {
                    TextEditor(text: $vm.inputText)
                        .frame(height: min(textEditorHeight, maxHeight))
                        .padding(.horizontal, 8)
                        .disabled(vm.sold || vm.deleted)
                        .background(Color.white)
                        .foregroundColor(Color.black)
                        .opacity(self.vm.inputText.isEmpty ? 0.5 : 1)
                        .onAppear {
                            UITextView.appearance().backgroundColor = .clear
                        }
                }

            }
            .background(Color(.white))
            .cornerRadius(18)

            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(!(vm.sold || vm.deleted) ? Color("SecondShowMain") : Color("SecondShowSecondary"))
            .cornerRadius(4)
            .disabled(vm.sold || vm.deleted)
            .clipShape(Capsule())
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .onPreferenceChange(ViewHeightKey.self) {
            textEditorHeight = $0
        }

    }
    
    private struct DescriptionPlaceholder: View {
        var body: some View {
            HStack {
                Text("Message")
                    .foregroundColor(Color(.gray))
                    .font(.system(size: 17))
                    .padding(.leading, 5)
                Spacer()
            }
        }
    }
    
    struct ViewHeightKey: PreferenceKey {
        static var defaultValue: CGFloat { 0 }
        static func reduce(value: inout Value, nextValue: () -> Value) {
            value = value + nextValue()
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        //        ChatView()
        //        MainMessagesView(notifyUser: {_, _ in}, chatVm: ChatViewModel())
        EmptyView()
    }
}
