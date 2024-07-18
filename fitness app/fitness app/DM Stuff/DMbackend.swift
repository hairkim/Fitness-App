//
//  DMbackend.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/12/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import UserNotifications
import FirebaseStorage
import UIKit

struct DBChat: Codable, Identifiable {
    @DocumentID var id: String?
    let participants: [String]
    let participantNames: [String: String]
    var lastMessage: String?
    var timestamp: Timestamp
    var unreadMessages: [String: Int]
    var profileImage: String?

    init(id: String? = nil, participants: [String], participantNames: [String: String], lastMessage: String? = nil, timestamp: Timestamp = Timestamp(), unreadMessages: [String: Int] = [:], profileImage: String? = nil) {
        self.id = id
        self.participants = participants
        self.participantNames = participantNames
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.unreadMessages = unreadMessages
        self.profileImage = profileImage
    }
}

struct DBMessage: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let chatId: String
    let senderId: String
    let receiverId: String
    let text: String
    let timestamp: Timestamp
    var isRead: Bool
    var imageURL: String?
    var linkURL: String? // New property for storing link URLs

    init(chatId: String, senderId: String, receiverId: String, text: String, timestamp: Timestamp = Timestamp(), isRead: Bool = false, imageURL: String? = nil, linkURL: String? = nil) {
        self.chatId = chatId
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
        self.imageURL = imageURL
        self.linkURL = linkURL // Initialize linkURL
    }

    static func ==(lhs: DBMessage, rhs: DBMessage) -> Bool {
        return lhs.id == rhs.id
    }

}

final class ChatManager {
    static let shared = ChatManager()
    private init() { }

    private let chatCollection = Firestore.firestore().collection("chats")

    private func chatDocument(chatId: String) -> DocumentReference {
        chatCollection.document(chatId)
    }

    private func messagesCollection(chatId: String) -> CollectionReference {
        chatDocument(chatId: chatId).collection("messages")
    }

    private func messagesDocument(chatId: String, messageId: String) -> DocumentReference {
        messagesCollection(chatId: chatId).document(messageId)
    }

    func createNewChat(chat: inout DBChat) async throws {
        let chatId = chatCollection.document().documentID
        chat.id = chatId
        try chatDocument(chatId: chatId).setData(from: chat, merge: false, encoder: Firestore.Encoder())
    }

    func sendMessage(message: DBMessage) async throws {
        let messageId = messagesCollection(chatId: message.chatId).document().documentID
        var messageWithId = message
        messageWithId.id = messageId
        try messagesDocument(chatId: message.chatId, messageId: messageId).setData(from: messageWithId, encoder: Firestore.Encoder())

        try await chatDocument(chatId: message.chatId).updateData([
            "lastMessage": message.text,
            "timestamp": Timestamp(date: Date()),
            "unreadMessages.\(message.receiverId)": FieldValue.increment(Int64(1))
        ])
        
        if message.senderId != Auth.auth().currentUser?.uid {
            sendNotification(for: message.chatId, messageText: message.text)
        }
    }

    func sendPostMessage(chatId: String, senderId: String, receiverId: String, post: Post) async throws {
        let messageId = messagesCollection(chatId: chatId).document().documentID
        let postMessage = DBMessage(
            chatId: chatId,
            senderId: senderId,
            receiverId: receiverId,
            text: "[Post] \(post.caption)",
            timestamp: Timestamp(),
            isRead: false,
            imageURL: post.imageName
        )
        
        try await messagesDocument(chatId: chatId, messageId: messageId).setData(from: postMessage, encoder: Firestore.Encoder())
        
        try await chatDocument(chatId: chatId).updateData([
            "lastMessage": "[Post] \(post.caption)",
            "timestamp": Timestamp(date: Date()),
            "unreadMessages.\(receiverId)": FieldValue.increment(Int64(1))
        ])
        
        if senderId != Auth.auth().currentUser?.uid {
            sendNotification(for: chatId, messageText: "[Post] \(post.caption)")
        }
    }

    func sendImageMessage(chatId: String, senderId: String, receiverId: String, image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            throw NSError(domain: "ChatManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child("chat_images").child(imageName)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            
            let downloadURL = try await storageRef.downloadURL()
            
            let newMessage = DBMessage(
                chatId: chatId,
                senderId: senderId,
                receiverId: receiverId,
                text: "[Image]",
                timestamp: Timestamp(),
                imageURL: downloadURL.absoluteString
            )
            
            try await messagesDocument(chatId: chatId, messageId: newMessage.id ?? UUID().uuidString).setData(from: newMessage, encoder: Firestore.Encoder())
            
            try await chatDocument(chatId: chatId).updateData([
                "lastMessage": "[Image]",
                "timestamp": Timestamp(date: Date()),
                "unreadMessages.\(receiverId)": FieldValue.increment(Int64(1))
            ])
            
            if senderId != Auth.auth().currentUser?.uid {
                sendNotification(for: chatId, messageText: "[Image]")
            }
            
        } catch {
            throw NSError(domain: "ChatManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to send image message: \(error.localizedDescription)"])
        }
    }

    func sendNotification(for chatId: String, messageText: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Message"
        content.body = messageText
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: chatId, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func getChats(for userId: String) async throws -> [DBChat] {
        let snapshot = try await chatCollection.whereField("participants", arrayContains: userId).getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: DBChat.self) }
    }

    func getMessages(for chatId: String) async throws -> [DBMessage] {
        let snapshot = try await messagesCollection(chatId: chatId).order(by: "timestamp").getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: DBMessage.self) }
    }

    func getChatBetweenUsers(user1Id: String, user2Id: String) async throws -> DBChat? {
        let snapshot = try await chatCollection
            .whereField("participants", arrayContains: user1Id)
            .getDocuments()

        for document in snapshot.documents {
            if let chat = try? document.data(as: DBChat.self),
               chat.participants.contains(user2Id) {
                return chat
            }
        }

        return nil // No chat found between the users
    }

    func addMessagesListener(chatId: String, completion: @escaping ([DBMessage]?, Error?) -> Void) -> ListenerRegistration {
        return messagesCollection(chatId: chatId)
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion(nil, nil)
                    return
                }
                let messages = documents.compactMap { try? $0.data(as: DBMessage.self) }
                completion(messages, nil)
            }
    }

    func markMessagesAsRead(chatId: String, userId: String) async throws {
        let snapshot = try await messagesCollection(chatId: chatId)
            .whereField("senderId", isNotEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        for document in snapshot.documents {
            try await document.reference.updateData(["isRead": true])
        }

        let chatDoc = chatDocument(chatId: chatId)
        try await chatDoc.updateData([
            "unreadMessages.\(userId)": 0
        ])
    }

    func getUnreadMessagesCount(userId: String) async throws -> Int {
        let snapshot = try await chatCollection
            .whereField("participants", arrayContains: userId)
            .getDocuments()

        var totalUnreadMessages = 0

        for document in snapshot.documents {
            if let chat = try? document.data(as: DBChat.self) {
                totalUnreadMessages += chat.unreadMessages[userId] ?? 0
            }
        }

        return totalUnreadMessages
    }
}
