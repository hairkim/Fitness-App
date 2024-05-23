//
//  UserStore.swift
//  fitnessapp
//
//  Created by Harris Kim on 5/23/24.
//

import Foundation
import SwiftUI
import Combine

class UserStore: ObservableObject {
    @Published var currentUser: DBUser?
    
    func setCurrentUser(user: DBUser) {
        self.currentUser = user
    }
    
    func clearCurrentUser() {
        self.currentUser = nil
    }
}
