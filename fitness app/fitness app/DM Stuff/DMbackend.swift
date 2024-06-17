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
    let name: String
    let initials: String
    var lastMessage: String?
    var timestamp: Timestamp
    var profileImage: String? // URL to the profile image
    
    init(participants: [String], name: String, initials: String, lastMessage: String?, timestamp: Timestamp = Timestamp(), profileImage: String?) {
        self.participants = participants
        self.name = name
        self.initials = initials
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.profileImage = profileImage
    }
}

struct DBMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let senderId: String
    let text: String
    let timestamp: Timestamp
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
    
    func createNewChat(chat: DBChat) async throws {
        try chatCollection.addDocument(from: chat, encoder: Firestore.Encoder())
    }
    
    func sendMessage(chatId: String, senderId: String, text: String) async throws {
        let message = DBMessage(senderId: senderId, text: text, timestamp: Timestamp(date: Date()))
        try messagesCollection(chatId: chatId).addDocument(from: message, encoder: Firestore.Encoder())
        
        // Update last message in chat document
        try await chatDocument(chatId: chatId).updateData([
            "lastMessage": text,
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
}
