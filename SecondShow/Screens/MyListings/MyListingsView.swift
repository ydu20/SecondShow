//
//  MyListingsView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct MyListingsView: View {
    var body: some View {
        VStack {
            NavBar<EmptyView>(title: "My Listings", subtitle: nil)
            listings
        }.padding()
    }
    
    private var listings: some View {
        ScrollView {
            ForEach(0..<2, id: \.self) { num in
                HStack {
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Concert Show #35")
                                .font(.system(size: 20, weight: .bold))
                            HStack(spacing: 12) {
                                Text("Nov. 16")
                                    .font(.system(size: 15))
                                HStack(spacing: 3) {
                                    Image(systemName: "flame")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(.orange))
                                    Text("18")
                                        .font(.system(size: 15))
                                }
                                HStack(spacing: 2) {
                                    Text("x")
                                        .font(.system(size: 13, weight: .semibold))
                                        .padding(.bottom, 1)
                                    Text("1/1")
                                        .font(.system(size: 15))
                                }
                            }
                        }
                        Spacer()
                        Button {
                            // TODO
                            
                        } label: {
                            Text("Sold")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .frame(height: 24)
                                .frame(width: 50)
                                .background(Color(.systemGreen))
                                .cornerRadius(6)
                        }
                        Button {
                            // TODO
                        } label: {
                            VStack {
                                Circle()
                                    .fill(Color(.systemRed))
                                    .frame(width: 23, height: 23)
                                    .overlay(
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                    )
                            }
                        }
                    }
                    .foregroundColor(Color(.white))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color(.systemBlue))
                    .cornerRadius(10)
                }
                .padding(.vertical, 3)
                
            }
        }
    }
}

struct MyListingsView_Previews: PreviewProvider {
    static var previews: some View {
        TicketsTabView(selectedTab: .constant(2))
        
    }
}
