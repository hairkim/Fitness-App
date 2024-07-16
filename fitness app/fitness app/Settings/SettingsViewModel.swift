//
//  SettingsViewModel.swift
//  fitnessapp
//
//  Created by Joshua Kim on 4/18/24.
//

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    private let userStore: UserStore
    
    init(userStore: UserStore) {
        self.userStore = userStore
    }
    
    func logOut() throws {
        try AuthenticationManager.shared.logOut()
        print("clearing current user")
        userStore.clearCurrentUser()
    }
    
    func deleteAccount() async throws {
        try await AuthenticationManager.shared.delete()
        userStore.clearCurrentUser()
    }
    
    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        let email = authUser.email
        
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
    
    func togglePrivacy() async throws {
        guard var currentUser = userStore.currentUser else { return }
        currentUser.isPublic.toggle()
        try await UserManager.shared.updateUser(currentUser)
        userStore.setCurrentUser(user: currentUser) // Update the userStore with the modified user
    }
}
