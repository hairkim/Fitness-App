//
//  AuthenticationManager.swift
//  fitnessapp
//
//  Created by Harris Kim on 3/27/24.
//

import Foundation
import FirebaseAuth

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
        self.photoUrl = mockUser.photoURL?.absoluteString
    }
}

struct MockUser {
    var uid: String
    var email: String?
    var photoURL: URL?

    init(uid: String, email: String?, photoURL: URL?) {
        self.uid = uid
        self.email = email
        self.photoURL = photoURL
    }
}

final class AuthenticationManager {
    
    static let shared = AuthenticationManager()
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
