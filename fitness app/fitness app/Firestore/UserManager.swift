//
//  UserManager.swift
//  fitnessapp
//
//  Created by Joshua Kim on 4/19/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DBUser: Codable, Identifiable, Equatable {
    var id: String { userId }
    let userId: String
    let username: String
    let dateCreated: Date?
    let email: String?
    let photoUrl: String?
    var followers: [String]
    let isPublic: Bool
    var sesh: Int = 0 // New field for tracking sessions
    var lastGymVisit: Date? = nil // New field
    
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

    // Implement Equatable
    static func ==(lhs: DBUser, rhs: DBUser) -> Bool {
        return lhs.userId == rhs.userId
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
    
    func getUser(userId: String) async throws -> DBUser {
        var user = try await userDocument(userId: userId).getDocument(as: DBUser.self)
        
        // Provide default values for new fields if missing
        if user.sesh == 0 {
            user.sesh = 0
        }
        if user.lastGymVisit == nil {
            user.lastGymVisit = nil
        }
        
        return user
    }
    
    func getAllUsers() async throws -> [DBUser] {
        let snapshot = try await userCollection.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: DBUser.self) }
    }
    
    func updateUser(_ user: DBUser) async throws {
        try userDocument(userId: user.userId).setData(from: user, merge: true)
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
    
    func fetchFollowers(for userId: String, completion: @escaping ([String]?) -> Void) {
        userDocument(userId: userId).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let followerIds = data?["followers"] as? [String]
                completion(followerIds)
            } else {
                completion(nil)
            }
        }
    }
    
    func searchFollowers(for userId: String, searchTerm: String, completion: @escaping ([DBUser]?) -> Void) {
        fetchFollowers(for: userId) { followerIds in
            guard let followerIds = followerIds else {
                completion(nil)
                return
            }
            
            self.userCollection.whereField("username", isGreaterThanOrEqualTo: searchTerm).whereField("username", isLessThanOrEqualTo: searchTerm + "\u{f8ff}").getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error searching users: \(error)")
                    completion(nil)
                } else {
                    Task {
                        var users: [DBUser] = []
                        await withTaskGroup(of: DBUser?.self) { group in
                            for document in querySnapshot!.documents {
                                let data = document.data()
                                if let id = data["id"] as? String, followerIds.contains(id) {
                                    let username = data["username"] as? String ?? ""
                                    let profilePictureUrl = data["photoUrl"] as? String ?? ""
                                    
                                    group.addTask {
                                        do {
                                            let userAuthDataModel = try await AuthenticationManager.shared.getUser(id: id)
                                            let user = DBUser(auth: userAuthDataModel, username: username)
                                            return user
                                        } catch {
                                            print("Error fetching user details: \(error)")
                                            return nil
                                        }
                                    }
                                }
                            }
                            
                            for await user in group {
                                if let user = user {
                                    users.append(user)
                                }
                            }
                        }
                        completion(users)
                    }
                }
            }
        }
    }
    
    // New Session Update Method
    func updateSesh(forUser userId: String, postDate: Date) async throws {
        var user = try await getUser(userId: userId)
        user.sesh += 1
        user.lastGymVisit = postDate
        try await updateUser(user)
    }
}
