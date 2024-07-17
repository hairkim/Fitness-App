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
        _viewModel = StateObject(wrappedValue: NotificationViewModel(userStore: userStore))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notifications) { notification in
                    HStack {
                        NotificationUserView(userId: notification.fromUserId)
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
                        case .follow:
                            Text("started following you")
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .onAppear {
                Task {
                    await viewModel.fetchNotifications()
                }
            }
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView(userStore: UserStore())
            .environmentObject(UserStore())
    }
}



import SwiftUI

struct NotificationUserView: View {
    let userId: String
    @State private var username: String = "Loading..."
    @State private var profilePictureUrl: String?

    var body: some View {
        HStack {
            if let url = profilePictureUrl, let imageUrl = URL(string: url) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                    @unknown default:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .clipShape(Circle())
                .frame(width: 40, height: 40)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
            }
            Text(username)
        }
        .onAppear {
            Task {
                if let user = try? await UserManager.shared.getUser(userId: userId) {
                    username = user.username
                    profilePictureUrl = user.photoUrl
                } else {
                    username = "Unknown user"
                }
            }
        }
    }
}
