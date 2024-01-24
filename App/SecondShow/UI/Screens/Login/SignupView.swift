//
//  SignupView.swift
//  SecondShow
//
//  Created by Alan on 11/14/23.
//

import SwiftUI
import FirebaseFirestore

struct SignupView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm: LoginViewModel
    
    var body: some View {
        
        GeometryReader { _ in
            VStack(spacing: 20) {
                
                signupTitle
                registerForm
                
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.0000001))
            .onTapGesture {
                self.hideKeyboard()
            }
        }
        .alert(isPresented: $vm.showSignupCompleteAlert) {
            Alert(
                title: Text(ConfigManager.shared.requireVerification ? "Email Verification" : "Confirmation"),
                message: Text(ConfigManager.shared.requireVerification ? "Thank you for signing up! Please check your email for a verification link." : "Thanks for signing up! You can now login."),
                dismissButton: .default(Text("Close")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            vm.statusMessage = ""
        }

        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var registerForm: some View {
        VStack (spacing: 20) {
            Group {
                
                TextField("Username", text: $vm.signupUsername)
                    .font(.system(size: 18))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(height: 50)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color("SecondShowTertiary"), lineWidth: 1)
                    )
                
                TextField(ConfigManager.shared.requirePennEmail ? "UPenn Email" : "Email", text: $vm.signupEmail)
                    .font(.system(size: 18))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .frame(height: 50)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color("SecondShowTertiary"), lineWidth: 1)
                    )

                SecureField("Password", text: $vm.signupPassword)
                    .font(.system(size: 18))
                    .frame(height: 50)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color("SecondShowTertiary"), lineWidth: 1)
                    )
                
                SecureField("Confirm password", text: $vm.signupConfirmPassword)
                    .font(.system(size: 18))
                    .frame(height: 50)
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color("SecondShowTertiary"), lineWidth: 1)
                    )
            }
            .background(Color("SecondShowTextField"))
            .cornerRadius(10)
            
            Button {
                vm.createAccount()
            } label: {
                Text("Sign Up")
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(.white))
                    .background(Color("SecondShowMain"))
                    .cornerRadius(10)
            }
            .disabled(vm.disableSubmit)
            
            Text(vm.statusMessage)
                .foregroundColor(Color(red: 0.8, green: 0, blue: 0))
        }
    }
    
    private var signupTitle: some View {
        HStack {
            Text("Sign Up")
                .font(.system(size: 32, weight: .semibold))
            Spacer()
        }
        .padding(.bottom, 20)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(showLoginView: .constant(true), userService: UserService())
    }
}
