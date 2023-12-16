//
//  MyListingsView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct MyListingsView: View {
    
    let notifyUser: (String, Color) -> ()
    
    @StateObject var vm = MyListingsViewModel()
        
    @State private var showSoldPopupView = false
    @State private var showDeletePopupView = false

    var body: some View {
        VStack {
            NavBar<EmptyView>(title: "My Listings", subtitle: nil)
                .padding(.horizontal)
            
            ZStack {
                ScrollView {
                    myAvailableListingsView
                        .padding(.horizontal)
                    mySoldOutListingsView
                        .padding(.horizontal)
                }
                .blur(radius: showSoldPopupView || showDeletePopupView ? 3 : 0)
                .disabled(showSoldPopupView || showDeletePopupView)

                if showSoldPopupView || showDeletePopupView {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .edgesIgnoringSafeArea(.all)
                }
                
                if showSoldPopupView {
                    SoldPopupView(showPopupView: $showSoldPopupView, vm: vm, notifyUser: notifyUser)
                        .transition(.asymmetric(insertion: .scale(scale: 1.05), removal: .opacity))
                }
                
                if showDeletePopupView {
                    DeletePopupView(showPopupView: $showDeletePopupView, vm: vm, notifyUser: notifyUser)
                        .transition(.asymmetric(insertion: .scale(scale: 1.05), removal: .opacity))
                }
            }
        }
        .padding(.vertical)
//        .onDisappear {
//            vm.myListingListener?.remove()
//        }
        .onAppear {
            vm.notifyUser = self.notifyUser
        }
    }
    
    private var myAvailableListingsView: some View {
        ForEach(self.vm.myAvailableListings) { listing in
            HStack {
                HStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(listing.eventName)
                            .font(.system(size: 20, weight: .bold))
                        HStack(spacing: 12) {
                            Text(listing.eventDateMMMdd)
                                .font(.system(size: 15))
                            HStack(spacing: 2) {
                                Text("#")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.bottom, 1)
                                Text("\(listing.listingNumber)")
                                    .font(.system(size: 15))
                            }
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
                        vm.selectedListing = listing
                        withAnimation(.linear(duration: 0.2)) {
                            showSoldPopupView.toggle()
                        }
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
                        vm.selectedListing = listing
                        withAnimation(.linear(duration: 0.2)) {
                            showDeletePopupView.toggle()
                        }
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
        ForEach(self.vm.mySoldOutListings) { listing in
            HStack {
                HStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(listing.eventName)
                            .font(.system(size: 20, weight: .bold))
                        HStack(spacing: 12) {
                            Text(listing.eventDateMMMdd)
                                .font(.system(size: 15))
                            HStack(spacing: 2) {
                                Text("#")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.bottom, 1)
                                Text("\(listing.listingNumber)")
                                    .font(.system(size: 15))
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "flame")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.black.opacity(0.3))
                                Text(String(listing.popularity))
                                    .font(.system(size: 15))
                            }
                            HStack(spacing: 2) {
                                Text("x")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.bottom, 1)
                                Text("0/\(listing.totalQuantity)")
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
        EmptyView()
    }
}
