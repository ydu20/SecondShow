//
//  ChatLogView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct ChatView: View {
    
    @StateObject var vm: ChatViewModel
    
    @State private var tempInput = ""
    
    var body: some View {
        ZStack {
            messageView
        }
        .navigationTitle("Hello")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // TODO
        }
    }
    
    private var inputDockView: some View {
        HStack {
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $tempInput)
                    .opacity(tempInput.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            Button {
                // TODO
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
        VStack {
            ScrollView {
                VStack {
                    ForEach(0..<20, id: \.self) { num in
                        HStack {
                            Spacer()
                            HStack {
                                Text("Message # \(num)").foregroundColor(.white)
                            }
                            .padding(12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
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
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
//        ChatView()
        MainMessagesView(notifyUser: {_, _ in})
    }
}
