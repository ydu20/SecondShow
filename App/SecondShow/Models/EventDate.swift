//
//  Date.swift
//  SecondShow
//
//  Created by Alan on 11/16/23.
//

import Foundation

struct EventDate: Identifiable {
    
    var id: String {date}
    var date: String
    var events: [Event]
    
    var dateMMMMdd: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let dateObj = formatter.date(from: date)
        if let dateObj = dateObj {
            formatter.dateFormat = "MMMM dd"
            return formatter.string(from: dateObj)
        } else {
            return "ERROR DATE"
        }
    }
}
