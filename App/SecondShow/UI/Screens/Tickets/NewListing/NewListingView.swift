//
//  NewListingView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI
import FirebaseFirestore

struct NewListingView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var vm: NewListingViewModel
    let notifyUser: (String, Color) -> ()

    
    init(mainTicketsVm: MainTicketsViewModel, eventService: EventService, listingService: ListingService, notifyUser: @escaping (String, Color) -> (), dismissView: @escaping () -> ()) {
        
        self.notifyUser = notifyUser

        _vm = StateObject(wrappedValue: NewListingViewModel(
            eventService: eventService,
            listingService: listingService,
            notifyUser: notifyUser,
            getEvents: {
                return mainTicketsVm.events
            },
            getEventDates: {
                return mainTicketsVm.eventDates
            },
            dismissView: dismissView
        ))
    }
    
    private func dismissPage() {
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        NavigationView {
            ZStack (alignment: .top) {
                
                inputForm
                formWarning
                if vm.showSuggestions, vm.suggestions.count > 0 {
                    suggestionsCover
                    suggestionsPanel
                }
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.createListing()
                    } label: {
                        Text("Post")
                    }
                }
            }
//            .onTapGesture {
//                self.hideKeyboard()
//            }
        }
    }
    
    private var suggestionsCover: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                vm.showSuggestions = false
            }
    }
    
    private var suggestionsPanel: some View {
        VStack {
            HStack {
                VStack {
                    ForEach(Array(vm.suggestions.enumerated()), id: \.offset) { index, suggestedEvent in
                        HStack {
                            Button {
                                vm.showSuggestions = false
                                vm.oneOffSuggestionDisable = true
                                vm.eventName = suggestedEvent.name
                                guard let nonOpDate = suggestedEvent.dateObj else {return}
                                vm.eventDate = nonOpDate
                            } label: {
                                Text(suggestedEvent.name)
                                    .foregroundColor(Color.black)
                            }
                            Spacer()
                        }

                        if index != vm.suggestions.count - 1 {
                            Divider()
                                .padding(.vertical, 2)
                        }
                    }
                    
                    
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .offset(y: 64)
        .transition(.opacity)
    }
    
    private var formWarning: some View {
        VStack {
            Text(vm.newListingWarning)
                .foregroundColor(Color(red: 0.8, green: 0, blue: 0))
        }
        .offset(y: 220)
    }
    
    private var inputForm: some View {
        Form {
            TextField("Event Name", text: $vm.eventName)
                .onChange(of: vm.eventName) {
                    vm.eventName = String($0.prefix(30))
                    if (!vm.oneOffSuggestionDisable) {
                        if (!vm.showSuggestions && vm.eventName.count >= 3) || (vm.showSuggestions && vm.eventName.count < 3) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                vm.showSuggestions.toggle()
                            }
                        }
                    } else {
                        vm.oneOffSuggestionDisable = false
                    }
                    
                    self.vm.updateSuggestions()
                }
                .textInputAutocapitalization(.words)
            
            DatePicker("Event Date", selection: $vm.eventDate, in: Date()..., displayedComponents: .date)
            
            Stepper("Number of tickets:  \(vm.quantity)", value: $vm.quantity, in: 1...10)
            HStack {
                Text("Price (per ticket)")
                Spacer()
                TextField("", text: $vm.price)
                    .frame(width: 46)
                    .frame(height: 30)
                    .multilineTextAlignment(.center)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.quaternaryLabel), lineWidth: 2)
                    )
                    .keyboardType(.numberPad)
                    .onChange(of: vm.price) {
                        vm.price = String($0.prefix(3)).filter{"0123456789".contains($0)}
                    }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct NewListingView_Previews: PreviewProvider {
    static var previews: some View {
//        TabBarView(
//            showLoginView: .constant(false),
//            selectedTab: .constant(0),
//            userService: UserService(),
//            eventService: EventService()
//        )
        EmptyView()
    }
}
