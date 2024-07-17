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

    init(userStore: UserStore) {
        self.userStore = userStore
        fetchNotifications()
    }

    func fetchNotifications() {
        guard let currentUser = userStore.currentUser else { return }
        
        NotificationManager.shared.getNotifications(for: currentUser.userId) { [weak self] notifications in
            DispatchQueue.main.async {
                self?.notifications = notifications
            }
        }
    }
    
    func acceptFollowRequest(from user: DBUser) async {
        guard let currentUser = userStore.currentUser else { return }
        do {
            try await UserManager.shared.acceptFollowRequest(senderId: user.userId, receiverId: currentUser.userId)
            DispatchQueue.main.async {
                self.notifications.removeAll { $0.fromUserId == user.userId && $0.type == .followRequest }
            }
            try await UserManager.shared.updateUser(currentUser) // Refresh currentUser
        } catch {
            print("Error accepting follow request: \(error)")
        }
    }

    func declineFollowRequest(from user: DBUser) async {
        guard let currentUser = userStore.currentUser else { return }
        do {
            try await UserManager.shared.declineFollowRequest(senderId: user.userId, receiverId: currentUser.userId)
            DispatchQueue.main.async {
                self.notifications.removeAll { $0.fromUserId == user.userId && $0.type == .followRequest }
            }
            try await UserManager.shared.updateUser(currentUser) // Refresh currentUser
        } catch {
            print("Error declining follow request: \(error)")
        }
    }
}

import Foundation
import FirebaseFirestoreSwift

struct Notification: Identifiable, Codable {
    var id: String
    var type: NotificationType
    var fromUserId: String
    var toUserId: String
    var postId: String?
    var timestamp: Date
    
    enum NotificationType: String, Codable {
        case followRequest
        case like
        case comment
    }
}

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class NotificationManager {
    
    static let shared = NotificationManager()
    private init() { }
    
    private let notificationsCollection = Firestore.firestore().collection("notifications")
    
    func getNotifications(for userId: String, completion: @escaping ([Notification]) -> Void) {
        notificationsCollection.whereField("toUserId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("No documents or there was an error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let notifications = documents.compactMap { try? $0.data(as: Notification.self) }
                completion(notifications)
            }
    }
    
    func addNotification(_ notification: Notification, for userId: String) async throws {
        try notificationsCollection.document(userId).setData(from: notification, merge: true)
    }
}

