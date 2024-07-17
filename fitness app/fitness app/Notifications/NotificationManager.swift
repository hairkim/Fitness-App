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
    private var listener: ListenerRegistration?

    init(userStore: UserStore) {
        self.userStore = userStore
        listenForNotifications()
    }

    deinit {
        listener?.remove()
    }

    func fetchNotifications() async {
        guard let currentUser = userStore.currentUser else { return }
        do {
            let notifications = try await NotificationManager.shared.getNotifications(for: currentUser.userId)
            DispatchQueue.main.async {
                self.notifications = notifications
            }
        } catch {
            print("Error fetching notifications: \(error)")
        }
    }

    func listenForNotifications() {
        guard let currentUser = userStore.currentUser else { return }
        NotificationManager.shared.addRealTimeListener(for: currentUser.userId) { notifications in
            DispatchQueue.main.async {
                self.notifications = notifications
            }
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

struct Notification: Identifiable, Codable {
    var id: String?
    var type: NotificationType
    var fromUserId: String
    var postId: String?
    var timestamp: Date
    
    enum NotificationType: String, Codable {
        case followRequest
        case like
        case comment
        case follow
    }
}


import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class NotificationManager {
    
    static let shared = NotificationManager()
    private init() { }
    
    private let notificationsCollection = Firestore.firestore().collection("notifications")
    
    func getNotifications(for userId: String) async throws -> [Notification] {
        let snapshot = try await notificationsCollection.whereField("toUserId", isEqualTo: userId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Notification.self) }
    }
    
    func addNotification(_ notification: Notification, for userId: String) async throws {
        var notification = notification
        notification.id = notificationsCollection.document().documentID
        try await notificationsCollection.document(notification.id!).setData(from: notification)
    }
    
    func removeNotification(_ notificationId: String) async throws {
        try await notificationsCollection.document(notificationId).delete()
    }
    
    func addRealTimeListener(for userId: String, completion: @escaping ([Notification]) -> Void) {
        notificationsCollection.whereField("toUserId", isEqualTo: userId)
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
}
