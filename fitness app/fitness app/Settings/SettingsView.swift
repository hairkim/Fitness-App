//
//  SettingsView.swift
//  fitnessapp
//
//  Created by Harris Kim on 3/31/24.
//

import SwiftUI
import Foundation

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userStore: UserStore
    @StateObject private var viewModel: SettingsViewModel
    @Binding var showSignInView: Bool
    @State private var resetPasswordMessage: AlertMessage?
    
    init(showSignInView: Binding<Bool>, userStore: UserStore) {
        self._showSignInView = showSignInView
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(userStore: userStore))
    }
    
    var body: some View {
        NavigationView {
            List {
                if let currentUser = userStore.currentUser {
                    Text(currentUser.username)
                } else {
                    Text("No user logged in")
                }
                
                Button("Log out") {
                    Task {
                        do {
                            try viewModel.logOut()
                            showSignInView = true
                        } catch {
                            print(error)
                        }
                    }
                }
                
                Button("Reset Password") {
                    Task {
                        do {
                            try await viewModel.resetPassword()
                            resetPasswordMessage = AlertMessage(message: "Password reset email sent")
                        } catch {
                            resetPasswordMessage = AlertMessage(message: "Failed to send password reset email: \(error.localizedDescription)")
                        }
                    }
                }
                .alert(item: $resetPasswordMessage) { message in
                    Alert(title: Text("Password Reset"), message: Text(message.message), dismissButton: .default(Text("OK")))
                }
                
                Button(role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteAccount()
                            showSignInView = true
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("Delete account")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(showSignInView: .constant(false), userStore: UserStore())
            .environmentObject(UserStore())
    }
}
