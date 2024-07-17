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
        List {
            ForEach(viewModel.notifications) { notification in
                HStack {
                    Text(notification.fromUserId) // Placeholder, replace with actual username fetching logic
                    Spacer()
                    switch notification.type {
                    case .followRequest:
                        Button("Accept") {
                            Task {
                                await viewModel.acceptFollowRequest(from: notification)
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        Button("Decline") {
                            Task {
                                await viewModel.declineFollowRequest(from: notification)
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    case .like:
                        Text("liked your post")
                    case .comment:
                        Text("commented on your post")
                    case .newFollower:
                        Text("started following you")
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

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView(userStore: UserStore())
            .environmentObject(UserStore())
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
