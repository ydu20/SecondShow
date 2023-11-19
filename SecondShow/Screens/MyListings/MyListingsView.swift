//
//  MyListingsView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct MyListingsView: View {
    
    let notifyUser: (String, Color) -> ()
    
    @StateObject private var vm = MyListingsViewModel()

    var body: some View {
        VStack {
            NavBar<EmptyView>(title: "My Listings", subtitle: nil)
            ScrollView {
                myAvailableListingsView
                mySoldOutListingsView
            }
        }.padding()
    }
    
    private var myAvailableListingsView: some View {
        ForEach(self.vm.myAvailableListings) { listing in
            HStack {
                HStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(listing.eventName)
                            .font(.system(size: 20, weight: .bold))
                        HStack(spacing: 12) {
                            Text(listing.eventDateMMMMdd)
                                .font(.system(size: 15))
                            HStack(spacing: 3) {
                                Image(systemName: "flame")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(.orange))
                                Text(String(listing.popularity))
                                    .font(.system(size: 15))
                            }
                            HStack(spacing: 2) {
                                Text("x")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.bottom, 1)
                                Text("\(listing.availableQuantity)/\(listing.totalQuantity)")
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
    
    private var mySoldOutListingsView: some View {
        ForEach(self.vm.mySoldOutListings) { mySoldOutListing in
            HStack {
                HStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mySoldOutListing.eventName)
                            .font(.system(size: 20, weight: .bold))
                        HStack(spacing: 12) {
                            Text(mySoldOutListing.eventDateMMMMdd)
                                .font(.system(size: 15))
                            HStack(spacing: 3) {
                                Image(systemName: "flame")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.black.opacity(0.3))
                                Text(String(mySoldOutListing.popularity))
                                    .font(.system(size: 15))
                            }
                            HStack(spacing: 2) {
                                Text("x")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.bottom, 1)
                                Text("0/\(mySoldOutListing.totalQuantity)")
                                    .font(.system(size: 15))
                            }
                        }
                    }
                    Spacer()

                    Text("Sold Out")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white)
                        .frame(height: 24)
                        .frame(width: 78)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(6)

                }
                .foregroundColor(Color(.white))
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
            }
            .padding(.vertical, 3)
        }
    }
}

struct MyListingsView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(showLoginView: .constant(false), selectedTab: .constant(2))
    }
}
