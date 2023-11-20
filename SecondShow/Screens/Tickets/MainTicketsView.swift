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
    
    @StateObject private var vm = MainTicketsViewModel()
    var eventVm = EventViewModel(event: nil)
    
    var body: some View {
        NavigationStack {
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
                showsList
            }
            .padding()
            .sheet(isPresented: $showNewListingView) {
                NewListingView(notifyUser: notifyUser)
            }
            .navigationDestination(isPresented: $showEventView, destination: {
                EventView(vm: eventVm)
            })
            .environmentObject(vm)
        }
    }
    
    private var showsList: some View {
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
        }
    }
    
}

struct MainTicketsView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(showLoginView: .constant(false), selectedTab: .constant(0))
        TabBarView(showLoginView: .constant(false), selectedTab: .constant(0))
            .preferredColorScheme(.dark)
        
    }
}
