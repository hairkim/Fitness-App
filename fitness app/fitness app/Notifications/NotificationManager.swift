//
//  NotificationManager.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/15/24.
//

import Foundation
import Combine

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

    func listenForNotifications() {
        guard let currentUser = userStore.currentUser else {
            print("Current user is nil.")
            return
        }
        
        listener = NotificationManager.shared.addRealTimeListener(for: currentUser.userId) { [weak self] notifications in
            DispatchQueue.main.async {
                self?.notifications = notifications
                print("Received Notifications: \(notifications)")
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
}



import Foundation
import FirebaseFirestoreSwift

struct Notification: Codable, Identifiable {
    @DocumentID var id: String?
    let type: NotificationType
    let fromUserId: String
    let postId: String?
    let toUserId: String
    let timestamp: Date
    
    enum NotificationType: String, Codable {
        case like
        case comment
        case followRequest
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
    
    /// Fetches notifications for a given user asynchronously.
    func getNotifications(for userId: String) async throws -> [Notification] {
        let snapshot = try await notificationsCollection.whereField("toUserId", isEqualTo: userId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Notification.self) }
    }
    
    /// Adds a notification document to Firestore.
    func addNotification(_ notification: Notification) async throws {
        try await notificationsCollection.addDocument(from: notification)
    }
    
    /// Removes a notification document from Firestore.
    func removeNotification(_ notificationId: String) async throws {
        try await notificationsCollection.document(notificationId).delete()
    }
    
    /// Sets up a real-time listener for notifications targeting a specific user.
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
}
