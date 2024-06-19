//
//  AuthenticationManager.swift
//  fitnessapp
//
//  Created by Harris Kim on 3/27/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct AuthDataResultModel {
    let uid: String
    let email: String
    let photoUrl: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email!
        self.photoUrl = user.photoURL?.absoluteString
    }
    
    init(mockUser: MockUser) {
        self.uid = mockUser.uid
        self.email = mockUser.email!
        self.photoUrl = mockUser.photoURL
    }
}

struct MockUser {
    var uid: String
    var email: String?
    var photoURL: String?

    init(uid: String, email: String?, photoURL: String?) {
        self.uid = uid
        self.email = email
        self.photoURL = photoURL
    }
}

final class AuthenticationManager {
    
    static let shared = AuthenticationManager()
    private let db = Firestore.firestore()
    private init() { }
    
    func createMockUser(mockUser: MockUser) -> AuthDataResultModel {
        return AuthDataResultModel(mockUser: mockUser)
    }
    
    func createUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    func getAuthenticatedUser() throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        return AuthDataResultModel(user: user)
    }
    
    func getUser(id: String) async throws -> AuthDataResultModel {
            let document = try await db.collection("users").document(id).getDocument()
            guard let data = document.data() else {
                throw URLError(.badServerResponse)
            }
            
            let email = data["email"] as? String ?? ""
            let photoUrl = data["photoUrl"] as? String ?? ""
            let mockUser = MockUser(uid: id, email: email, photoURL: photoUrl)
            
            return AuthDataResultModel(mockUser: mockUser)
        }
    
    func logInUser(email: String, password: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    func logOut() throws {
        try Auth.auth().signOut()
    }
    
    func delete() async throws {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badURL)
        }
        
        try await user.delete()
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
}
