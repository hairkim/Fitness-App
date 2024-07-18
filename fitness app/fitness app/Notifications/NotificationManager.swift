//
//  NotificationManager.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/15/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Notification: Codable, Identifiable {
    @DocumentID var id: String? = UUID().uuidString
    let type: NotificationType
    let fromUserId: String
    let postId: String?
    let toUserId: String
    let timestamp: Date
    var isRead: Bool = false
}

enum NotificationType: String, Codable {
    case follow
    case followRequest
    case like
    case comment
}

final class NotificationManager {
    static let shared = NotificationManager()
    private init() { }

    private let notificationsCollection = Firestore.firestore().collection("notifications")

    func getNotifications(for userId: String) async throws -> [Notification] {
        let snapshot = try await notificationsCollection.whereField("toUserId", isEqualTo: userId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Notification.self) }
    }

    func addNotification(_ notification: Notification) async throws {
        try await notificationsCollection.addDocument(from: notification)
    }

    func removeNotification(_ notificationId: String) async throws {
        try await notificationsCollection.document(notificationId).delete()
    }

    func addRealTimeListener(for userId: String, completion: @escaping ([Notification]) -> Void) -> ListenerRegistration {
        return notificationsCollection.whereField("toUserId", isEqualTo: userId)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching notifications: \(error)")
                    return
                }
                guard let documents = querySnapshot?.documents else { return }
                let notifications = documents.compactMap { try? $0.data(as: Notification.self) }
                completion(notifications)
            }
    }

    func markNotificationAsRead(_ notificationId: String) async throws {
        let notificationRef = notificationsCollection.document(notificationId)
        try await notificationRef.updateData(["isRead": true])
    }
}
