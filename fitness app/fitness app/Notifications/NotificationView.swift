//
//  NotificationView.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/15/24.
//

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var userStore: UserStore
    @StateObject private var viewModel: NotificationViewModel

    init(userStore: UserStore) {
        self._viewModel = StateObject(wrappedValue: NotificationViewModel(userStore: userStore))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notifications) { notification in
                    HStack {
                        Text(notification.fromUserId) // Replace with actual username retrieval
                        Spacer()
                        switch notification.type {
                        case .followRequest:
                            Button("Accept") {
                                Task {
                                    if let user = try? await UserManager.shared.getUser(userId: notification.fromUserId) {
                                        await viewModel.acceptFollowRequest(from: user)
                                    }
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            Button("Decline") {
                                Task {
                                    if let user = try? await UserManager.shared.getUser(userId: notification.fromUserId) {
                                        await viewModel.declineFollowRequest(from: user)
                                    }
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        case .like:
                            Text("liked your post")
                        case .comment:
                            Text("commented on your post")
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .onAppear {
                viewModel.fetchNotifications()
            }
        }
    }
}


struct NotificationUserView: View {
    let userId: String
    @State private var username: String = "Loading..."

    var body: some View {
        Text(username)
            .onAppear {
                Task {
                    if let user = try? await UserManager.shared.getUser(userId: userId) {
                        username = user.username
                    } else {
                        username = "Unknown user"
                    }
                }
            }
    }
}
