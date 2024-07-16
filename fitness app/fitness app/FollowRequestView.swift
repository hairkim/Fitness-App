//
//  FollowRequestView.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/15/24.
//


import SwiftUI
import Combine

class FollowRequestViewModel: ObservableObject {
    @Published var followRequests: [DBUser] = []
    private let userStore: UserStore

    init(userStore: UserStore) {
        self.userStore = userStore
        fetchFollowRequests()
    }

    func fetchFollowRequests() {
        Task {
            guard let currentUser = userStore.currentUser else { return }
            let userRequests = currentUser.followRequests
            var loadedUsers: [DBUser] = []

            for userId in userRequests {
                if let user = try? await UserManager.shared.getUser(userId: userId) {
                    loadedUsers.append(user)
                }
            }

            DispatchQueue.main.async {
                self.followRequests = loadedUsers
            }
        }
    }

    func acceptFollowRequest(from user: DBUser) async {
        guard let currentUser = userStore.currentUser else { return }
        do {
            try await UserManager.shared.acceptFollowRequest(senderId: user.userId, receiverId: currentUser.userId)
            DispatchQueue.main.async {
                self.followRequests.removeAll { $0.userId == user.userId }
            }
            try await UserManager.shared.updateUser(currentUser) // Refresh currentUser
        } catch {
            print("Error accepting follow request: \(error)")
        }
    }

    func declineFollowRequest(from user: DBUser) async {
        guard let currentUser = userStore.currentUser else { return }
        do {
            try await UserManager.shared.declineFollowRequest(senderId: user.userId, receiverId: currentUser.userId)
            DispatchQueue.main.async {
                self.followRequests.removeAll { $0.userId == user.userId }
            }
            try await UserManager.shared.updateUser(currentUser) // Refresh currentUser
        } catch {
            print("Error declining follow request: \(error)")
        }
    }
}

import SwiftUI

struct FollowRequestView: View {
    @EnvironmentObject var userStore: UserStore
    @StateObject private var viewModel: FollowRequestViewModel

    init(userStore: UserStore) {
        self._viewModel = StateObject(wrappedValue: FollowRequestViewModel(userStore: userStore))
    }

    var body: some View {
        List {
            ForEach(viewModel.followRequests, id: \.self) { user in
                HStack {
                    Text(user.username)
                    Spacer()
                    Button("Accept") {
                        Task {
                            await viewModel.acceptFollowRequest(from: user)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    Button("Decline") {
                        Task {
                            await viewModel.declineFollowRequest(from: user)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .onAppear {
            viewModel.fetchFollowRequests()
        }
    }
}

struct FollowRequestView_Previews: PreviewProvider {
    static var previews: some View {
        FollowRequestView(userStore: UserStore())
            .environmentObject(UserStore())
    }
}
