//
//  PostManager.swift
//  fitnessapp
//
//  Created by Harris Kim on 5/23/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

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
    var likedBy: [String]

    init(id: UUID = UUID(), userId: String, username: String, imageName: String, caption: String, multiplePictures: Bool, workoutSplit: String, workoutSplitEmoji: String, comments: [Comment], date: Date = Date(), likes: Int = 0, likedBy: [String] = []) {
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
        self.likedBy = likedBy
    }
}

struct Comment: Identifiable, Codable {
    let id: UUID
    let username: String
    let text: String
    let date: Date
    var replies: [Comment]
    var showReplies: Bool = false
    var isReplying: Bool = false
    var replyText: String = ""

    init(id: UUID = UUID(), username: String, text: String, date: Date = Date(), replies: [Comment] = []) {
        self.id = id
        self.username = username
        self.text = text
        self.date = date
        self.replies = replies
    }
}

struct SharedPost: Codable, Identifiable {
    @DocumentID var id: String? = UUID().uuidString
    let postId: UUID
    let sharedByUserId: String
    let sharedWithUserId: String
    let sharedAt: Date

    init(postId: UUID, sharedByUserId: String, sharedWithUserId: String, sharedAt: Date = Date()) {
        self.postId = postId
        self.sharedByUserId = sharedByUserId
        self.sharedWithUserId = sharedWithUserId
        self.sharedAt = sharedAt
    }
}

final class PostManager {

    static let shared = PostManager()
    private init() { }

    private let postCollection = Firestore.firestore().collection("posts")
    private var sharedPostCollection: CollectionReference {
        Firestore.firestore().collection("sharedPosts")
    }

    private func postDocument(postId: String) -> DocumentReference {
        postCollection.document(postId)
    }

    func createNewPost(post: Post) async throws {
        try postDocument(postId: post.id.uuidString).setData(from: post, merge: false, encoder: Firestore.Encoder())
        try await UserManager.shared.updateSesh(forUser: post.userId, postDate: post.date)
    }

    func deletePost(postId: String) async throws {
        try await postDocument(postId: postId).delete()
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

    func addComment(postId: String, username: String, comment: String) async throws {
        let newComment = Comment(username: username, text: comment)
        let postRef = postDocument(postId: postId)
        let postDocument = try await postRef.getDocument()
        guard var post = try? postDocument.data(as: Post.self) else {
            throw NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode post"])
        }
        post.comments.append(newComment)
        try postRef.setData(from: post, merge: true, encoder: Firestore.Encoder())
    }

    func addReply(postId: String, commentId: UUID, username: String, reply: String) async throws {
        let newReply = Comment(username: username, text: reply)
        let postRef = postDocument(postId: postId)
        let postDocument = try await postRef.getDocument()
        guard var post = try? postDocument.data(as: Post.self) else {
            throw NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode post"])
        }
        if let commentIndex = post.comments.firstIndex(where: { $0.id == commentId }) {
            post.comments[commentIndex].replies.append(newReply)
        }
        try postRef.setData(from: post, merge: true, encoder: Firestore.Encoder())
    }

    func getComments(postId: String) async throws -> [Comment] {
        let document = try await postCollection.document(postId).getDocument()
        let post = try document.data(as: Post.self)
        return post.comments
    }

    func incrementLikes(postId: String, userId: String) async throws {
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

            var post = try? postDocument.data(as: Post.self)
            post!.likedBy.append(userId)
            transaction.updateData(["likes": oldLikes + 1, "likedBy": post!.likedBy], forDocument: postRef)
            return nil
        }
    }

    func decrementLikes(postId: String, userId: String) async throws {
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

            var post = try? postDocument.data(as: Post.self)
            post!.likedBy.removeAll { $0 == userId }
            transaction.updateData(["likes": oldLikes - 1, "likedBy": post!.likedBy], forDocument: postRef)
            return nil
        }
    }

    func getLikes(postId: String) async throws -> Int {
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

    func checkIfUserLikedPost(postId: String, userId: String) async throws -> Bool {
        let postRef = postDocument(postId: postId)
        let postDocument = try await postRef.getDocument()
        if let likedBy = postDocument.data()?["likedBy"] as? [String] {
            return likedBy.contains(userId)
        } else {
            return false
        }
    }

    func getUsersWhoLikedPost(postId: String) async throws -> [DBUser] {
        let postRef = postDocument(postId: postId)
        let postDocument = try await postRef.getDocument()
        guard let likedBy = postDocument.data()?["likedBy"] as? [String] else {
            throw NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to retrieve likedBy from snapshot \(postDocument)"
            ])
        }

        return try await withThrowingTaskGroup(of: DBUser.self, returning: [DBUser].self) { group in
            for userId in likedBy {
                group.addTask {
                    return try await UserManager.shared.getUser(userId: userId)
                }
            }

            var users = [DBUser]()
            for try await user in group {
                users.append(user)
            }
            return users
        }
    }

    func sharePost(postId: UUID, sharedByUserId: String, sharedWithUserId: String) async throws {
        let sharedPost = SharedPost(postId: postId, sharedByUserId: sharedByUserId, sharedWithUserId: sharedWithUserId)
        try await sharedPostCollection.document(sharedPost.id!).setData(from: sharedPost, encoder: Firestore.Encoder())
    }

    func getSharedPosts(forUser userId: String) async throws -> [SharedPost] {
        let snapshot = try await sharedPostCollection.whereField("sharedWithUserId", isEqualTo: userId).getDocuments()
        return snapshot.documents.compactMap { document -> SharedPost? in
            try? document.data(as: SharedPost.self)
        }
    }

    func likePost(postId: UUID, fromUserId: String, toUserId: String) async throws {
        try await incrementLikes(postId: postId.uuidString, userId: fromUserId)
        try await UserManager.shared.likePost(postId: postId.uuidString, fromUserId: fromUserId, toUserId: toUserId)
    }

    func commentOnPost(postId: UUID, fromUserId: String, toUserId: String, comment: String) async throws {
        try await addComment(postId: postId.uuidString, username: fromUserId, comment: comment)
        try await UserManager.shared.commentOnPost(postId: postId.uuidString, fromUserId: fromUserId, toUserId: toUserId, comment: comment)
    }
}
