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
    let username: String
    let imageName: String
    let caption: String
    let multiplePictures: Bool
    let workoutSplit: String
    let workoutSplitEmoji: String
    var comments: [Comment]
    
    init(id: UUID = UUID(), username: String, imageName: String, caption: String, multiplePictures: Bool, workoutSplit: String, workoutSplitEmoji: String, comments: [Comment]) {
         self.id = id
         self.username = username
         self.imageName = imageName
         self.caption = caption
         self.multiplePictures = multiplePictures
         self.workoutSplit = workoutSplit
         self.workoutSplitEmoji = workoutSplitEmoji
         self.comments = comments
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
}