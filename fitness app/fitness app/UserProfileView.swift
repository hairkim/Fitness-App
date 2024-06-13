//
//  UserProfileView.swift
//  fitnessapp
//
//  Created by Harris Kim on 6/5/24.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var userStore: UserStore
    
    let postUser: DBUser
    
    var body: some View {
        Text(postUser.username)
        Button(action: {
            Task {
                await addFollower()
            }
        }) {
            Text("follow")
        }
    }
    
    private func addFollower() async {
            guard let currentUser = userStore.currentUser else {
                print("Current user is nil")
                return
            }
            do {
                try await UserManager.shared.addFollower(sender: currentUser, receiver: postUser)
                print("Follower added successfully")
            } catch {
                print("Error adding follower: \(error.localizedDescription)")
            }
        }
}

#Preview {
    let mockUser = MockUser(uid: "12kjksdfj", email: "mockUser@gmail.com", photoURL: nil)
    let authResultModel = AuthenticationManager.shared.createMockUser(mockUser: mockUser)
    return UserProfileView(postUser: DBUser(auth: authResultModel, username: "mock user"))
}
