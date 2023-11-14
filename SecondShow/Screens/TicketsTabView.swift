//
//  TicketsTabView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct TicketsTabView: View {
    
    @Binding var selectedTab: Int
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainTicketsView()
                .tabItem {Image(systemName: "ticket")}
                .tag(0)
            
            MainMessagesView()
                .tabItem {Image(systemName: "message")}
                .tag(1)
            
            MyListingsView()
                .tabItem {Image(systemName: "list.bullet")}
                .tag(2)
            
            ProfileView()
                .tabItem {Image(systemName: "person")}
                .tag(3)
        }
    }
}

struct TicketsTabView_Previews: PreviewProvider {
    static var previews: some View {
        TicketsTabView(selectedTab: .constant(0))
    }
}
