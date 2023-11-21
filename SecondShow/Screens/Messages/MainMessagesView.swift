//
//  MainMessagesView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct MainMessagesView: View {
    
    let notifyUser: (String, Color) -> ()
    
    @State private var showAlert = false
    
    var body: some View {
        VStack {
            NavBar<EmptyView>(title: "Messages", subtitle: nil)
            messageList
            
        }.padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Alert Message"),
                    message: Text("This is alert message"),
                    dismissButton: .default(Text("Dismiss"))
                )
            }
    }
    
    private var messageList: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                Button {
                    showAlert.toggle()
                } label: {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Concert Show #35")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(.label))
                            Text("Hey, is this still available?")
                                .font(.system(size: 13))
                                .foregroundColor(Color(.darkGray))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Text("5m")
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
