//
//  MainTicketsView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct MainTicketsView: View {

    
    var body: some View {
        VStack {
            NavBar(
                title: "Second Show",
                subtitle: nil,
                buttonLabel: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color(.label))
                },
                buttonAction: {}
            )
            showsList
        }.padding()
    }
    
    private var showsList: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                HStack(spacing: 16) {
                    Text("Nov. 16")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                }
                Divider()
                    .padding(.vertical, 4)
                
                ForEach(0..<2, id: \.self) { num in
                    Button {
                        
                    } label: {
                        HStack(spacing: 16) {
                            Text("Concert Show")
                                .font(.system(size: 20))
                                .foregroundColor(Color(.label))
                            Spacer()
                            Circle()
                                .fill(Color(.systemBlue))
                                .frame(width: 25, height: 25)
                                .overlay(
                                    Text("15")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(.white))
                                )
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
}

struct MainTicketsVIew_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(showLoginView: .constant(false), selectedTab: .constant(0))
        TabBarView(showLoginView: .constant(false), selectedTab: .constant(0))
            .preferredColorScheme(.dark)
    }
}
