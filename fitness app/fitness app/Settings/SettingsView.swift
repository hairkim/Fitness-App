//
//  SettingsView.swift
//  fitnessapp
//
//  Created by Harris Kim on 3/31/24.
//

import SwiftUI



struct SettingsView: View {
    @EnvironmentObject var userStore: UserStore
    @StateObject private var viewModel: SettingsViewModel
    @Binding var showSignInView: Bool
    
    init(showSignInView: Binding<Bool>, userStore: UserStore) {
        self._showSignInView = showSignInView
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(userStore: userStore))
    }
    
    var body: some View {
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
                        print("Password has been reset")
                    } catch {
                        print(error)
                    }
                }
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
            } label : {
                Text("Delete account")
            }
        }
    }
}

#Preview {
    SettingsView(showSignInView: .constant(false), userStore: UserStore())
        .environmentObject(UserStore())
}
