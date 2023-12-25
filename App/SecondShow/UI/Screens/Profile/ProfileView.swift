//
//  ProfileView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct ProfileView: View {
    
    
    @Binding var showLoginView: Bool
    @StateObject private var vm: ProfileViewModel
    
    @State private var showOptionsMenu = false;
    @State private var isAlerts = true

    init(showLoginView: Binding<Bool>, eventService: EventService, userService: UserService, notifyUser: @escaping (String, Color) -> ()) {
        _showLoginView = showLoginView
        _vm = StateObject(wrappedValue: ProfileViewModel(eventService: eventService, userService: userService, notifyUser: notifyUser))
    }
    
    var body: some View {
        VStack {
            NavBar(
                title: "\(FirebaseManager.shared.currentUser?.username ?? "")",
                subtitle: "User since \(FirebaseManager.shared.currentUser?.createDateString ?? "")",
                buttonLabel: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(Color(.label))
                },
                buttonAction: {
                    showOptionsMenu.toggle()
                }
            )
            .confirmationDialog("Settings", isPresented: $showOptionsMenu) {
                Button ("Log Out", role: .destructive) {
                    handleLogout()
                }
                Button ("Cancel", role: .cancel) {}
            } message: {
                Text("Settings")
            }
            
            Picker(selection: $isAlerts, label: EmptyView()) {
                Text("Alerts")
                    .tag(true)
                Text("Feedback")
                    .tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 10)

            if isAlerts {
                alertsList
            } else {
                feedbackForm
            }
            Spacer()
        }
        .padding()
        .onAppear {
            vm.fetchMyAlerts()
        }
        .onDisappear() {
            vm.removeListener()
        }
    }
    
    private func handleLogout() {
        try? FirebaseManager.shared.auth.signOut()
        FirebaseManager.shared.currentUser = nil
        showLoginView.toggle()
    }
    
    private var feedbackForm: some View {
        VStack (alignment: .leading){
            
            Text("Feedback / Bugs")
                .font(.system(size: 24, weight: .bold))
                .padding(.bottom, 10)

            TextEditor(text: $vm.feedbackInput)
                .overlay(
                    RoundedRectangle(cornerRadius: 8) // Use RoundedRectangle for rounded corners
                        .stroke(Color(.secondarySystemFill), lineWidth: 1)
                )
                .padding(.bottom, 10)
            
            HStack {
                Spacer()
                Text(vm.feedbackStatusMsg)
                    .foregroundColor(
                        vm.feedbackError ? Color(red: 0.8, green: 0, blue: 0) : Color(red: 0, green: 0.4, blue: 0)
                    )
                    .onDisappear {
                        vm.feedbackStatusMsg = ""
                    }
                Spacer()
            }
            
            Button {
                vm.submitFeedback()
            } label: {
                Text("Submit")
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(.white))
                    .background(Color(.systemBlue))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var alertsList: some View {
        ScrollView {
            if vm.myAlerts.count > 0 {
                ForEach(vm.myAlerts) { event in
                    HStack {
                        HStack(spacing: 15) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(event.name)
                                    .font(.system(size: 20, weight: .bold))
                                HStack(spacing: 12) {
                                    Text(event.dateMMMdd)
                                        .font(.system(size: 15))
                                }
                            }
                            Spacer()
                            Button {
                                vm.deregisterAlert(event: event)
                            } label: {
                                VStack {
                                    Circle()
                                        .fill(Color(.white))
                                        .frame(width: 23, height: 23)
                                        .overlay(
                                            Image(systemName: "x.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(Color(.systemRed))
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
            else {
                Text("Go to an event page to add an alert")
                    .padding(.top, 40)
            }
        }
        .onAppear {
            vm.fetchMyAlerts()
        }
        .onDisappear {
            vm.eventListener?.remove()
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
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