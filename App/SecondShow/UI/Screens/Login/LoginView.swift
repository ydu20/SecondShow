//
//  LoginView.swift
//  SecondShow
//
//  Created by Alan on 11/14/23.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    
    @Binding var showLoginView: Bool
    @StateObject private var vm: LoginViewModel
    
    init(showLoginView: Binding<Bool>, userService: UserService) {
        self._showLoginView = showLoginView
        _vm = StateObject(wrappedValue: LoginViewModel(userService: userService))
    }
    
    var body: some View {
        NavigationView {
            
            GeometryReader { _ in
                VStack(spacing: 20) {
                    
                    topBar
                    logoDisplay
                    loginForm
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onAppear {
                vm.statusMessage = ""
            }
        }
        
    }
    
    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                vm.showSignupView.toggle()
            } label: {
                Text("Sign Up")
            }
        }
    }
    
    private var loginForm: some View {
        VStack (spacing: 20) {
            Group {
                TextField("Email", text: $vm.loginEmail)
                    .font(.system(size: 18))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .frame(height: 50)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color("SecondShowTertiary"), lineWidth: 1)
                    )
                    .background(Color("SecondShowTextField"))
                
                SecureField("Password", text: $vm.loginPassword)
                    .font(.system(size: 18))
                    .frame(height: 50)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color("SecondShowTertiary"), lineWidth: 1)
                    )
                    .background(Color("SecondShowTextField"))
            }
            .background(Color.white)
            .cornerRadius(10)
            
            Button {
                dismissKeyboard()
                vm.loginUser(onSuccess: {
                    showLoginView.toggle()
                })
            } label: {
                Text("Log in")
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(.white))
                    .background(Color("SecondShowMain"))
                    .cornerRadius(10)
            }
            .disabled(vm.disableSubmit)
            
            Text(vm.statusMessage)
                .foregroundColor(Color(red: 0.8, green: 0, blue: 0))
            
            NavigationLink(destination: SignupView(vm: vm), isActive: $vm.showSignupView) {
                EmptyView()
            }
            .hidden()
        }
    }
    
    private var logoDisplay: some View {
        VStack (spacing: 20) {
            Text("Second Show")
                .font(.system(size: 38, weight: .bold))
                .padding(.top, 25)
            Text("Your second chance at that show")
                .font(.system(size: 16, weight: .thin))
                .padding(.top, 5)
                .padding(.bottom, 26)
        }
    }
}

extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(showLoginView: .constant(true), userService: UserService())
//        RootView()
    }
}
