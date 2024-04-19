//
//  SettingsViewModel.swift
//  fitnessapp
//
//  Created by Joshua Kim on 4/18/24.
//

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    func logOut() throws {
        try AuthenticationManager.shared.logOut()
    }
    
    func deleteAccount() async throws {
        try await AuthenticationManager.shared.delete()
    }
    
    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let email = authUser.email else {
            throw URLError(.fileDoesNotExist)
        }
        
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
}
