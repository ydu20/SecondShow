//
//  NotificationBanner.swift
//  SecondShow
//
//  Created by Alan on 11/16/23.
//

import SwiftUI

struct NotificationBanner: View {
    
    let bannerText: String
    let bannerColor: Color
    
    var body: some View {
        VStack {
            Text(bannerText)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 46)
                .padding(.vertical, 14)
                .background(bannerColor)
                .foregroundColor(.white)
                .font(.system(size: 18))
                .cornerRadius(10)
        }
        .padding()
    }
}

struct NotificationBanner_Previews: PreviewProvider {
    static var previews: some View {
        NotificationBanner(bannerText: "Hello", bannerColor: Color.green)
    }
}
