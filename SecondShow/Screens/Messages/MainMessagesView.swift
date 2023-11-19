//
//  MainMessagesView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct MainMessagesView: View {
    
    let notifyUser: (String, Color) -> ()
    
    var body: some View {
        VStack {
            NavBar<EmptyView>(title: "Messages", subtitle: nil)
            messageList
            
        }.padding()
    }
    
    private var messageList: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                Button {
                    
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
