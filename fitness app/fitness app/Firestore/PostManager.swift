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
//    let userId: String
    let username: String
    let imageName: String
    let caption: String
    let multiplePictures: Bool
    let workoutSplit: String
    let workoutSplitEmoji: String
    var comments: [Comment]
    
    init(id: UUID = UUID(), username: String, imageName: String, caption: String, multiplePictures: Bool, workoutSplit: String, workoutSplitEmoji: String, comments: [Comment]) {
         self.id = id
//         self.userId = userId
         self.username = username
         self.imageName = imageName
         self.caption = caption
         self.multiplePictures = multiplePictures
         self.workoutSplit = workoutSplit
         self.workoutSplitEmoji = workoutSplitEmoji
         self.comments = comments
     }
}

struct Comment: Codable, Identifiable {
    let id: UUID
    let username: String
    let text: String
    
    init(id: UUID = UUID(), username: String, text: String) {
        self.id = id
        self.username = username
        self.text = text
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
        print("PostManager.createNewPost called")
            try postDocument(postId: post.id).setData(from: post, merge: false, encoder: Firestore.Encoder())
        }
    
    func getPosts() async throws -> [Post] {
        print("getPosts called")
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
        do {
            let postRef = postDocument(postId: postId)
            let postDocument = try await postRef.getDocument()
            guard var post = try? postDocument.data(as: Post.self) else {
                throw NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode post"])
            }
            
            post.comments.append(newComment)
            
            try postRef.setData(from: post)
            
            print("added comment successfully")
        } catch {
            print("could not add comment")
        }
    }
    
    func getComments(postId: UUID) async throws -> [Comment] {
        let document = try await postCollection.document(postId.uuidString).getDocument()
        let post = try document.data(as: Post.self)
        return post.comments
    }
}

