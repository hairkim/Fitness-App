//
//  UserManager.swift
//  fitnessapp
//
//  Created by Joshua Kim on 4/19/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DBUser: Codable {
    let userId: String
    let username: String
    let dateCreated: Date?
    let email: String?
    let photoUrl: String?
    var followers: [String]
    let isPublic: Bool
    
    init(auth: AuthDataResultModel, username: String) {
        self.userId = auth.uid
        self.username = username
        self.dateCreated = Date()
        self.email = auth.email
        self.photoUrl = auth.photoUrl
        self.followers = [String]()
        self.isPublic = true
    }
    
    static var placeholder: DBUser {
        let mockUser = MockUser(uid: "placeholder", email: "", photoURL: nil)
        let authDataResultModel = AuthDataResultModel(mockUser: mockUser)
        return DBUser(auth: authDataResultModel, username: "Loading...")
    }
}

//struct UserProfile: Identifiable, Codable {
//    let user: DBUser
//    
//}


final class UserManager {
    
    static let shared = UserManager()
    private init() { }
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    func createNewUser(user: DBUser) async throws {
        try userDocument(userId: user.userId).setData(from: user, merge: false, encoder: Firestore.Encoder())
    }
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func getUser(userId: String) async throws -> DBUser {
        try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }
    
    func addFollower(sender: DBUser, receiver: DBUser) async throws {
        guard sender.userId != receiver.userId else {
            return
        }
        do {
            let userRef = userDocument(userId: receiver.userId)
            let userDocument = try await userRef.getDocument()
            
            guard var user = try? userDocument.data(as: DBUser.self) else {
                throw NSError(domain: "App ErrorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode user"])
            }
            
            if !user.followers.contains(sender.userId) {
                   user.followers.append(sender.userId)
                   try userRef.setData(from: user)
                   print("Added as follower")
               } else {
                   print("User is already a follower")
               }
           } catch {
               print("Error adding follower: \(error.localizedDescription)")
               throw error
           }
    }
}
