//
//  ProfileView.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct ProfileView: View {
    
    @Binding var showLoginView: Bool
    
    @State private var showOptionsMenu = false;
    @State private var showErrorMessage = false;
    @State private var errorMessage = ""
    
    @State private var isAlerts = false
    @State private var textFieldInput = ""
        
    var body: some View {
        VStack {
            NavBar(
                title: "Me",
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
        
        .alert(isPresented: $showErrorMessage) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Close")) {errorMessage = ""}
            )
        }
    }
    
//    private func fetchCurrentUser() {
        
//        guard let currentUser = FirebaseManager.shared.currentUser else {
//            self.errorMessage = "Not logged in"
//            self.showErrorMessage.toggle()
//            return
//        }
        
        
        
//        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
//            self.errorMessage = "Not logged in"
//            self.showErrorMessage.toggle()
//            return
//        }
//
//        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { result, err in
//            if let err = err {
//                self.errorMessage = err.localizedDescription
//                self.showErrorMessage.toggle()
//                return
//            }
//
//            if let user = try? result?.data(as: User.self) {
//                FirebaseManager.shared.currentUser = user
//            }
//        }
//    }
    
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

            TextEditor(text:$textFieldInput)
                .overlay(
                    RoundedRectangle(cornerRadius: 8) // Use RoundedRectangle for rounded corners
                        .stroke(Color(.secondarySystemFill), lineWidth: 1)
                )
                .padding(.bottom, 10)
            
            Button {
                //TODO
                
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
            ForEach(0..<2, id: \.self) { num in
                HStack {
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Concert Show")
                                .font(.system(size: 20, weight: .bold))
                            HStack(spacing: 12) {
                                Text("Nov. 16")
                                    .font(.system(size: 15))
                            }
                        }
                        Spacer()
                        Button {
                            // TODO
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
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
//        ProfileView()
        TabBarView(showLoginView: .constant(false), selectedTab: .constant(3))
    }
}
