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
    
    init(auth: AuthDataResultModel, username: String) {
        self.userId = auth.uid
        self.username = username
        self.dateCreated = Date()
        self.email = auth.email
        self.photoUrl = auth.photoUrl
    }
}




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
    
//    func createNewUser(auth: AuthDataResultModel) async throws {
//        var userData: [ String:Any] = [
//            "user_id" : auth.uid,
//            "date_created" : Timestamp(),
//            "email" : auth.email,
//        ]
//        if let photoUrl = auth.photoUrl {
//            userData["photo_url"] = photoUrl
//        }
//        
//        try await userDocument(userId: auth.uid).setData(userData, merge: false)
//    }
    
    func getUser(userId: String) async throws -> DBUser {
        try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }
    
//    func getUser(userId: String) async throws -> DBUser {
//        let document = try await userDocument(userId: userId).getDocument()
//        
//        guard let data = document.data(), let userId = data["user_id"] as? String else {
//            throw URLError(.badServerResponse)
//        }
//        
//        let dateCreated = data["date_created"] as? Date
//        let email = data["email"] as? String
//        let photoUrl = data["photo_url"] as? String
//        
//        return DBUser(userId: userId, dateCreated: dateCreated, email: email, photoUrl: photoUrl)
//    }
     
}
