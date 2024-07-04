//
//  DMbackend.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/12/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DBChat: Codable, Identifiable {
    @DocumentID var id: String?
    let participants: [String]
    let participantNames: [String: String]
    var lastMessage: String?
    var timestamp: Timestamp
    var profileImage: String? // URL to the profile image

    init(id: String? = nil, participants: [String], participantNames: [String: String], lastMessage: String?, timestamp: Timestamp = Timestamp(), profileImage: String?) {
        self.id = id
        self.participants = participants
        self.participantNames = participantNames
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.profileImage = profileImage
    }
}

struct DBMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let chatId: String
    let senderId: String
    let text: String
    let timestamp: Timestamp
    
    init(chatId: String, senderId: String, text: String, timestamp: Timestamp = Timestamp()) {
        self.chatId = chatId
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
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
        var chatWithId = chat
        chatWithId.id = chatId
        try chatDocument(chatId: chatId).setData(from: chatWithId, merge: false, encoder: Firestore.Encoder())
    }

    func sendMessage(message: DBMessage) async throws {
        let messageId = messagesCollection(chatId: message.chatId).document().documentID
        var messageWithId = message
        messageWithId.id = messageId
        try messagesDocument(chatId: message.chatId, messageId: messageId).setData(from: messageWithId, encoder: Firestore.Encoder())

        // Update last message in chat document
        try await chatDocument(chatId: message.chatId).updateData([
            "lastMessage": message.text,
            "timestamp": Timestamp(date: Date())
        ])
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
}
