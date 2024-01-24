//
//  BackgroundRefreshManager.swift
//  SecondShow
//
//  Created by Alan on 1/12/24.
//

import Foundation


class BackgroundRefreshManager {
    
    var ticketsVm: MainTicketsViewModel?
    var messagesVm: MainMessagesViewModel?
    var myListingsVm: MyListingsViewModel?
    var profileVm: ProfileViewModel?
    
    static let shared = BackgroundRefreshManager()
}
