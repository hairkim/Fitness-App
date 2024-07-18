//
//  NotificationView.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/15/24.
//

import Foundation
import Combine
import FirebaseFirestore
import SwiftUI

struct NotificationView: View {
    @ObservedObject var notificationViewModel: NotificationViewModel
    
    var body: some View {
        List(notificationViewModel.notifications) { notification in
            Text(notification.type.rawValue)
        }
        .navigationTitle("Notifications")
    }
}

class NotificationViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var unreadNotificationsCount: Int = 0
    private let userStore: UserStore
    private var listener: ListenerRegistration?

    init(userStore: UserStore) {
        self.userStore = userStore
        listenForNotifications()
    }

    deinit {
        listener?.remove()
    }

    func listenForNotifications() {
        guard let currentUser = userStore.currentUser else {
            print("Current user is nil.")
            return
        }

        listener = NotificationManager.shared.addRealTimeListener(for: currentUser.userId) { [weak self] notifications in
            DispatchQueue.main.async {
                self?.notifications = notifications
                self?.unreadNotificationsCount = notifications.filter { !$0.isRead }.count
            }
        }
    }

    func acceptFollowRequest(from notification: Notification) async {
        guard let currentUser = userStore.currentUser else {
            print("Current user is nil.")
            return
        }

        do {
            try await UserManager.shared.acceptFollowRequest(senderId: notification.fromUserId, receiverId: currentUser.userId)
            if let notificationId = notification.id {
                try await NotificationManager.shared.removeNotification(notificationId)
            } else {
                print("Notification ID is nil.")
            }
        } catch {
            print("Error accepting follow request: \(error)")
        }
    }

    func declineFollowRequest(from notification: Notification) async {
        guard let currentUser = userStore.currentUser else {
            print("Current user is nil.")
            return
        }

        do {
            try await UserManager.shared.declineFollowRequest(senderId: notification.fromUserId, receiverId: currentUser.userId)
            if let notificationId = notification.id {
                try await NotificationManager.shared.removeNotification(notificationId)
            } else {
                print("Notification ID is nil.")
            }
        } catch {
            print("Error declining follow request: \(error)")
        }
    }

    func markNotificationAsRead(_ notification: Notification) async {
        guard let notificationId = notification.id else { return }
        do {
            try await NotificationManager.shared.markNotificationAsRead(notificationId)
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
}
