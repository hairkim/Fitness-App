//
//  NotificationManager.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/15/24.
//


import Foundation
import Combine

class NotificationViewModel: ObservableObject {
    @Published var notifications: [(notification: Notification, user: DBUser?)] = []
    private let userStore: UserStore

    init(userStore: UserStore) {
        self.userStore = userStore
        fetchNotifications()
    }

    func fetchNotifications() {
        // Fetch notifications (follow requests, likes, comments)
        Task {
            var loadedNotifications: [(notification: Notification, user: DBUser?)] = []
            guard let currentUser = userStore.currentUser else { return }

            let notifications = try await NotificationManager.shared.getNotifications(for: currentUser.userId)

            for notification in notifications {
                let user = try? await UserManager.shared.getUser(userId: notification.fromUserId)
                loadedNotifications.append((notification, user))
            }
            
            DispatchQueue.main.async {
                self.notifications = loadedNotifications
            }
        }
    }

    func acceptFollowRequest(from userId: String) async {
        guard let currentUser = userStore.currentUser else { return }
        do {
            try await UserManager.shared.acceptFollowRequest(senderId: userId, receiverId: currentUser.userId)
            DispatchQueue.main.async {
                self.notifications.removeAll { $0.notification.fromUserId == userId && $0.notification.type == .followRequest }
            }
            try await UserManager.shared.updateUser(currentUser) // Refresh currentUser
        } catch {
            print("Error accepting follow request: \(error)")
        }
    }

    func declineFollowRequest(from userId: String) async {
        guard let currentUser = userStore.currentUser else { return }
        do {
            try await UserManager.shared.declineFollowRequest(senderId: userId, receiverId: currentUser.userId)
            DispatchQueue.main.async {
                self.notifications.removeAll { $0.notification.fromUserId == userId && $0.notification.type == .followRequest }
            }
            try await UserManager.shared.updateUser(currentUser) // Refresh currentUser
        } catch {
            print("Error declining follow request: \(error)")
        }
    }
}



import Foundation
import FirebaseFirestore

struct Notification: Identifiable, Codable {
    var id: String
    var type: NotificationType
    var fromUserId: String
    var postId: String?
    var timestamp: Date
    
    enum NotificationType: String, Codable {
        case followRequest
        case like
        case comment
    }
}

final class NotificationManager {
    
    static let shared = NotificationManager()
    private init() { }
    
    private let notificationsCollection = Firestore.firestore().collection("notifications")
    
    func getNotifications(for userId: String) async throws -> [Notification] {
        let snapshot = try await notificationsCollection.whereField("toUserId", isEqualTo: userId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Notification.self) }
    }
    
    func addNotification(_ notification: Notification, for userId: String) async throws {
        try notificationsCollection.document(notification.id).setData(from: notification, merge: true)
    }
}
