//
//  SoldPopupView.swift
//  SecondShow
//
//  Created by Alan on 11/19/23.
//

import SwiftUI

struct SoldPopupView: View {
    
    @Binding var showPopupView: Bool
    let listing: Listing?
    
    @State private var numSold: Double = 1
    
    var body: some View {
        VStack {

            if let listing = self.listing {
                    
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
                    showPopupView.toggle()
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
                if listing != nil {
                    Spacer()
                    Button {
                        if listing != nil {
                            // TODO

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
        .shadow(radius: 5)
        
    }
}

struct SoldPopupView_Previews: PreviewProvider {
    static var previews: some View {
        SoldPopupView(showPopupView: .constant(true), listing: Listing(eventId: "testtesttest", eventName: "Test Event", eventDate: "11-26-2023", listingNumber: 1, price: 15, totalQuantity: 4, availableQuantity: 1, popularity: 14, createTime: Date()))
        
        SoldPopupView(showPopupView: .constant(true), listing: nil)
    }
}
