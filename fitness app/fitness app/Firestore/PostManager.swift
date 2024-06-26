//
//  PostManager.swift
//  fitnessapp
//
//  Created by Harris Kim on 5/23/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI

struct Post: Codable, Identifiable {
    let id: UUID
    let userId: String
    let username: String
    let imageName: String
    let caption: String
    let multiplePictures: Bool
    let workoutSplit: String
    let workoutSplitEmoji: String
    var comments: [Comment]
    let date: Date
    var likes: Int

    init(id: UUID = UUID(), userId: String, username: String, imageName: String, caption: String, multiplePictures: Bool, workoutSplit: String, workoutSplitEmoji: String, comments: [Comment], date: Date = Date(), likes: Int = 0) {
        self.id = id
        self.userId = userId
        self.username = username
        self.imageName = imageName
        self.caption = caption
        self.multiplePictures = multiplePictures
        self.workoutSplit = workoutSplit
        self.workoutSplitEmoji = workoutSplitEmoji
        self.comments = comments
        self.date = date
        self.likes = likes
    }
}

struct Comment: Codable, Identifiable {
    let id: UUID
    let username: String
    let text: String
    var replies: [Comment]

    init(id: UUID = UUID(), username: String, text: String, replies: [Comment] = []) {
        self.id = id
        self.username = username
        self.text = text
        self.replies = replies
    }
}

final class PostManager {

    static let shared = PostManager()
    private init() { }

    private let postCollection = Firestore.firestore().collection("posts")

    private func postDocument(postId: UUID) -> DocumentReference {
        postCollection.document(postId.uuidString)
    }

    func createNewPost(post: Post) async throws {
        try postDocument(postId: post.id).setData(from: post, merge: false, encoder: Firestore.Encoder())
    }

    func getPosts() async throws -> [Post] {
        let snapshot = try await postCollection.getDocuments()
        return snapshot.documents.compactMap { document -> Post? in
            try? document.data(as: Post.self)
        }
    }

    func getPosts(forUser userId: String) async throws -> [Post] {
        let snapshot = try await postCollection.whereField("userId", isEqualTo: userId).getDocuments()
        return snapshot.documents.compactMap { document -> Post? in
            try? document.data(as: Post.self)
        }
    }

    func addComment(postId: UUID, username: String, comment: String) async throws {
        let newComment = Comment(username: username, text: comment)
        let postRef = postDocument(postId: postId)
        let postDocument = try await postRef.getDocument()
        guard var post = try? postDocument.data(as: Post.self) else {
            throw NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode post"])
        }
        post.comments.append(newComment)
        try postRef.setData(from: post)
    }

    func addReply(postId: UUID, commentId: UUID, username: String, reply: String) async throws {
        let newReply = Comment(username: username, text: reply)
        let postRef = postDocument(postId: postId)
        let postDocument = try await postRef.getDocument()
        guard var post = try? postDocument.data(as: Post.self) else {
            throw NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode post"])
        }
        if let commentIndex = post.comments.firstIndex(where: { $0.id == commentId }) {
            post.comments[commentIndex].replies.append(newReply)
        }
        try postRef.setData(from: post)
    }

    func getComments(postId: UUID) async throws -> [Comment] {
        let document = try await postCollection.document(postId.uuidString).getDocument()
        let post = try document.data(as: Post.self)
        return post.comments
    }

    func incrementLikes(postId: UUID) async throws {
        let postRef = postDocument(postId: postId)
        try await Firestore.firestore().runTransaction { (transaction, errorPointer) -> Any? in
            let postDocument: DocumentSnapshot
            do {
                postDocument = try transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let oldLikes = postDocument.data()?["likes"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve likes from snapshot \(postDocument)"
                ])
                errorPointer?.pointee = error
                return nil
            }

            transaction.updateData(["likes": oldLikes + 1], forDocument: postRef)
            return nil
        }
    }

    func decrementLikes(postId: UUID) async throws {
        let postRef = postDocument(postId: postId)
        try await Firestore.firestore().runTransaction { (transaction, errorPointer) -> Any? in
            let postDocument: DocumentSnapshot
            do {
                postDocument = try transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let oldLikes = postDocument.data()?["likes"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve likes from snapshot \(postDocument)"
                ])
                errorPointer?.pointee = error
                return nil
            }

            transaction.updateData(["likes": oldLikes - 1], forDocument: postRef)
            return nil
        }
    }

    func getLikes(postId: UUID) async throws -> Int {
        let postRef = postDocument(postId: postId)
        let postDocument = try await postRef.getDocument()
        if let likes = postDocument.data()?["likes"] as? Int {
            return likes
        } else {
            throw NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to retrieve likes from snapshot \(postDocument)"
            ])
        }
    }
}

struct CommentView: View {
    var comment: Comment
    var postId: UUID
    var deleteComment: (Comment) -> Void
    var addReply: (UUID, UUID, String, String) -> Void
    
    @State private var isReplying = false
    @State private var replyText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(comment.username): \(comment.text)")
                    .padding(.horizontal, 16)
                Spacer()
                Button(action: {
                    deleteComment(comment)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .padding(.trailing, 16)
            }
            
            if isReplying {
                HStack {
                    TextField("Write a reply...", text: $replyText, onCommit: {
                        Task {
                            await addReply(postId, comment.id, comment.username, replyText)
                            replyText = ""
                            isReplying = false
                        }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        Task {
                            await addReply(postId, comment.id, comment.username, replyText)
                            replyText = ""
                            isReplying = false
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            ForEach(comment.replies) { reply in
                HStack {
                    Text("\(reply.username): \(reply.text)")
                        .padding(.horizontal, 32)
                    Spacer()
                }
            }
            
            Button(action: {
                isReplying.toggle()
            }) {
                Text(isReplying ? "Cancel" : "Reply")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}
