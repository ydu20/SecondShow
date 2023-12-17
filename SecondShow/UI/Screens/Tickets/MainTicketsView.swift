//
//  MainTicketsView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI
import Firebase

struct MainTicketsView: View {

    let notifyUser: (String, Color) -> ()
    
    @State private var showNewListingView = false
    @State private var showEventView = false
    
    @StateObject private var vm: MainTicketsViewModel
    var eventVm: EventViewModel
    var chatVm: ChatViewModel
    
    private let eventService: EventService
    private let listingService: ListingService
    
    init(notifyUser: @escaping (String, Color) -> Void, chatVm: ChatViewModel, eventService: EventService, listingService: ListingService) {
        self.notifyUser = notifyUser
        _vm = StateObject(wrappedValue: MainTicketsViewModel(eventService: eventService))
        self.eventVm = EventViewModel(
            eventService: eventService,
            notifyUser: notifyUser,
            updateChatOnRemoval: {listingId, creator, deleted in
                if listingId == chatVm.listingId, creator == chatVm.counterpartyEmail {
                    if deleted {
                        chatVm.deleted = true
                    } else {
                        chatVm.sold = true
                    }
                }
            }
        )
        self.chatVm = chatVm
        self.eventService = eventService
        self.listingService = listingService
    }
    
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
                buttonAction: {
                    showNewListingView.toggle()
                }
            )
            .padding(.horizontal)

            if self.vm.eventDates.count == 0 {
                Text("No events currently. Post a listing to create an event!")
                    .padding(.top, 200)
                Spacer()
            } else {
                eventsList
            }
            
            NavigationLink(destination: EventView(vm: eventVm, chatVm: chatVm), isActive: $showEventView) {
                EmptyView()
            }
            .hidden()
        }
        .sheet(isPresented: $showNewListingView) {
            NewListingView(
                mainTicketsVm: vm,
                eventService: eventService,
                listingService: listingService,
                notifyUser: notifyUser,
                dismissView: {
                    showNewListingView = false;
                }
            )
                .environmentObject(vm)
        }
        .padding(.vertical)
    }
    
    private var eventsList: some View {
        ScrollView {
            ForEach(vm.eventDates) { eventDate in
                HStack(spacing: 16) {
                    Text(eventDate.dateMMMMdd)
                        .font(.system(size: 22, weight: .semibold))
                    Spacer()
                }
                Divider()
                    .padding(.vertical, 4)
                
                ForEach(eventDate.events) { event in
                    Button {
                        // TODO
                        self.eventVm.setEvent(event: event)
                        self.eventVm.fetchListings()
                        showEventView.toggle()
                    } label: {
                        HStack(spacing: 16) {
                            Text(event.name)
                                .font(.system(size: 20))
                                .foregroundColor(Color(.label))
                            Spacer()
                            Circle()
                                .fill(Color(.systemBlue))
                                .frame(width: 25, height: 25)
                                .overlay(
                                    Text(String(event.listingCount))
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(.white))
                                )
                        }
                    }
                    Divider()
                        .padding(.vertical, 4)
                }
            }
            .padding(.horizontal)
        }
    }
    
}

struct MainTicketsView_Previews: PreviewProvider {
    static var previews: some View {
//        TabBarView(
//            showLoginView: .constant(false),
//            selectedTab: .constant(0),
//            userService: UserService(),
//            eventService: EventService()
//        )
//        TabBarView(
//            showLoginView: .constant(false),
//            selectedTab: .constant(0),
//            userService: UserService(),
//            eventService: EventService()
//        )
//            .preferredColorScheme(.dark)
        EmptyView()
    }
}
