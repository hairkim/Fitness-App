//
//  UserManager.swift
//  fitnessapp
//
//  Created by Harris Kim on 3/26/24.
//

import Foundation

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var username: String?

    private init() {}

    func login(username: String) {
        self.username = username
    }

    func logout() {
        self.username = nil
    }
}
