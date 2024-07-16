//
//  NotificationView.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/15/24.
//

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var userStore: UserStore
    @Binding var showNotificationView: Bool
    @StateObject private var viewModel: NotificationViewModel

    init(userStore: UserStore, showNotificationView: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: NotificationViewModel(userStore: userStore))
        self._showNotificationView = showNotificationView
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notifications, id: \.notification.id) { (notification, user) in
                    HStack {
                        if let user = user {
                            Text(user.username)
                        } else {
                            Text("Unknown user")
                        }
                        Spacer()
                        switch notification.type {
                        case .followRequest:
                            Button("Accept") {
                                Task {
                                    await viewModel.acceptFollowRequest(from: notification.fromUserId)
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            Button("Decline") {
                                Task {
                                    await viewModel.declineFollowRequest(from: notification.fromUserId)
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
            .navigationBarItems(leading: Button(action: {
                showNotificationView = false
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            })
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
