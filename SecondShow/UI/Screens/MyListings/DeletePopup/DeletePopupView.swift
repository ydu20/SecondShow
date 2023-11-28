//
//  DeletePopupView.swift
//  SecondShow
//
//  Created by Alan on 11/20/23.
//

import SwiftUI
import FirebaseFirestore

struct DeletePopupView: View {
    
    @Binding var showPopupView: Bool
    @ObservedObject var vm: MyListingsViewModel
    let notifyUser: (String, Color) -> ()
    
    var body: some View {
        VStack {
            if vm.selectedListing != nil {
                Text("Are you sure you want to delete this listing?")
                    .padding(.bottom, 20)
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
                        .foregroundColor(Color(.secondaryLabel))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.secondaryLabel))
                        )
                }
                if vm.selectedListing != nil {
                    Spacer()
                    Button {
                        if vm.selectedListing != nil {
                            // TODO
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showPopupView.toggle()
                            }
                            vm.deleteListing()
                        }
                    } label: {
                        Text("Delete")
                            .frame(height: 30)
                            .frame(width: 76)
                            .foregroundColor(Color(.systemRed))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemRed))
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

struct DeletePopupView_Previews: PreviewProvider {
    static var previews: some View {
        DeletePopupView(showPopupView: .constant(true), vm: MyListingsViewModel(), notifyUser: {msg, _ in print(msg)})
    }
}
