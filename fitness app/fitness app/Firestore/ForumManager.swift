//
//  ForumManager.swift
//  fitnessapp
//
//  Created by Harris Kim on 7/3/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

// Data Models
class ForumPost: Identifiable, ObservableObject, Codable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let title: String
    let body: String
    @Published var replies: [Reply]
    let media: [MediaItem]
    let link: URL?
    @Published var likes: [String]
    let createdAt: Date

    init(userId: String, username: String, title: String, body: String, replies: [Reply] = [], media: [MediaItem] = [], link: URL? = nil, likes: [String] = [], createdAt: Date = Date()) {
        self.userId = userId
        self.username = username
        self.title = title
        self.body = body
        self.replies = replies
        self.media = media
        self.link = link
        self.likes = likes
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case username
        case title
        case body
        case replies
        case media
        case link
        case likes
        case createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decode(String.self, forKey: .username)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        replies = try container.decode([Reply].self, forKey: .replies)
        media = try container.decode([MediaItem].self, forKey: .media)
        link = try container.decodeIfPresent(URL.self, forKey: .link)
        likes = try container.decode([String].self, forKey: .likes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(username, forKey: .username)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encode(replies, forKey: .replies)
        try container.encode(media, forKey: .media)
        try container.encodeIfPresent(link, forKey: .link)
        try container.encode(likes, forKey: .likes)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

class Reply: Codable, Identifiable, ObservableObject {
    @DocumentID var id: String?
    let forumPostId: String
    let username: String
    let replyText: String
    @Published var media: [MediaItem]
    @Published var likes: [String]
    @Published var replies: [Reply]
    let createdAt: Date

    init(forumPostId: String, username: String, replyText: String, media: [MediaItem] = [], likes: [String] = [], replies: [Reply] = [], createdAt: Date = Date()) {
        self.forumPostId = forumPostId
        self.username = username
        self.replyText = replyText
        self.media = media
        self.likes = likes
        self.replies = replies
        self.createdAt = createdAt
    }

enum CodingKeys: String, CodingKey {
        case id
        case forumPostId
        case username
        case replyText
        case media
        case likes
        case likedByCurrentUser
        case replies
        case createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        forumPostId = try container.decode(String.self, forKey: .forumPostId)
        username = try container.decode(String.self, forKey: .username)
        replyText = try container.decode(String.self, forKey: .replyText)
        media = try container.decode([MediaItem].self, forKey: .media)
        likes = try container.decode([String].self, forKey: .likes)
        replies = try container.decode([Reply].self, forKey: .replies)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(replyText, forKey: .replyText)
        try container.encode(media, forKey: .media)
        try container.encode(likes, forKey: .likes)
        try container.encode(replies, forKey: .replies)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

class MediaItem: Codable, Identifiable {
    @DocumentID var id: String?
    let type: MediaType
    let url: URL

    init(type: MediaType, url: URL) {
        self.type = type
        self.url = url
    }
}

enum MediaType: Codable {
    case image
    case video
}

enum SortOption: String, CaseIterable {
    case hot = "Hot"
    case topDay = "Top (Day)"
    case topWeek = "Top (Week)"
    case topMonth = "Top (Month)"
    case topYear = "Top (Year)"
    case topAllTime = "Top (All Time)"
}


final class ForumManager {
    static let shared = ForumManager()
    private init() { }

    private let forumCollection = Firestore.firestore().collection("forum_posts")

    private func forumDocument(forumId: String) -> DocumentReference {
        forumCollection.document(forumId)
    }

    func getForumPost(forumPostId: String) async throws -> ForumPost {
        try await forumDocument(forumId: forumPostId).getDocument(as: ForumPost.self)
    }

    func getAllForumPosts() async throws -> [ForumPost] {
        let snapshot = try await forumCollection.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ForumPost.self) }
    }


    func createNewForumPost(forumPost: ForumPost) async throws {
        let forumDocument = forumCollection.document(forumPost.id ?? UUID().uuidString)
        try forumDocument.setData(from: forumPost, merge: false, encoder: Firestore.Encoder())
    }

    func createNewReply(for post: ForumPost, reply: Reply) async throws {
        guard let postId = post.id else {
            print("Couldn't find post id")
            return
        }

        do {
            let forumRef = forumDocument(forumId: postId)
            let forumDoc = try await forumRef.getDocument()

            guard let forum = try forumDoc.data(as: ForumPost?.self) else {
                throw NSError(domain: "App ErrorDomain", code: -5, userInfo: [NSLocalizedDescriptionKey: "Unable to decode forum post"])
            }

            // Ensure the reply is unique before adding
            if !forum.replies.contains(where: { $0.id == reply.id }) {
                forum.replies.append(reply)

                // Update the forum post in Firestore
                try forumRef.setData(from: forum, merge: true)
                print("Reply added successfully")
            } else {
                print("Reply already exists")
            }
        } catch {
            print("Error adding reply: \(error.localizedDescription)")
            throw error
        }
    }

    func createNewReply(for parentReply: Reply, reply: Reply) async throws {
        guard let parentReplyId = parentReply.id else {
            print("Couldn't find parent reply id")
            return
        }

        do {
            let forumRef = forumDocument(forumId: parentReply.forumPostId)
            let forumDoc = try await forumRef.getDocument()

            guard let forum = try forumDoc.data(as: ForumPost?.self) else {
                throw NSError(domain: "App ErrorDomain", code: -5, userInfo: [NSLocalizedDescriptionKey: "Unable to decode forum post"])
            }

            // Ensure the parent reply exists
            guard let parentIndex = forum.replies.firstIndex(where: { $0.id == parentReplyId }) else {
                print("Parent reply not found")
                return
            }

            // Ensure the reply is unique before adding
            if !forum.replies[parentIndex].replies.contains(where: { $0.id == reply.id }) {
                forum.replies[parentIndex].replies.append(reply)

                // Update the forum post in Firestore
                try forumRef.setData(from: forum, merge: true)
                print("Reply added successfully")
            } else {
                print("Reply already exists")
            }
        } catch {
            print("Error adding reply: \(error.localizedDescription)")
            throw error
        }
    }

    
    func likePost(for forumPostId: String, userId: String) async throws {
        do {
            let forumRef = forumDocument(forumId: forumPostId)
            let forumDocument = try await forumRef.getDocument()
            
            guard var forumPost = try? forumDocument.data(as: ForumPost.self) else {
                throw NSError(domain: "App ErrorDomain", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unable to decode forum post"])
            }
            
            if !forumPost.likes.contains(userId) {
                forumPost.likes.append(userId)
                try forumRef.setData(from: forumPost)
                print("You liked the forum post")
            } else {
                print("you already liked the forum post")
            }
        } catch {
            print("Error liking the forum post: \(error.localizedDescription)")
            throw error
        }
    }
    
    func likeReply(userId: String, for reply: Reply, in post: ForumPost) async throws {
        guard let replyId = reply.id else {
            print("couldnt get reply id")
            return
        }
        
        guard let forumPostId = post.id else {
            print("couldnt find forum post id")
            return
        }
        do {
            let forumRef = forumDocument(forumId: forumPostId)
            let forumDocument = try await forumRef.getDocument()
            
            guard var forumPost = try? forumDocument.data(as: ForumPost.self) else {
                throw NSError(domain: "App ErrorDomain", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unable to decode forum post"])
            }
            
            if let replyIndex = forumPost.replies.firstIndex(where: { $0.id == replyId }) {
                var replyToUpdate = forumPost.replies[replyIndex]
                
                if !replyToUpdate.likes.contains(where: { $0 == userId }) {
                    replyToUpdate.likes.append(userId)
                    forumPost.replies[replyIndex] = replyToUpdate
                    try forumRef.setData(from: forumPost)
                    print("You liked the reply")
                } else {
                    print("You already liked the reply")
                }
            } else {
                print("Reply not found")
            }
        } catch {
            print("Error liking the forum post: \(error.localizedDescription)")
            throw error
        }
        
    }
}

