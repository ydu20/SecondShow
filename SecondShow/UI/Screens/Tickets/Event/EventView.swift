//
//  EventView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct EventView: View {
    
    @StateObject var vm: EventViewModel
    var chatVm: ChatViewModel
    
    @State private var showChatView = false
    
    var body: some View {
        VStack {
            if self.vm.listings.count == 0 {
                Text("No listings for this event currently.")
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
                        .foregroundColor(self.vm.eventAlerts ? Color(.systemBlue) : Color(.secondaryLabel))
                }
            }
        }
        .padding()
        .onDisappear {
            if (!showChatView) {
                vm.listingListener?.remove()
            }
        }
    }
    
    private var listingsView: some View {
        ScrollView {
            ForEach(self.vm.listings) { listing in
                Button {
                    guard let userEmail = FirebaseManager.shared.currentUser?.email else {return}
                    
                    if (listing.creator != userEmail) {
                        chatVm.updateWithListing(listing: listing)
                        showChatView.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("# \(String(listing.listingNumber))")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.trailing, 6)

                        HStack(spacing: 3) {
                            Image(systemName: "flame")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.orange))
                            Text("\(listing.popularity)")
                        }

                        Text("x \(String(listing.availableQuantity))/\(String(listing.totalQuantity))")

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
        TabBarView(
            showLoginView: .constant(false),
            selectedTab: .constant(0),
            userService: UserService(),
            eventService: EventService()
        )
    }
}
