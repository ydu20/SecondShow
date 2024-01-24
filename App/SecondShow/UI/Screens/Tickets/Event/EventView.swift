//
//  EventView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct EventView: View {
    
    @ObservedObject var vm: EventViewModel
    var chatVm: ChatViewModel
    
    @State private var showChatView = false
    
    var body: some View {
        VStack {
            if self.vm.listings.count == 0 {
                Text("No available listings for this event currently.")
            } else {
                listingsView
            }
            
            NavigationLink(destination: ChatView(vm: chatVm), isActive: $showChatView) {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle(vm.eventName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if self.vm.eventAlerts {
                        self.vm.deregisterEventAlerts()
                    } else {
                        self.vm.registerEventAlerts()
                    }
                } label: {
                    Image(systemName: self.vm.eventAlerts ? "bell.fill" : "bell")
                        .font(.system(size: 14))
                        .foregroundColor(self.vm.eventAlerts ? Color("SecondShowMain") : Color(.secondaryLabel))
                }
            }
        }
        .padding()
        .onAppear {
            vm.fetchListings()
        }
        .onDisappear {
            vm.removeListener()
        }
    }
    
    private var listingsView: some View {
        ScrollView {
            ForEach(self.vm.listings) { listing in
                Button {
                    guard let userEmail = FirebaseManager.shared.currentUser?.email else {return}
                    
                    if (listing.creatorEmail != userEmail) {
                        chatVm.updateWithListing(listing: listing)
                        showChatView.toggle()
                    }
                } label: {
                    HStack(spacing: 15) {
                        Text("# \(String(listing.listingNumber))")
                            .font(.system(size: 20, weight: .semibold))
//                            .padding(.trailing, 6)

                        HStack(spacing: 3) {
                            Image(systemName: "flame")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.orange))
                            Text("\(listing.popularity)")
                        }

                        Text("x \(String(listing.availableQuantity))/\(String(listing.totalQuantity))")
                        
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.gray))
                            Text(listing.creatorUsername)
                        }

                        Spacer()
                        Text("$\(String(listing.price))")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.trailing, 6)
                    }
                    .foregroundColor(Color(.label))
                }
                Divider()
                    .padding(.vertical, 5)
            }
        }
    }
}

struct EventView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
