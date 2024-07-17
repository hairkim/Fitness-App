//
//  NotificationManager.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/15/24.
//


import Foundation
import Combine
import FirebaseFirestore

class NotificationViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    private let userStore: UserStore
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init(userStore: UserStore) {
        self.userStore = userStore
        fetchNotifications()
    }

    deinit {
        listener?.remove()
    }

    func fetchNotifications() {
        guard let currentUser = userStore.currentUser else { return }
        listener = db.collection("notifications")
            .whereField("toUserId", isEqualTo: currentUser.userId)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching notifications: \(error)")
                    return
                }
                guard let documents = querySnapshot?.documents else { return }
                self.notifications = documents.compactMap { try? $0.data(as: Notification.self) }
            }
    }

    func acceptFollowRequest(from notification: Notification) async {
        guard let currentUser = userStore.currentUser else { return }
        do {
            try await UserManager.shared.acceptFollowRequest(senderId: notification.fromUserId, receiverId: currentUser.userId)
            try await NotificationManager.shared.removeNotification(notification.id ?? "")
        } catch {
            print("Error accepting follow request: \(error)")
        }
    }

    func declineFollowRequest(from notification: Notification) async {
        guard let currentUser = userStore.currentUser else { return }
        do {
            try await UserManager.shared.declineFollowRequest(senderId: notification.fromUserId, receiverId: currentUser.userId)
            try await NotificationManager.shared.removeNotification(notification.id ?? "")
        } catch {
            print("Error declining follow request: \(error)")
        }
    }
}

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Notification: Identifiable, Codable {
    @DocumentID var id: String?
    var type: NotificationType
    var fromUserId: String
    var toUserId: String
    var postId: String?
    var timestamp: Date

    enum NotificationType: String, Codable {
        case followRequest
        case like
        case comment
        case newFollower
    }
}

import Foundation
import FirebaseFirestore

final class NotificationManager {
    
    static let shared = NotificationManager()
    private init() { }
    
    private let notificationsCollection = Firestore.firestore().collection("notifications")
    
    func getNotifications(for userId: String) async throws -> [Notification] {
        let snapshot = try await notificationsCollection.whereField("toUserId", isEqualTo: userId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Notification.self) }
    }
    
    func addNotification(_ notification: Notification) async throws {
        try notificationsCollection.addDocument(from: notification)
    }

    func removeNotification(_ notificationId: String) async throws {
        try await notificationsCollection.document(notificationId).delete()
    }
}
