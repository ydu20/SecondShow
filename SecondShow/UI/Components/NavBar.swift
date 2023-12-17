//
//  NavBar.swift
//  SecondShow
//
//  Created by Alan on 11/13/23.
//

import SwiftUI

struct NavBar<Label: View>: View {
    
    let title: String
    let subtitle: String?
    let buttonLabel: (() -> Label)?
    let buttonAction: (() -> Void)?
    
    init(title: String, subtitle: String?) {
        self.title = title
        self.subtitle = subtitle
        self.buttonLabel = nil
        self.buttonAction = nil
    }
    
    init(title: String, subtitle: String?, @ViewBuilder buttonLabel: @escaping () -> Label, buttonAction: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.buttonLabel = buttonLabel
        self.buttonAction = buttonAction
    }
    
    
    var body: some View {
        HStack(spacing: 16) {
            VStack (alignment: .leading) {
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                Text(subtitle ?? "")
                    .font(.system(size: 12, weight: .light))
            }
            Spacer()
            if let buttonLabel = buttonLabel, let buttonAction = buttonAction {
                Button(action: buttonAction, label: buttonLabel)
            }
        }
    }
}

struct NavBar_Previews: PreviewProvider {
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
