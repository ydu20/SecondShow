//
//  SoldPopupView.swift
//  SecondShow
//
//  Created by Alan on 11/19/23.
//

import SwiftUI
import FirebaseFirestore

struct SoldPopupView: View {
    
    @Binding var showPopupView: Bool
    @ObservedObject var vm: MyListingsViewModel
    let notifyUser: (String, Color) -> ()
    
    @State private var numSold: Double = 1
    
    var body: some View {
        VStack {
            if let listing = vm.selectedListing {
                    
                    if (listing.availableQuantity == 1) {
                        Text("Please confirm that you have sold your ticket")
                            .padding(.bottom, 20)
                    } else {
                        Text("How many tickets have you sold?")
                            .padding(.bottom, 15)
                        HStack {
                            Slider(
                                value: $numSold,
                                in: 1...Double(listing.availableQuantity),
                                step: 1
                            )
                            Text(String(Int(numSold)))
                        }
                        .onAppear {
                            numSold = Double(listing.availableQuantity)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                
            } else {
                Text("Error retrieving listing information")
                    .foregroundColor(Color(.red))
                    .padding(.bottom, 20)
            }
            
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showPopupView.toggle()
                    }
                } label: {
                    Text("Cancel")
                        .frame(height: 30)
                        .frame(width: 72)
                        .foregroundColor(Color(.systemRed))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemRed))
                        )
                }
                if vm.selectedListing != nil {
                    Spacer()
                    Button {
                        if vm.selectedListing != nil {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showPopupView.toggle()
                            }
                            vm.updateListing(numSold: Int(numSold))
                        }
                    } label: {
                        Text("Confirm")
                            .frame(height: 30)
                            .frame(width: 76)
                            .foregroundColor(Color(.systemGreen))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGreen))
                            )
                    }
                }

            }
            .padding(.horizontal, 50)
        }
        .frame(width: 300)
        .padding(.vertical, 30)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct SoldPopupView_Previews: PreviewProvider {
    static var previews: some View {
//        SoldPopupView(showPopupView: .constant(true), vm: MyListingsViewModel(), notifyUser: {msg, _ in print(msg)})
        EmptyView()
    }
}
