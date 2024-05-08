//
//  UserManager.swift
//  fitnessapp
//
//  Created by Joshua Kim on 4/19/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DBUser {
    let userId: String
    let dateCreated: Date?
    let email: String?
    let photoUrl: String?
}

final class UserManager {
    
    static let shared = UserManager()
    private init() { }
    
    func createNewUser(auth: AuthDataResultModel) async throws {
        var userData: [ String:Any] = [
            "user_id" : auth.uid,
            "date_created" : Timestamp(),
            "email" : auth.email,
        ]
        if let photoUrl = auth.photoUrl {
            userData["photo_url"] = photoUrl
        }
        
        try await Firestore.firestore().collection("users").document(auth.uid).setData(userData, merge: false)
    }
    
    func getUser(userId: String) async throws -> DBUser {
        let document = try await Firestore.firestore().collection("users").document(userId).getDocument()
        
        guard let data = document.data(), let userId = data["user_id"] as? String else {
            throw URLError(.badServerResponse)
        }
        
        let dateCreated = data["date_created"] as? Date
        let email = data["email"] as? String
        let photoUrl = data["photo_url"] as? String
        
        return DBUser(userId: userId, dateCreated: dateCreated, email: email, photoUrl: photoUrl)
    }
     
}
