//
//  UserManager.swift
//  fitnessapp
//
//  Created by Joshua Kim on 4/19/24.
//
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DBUser: Codable, Identifiable, Equatable, Hashable {
    var id: String { userId }
    let userId: String
    let username: String
    let dateCreated: Date?
    let email: String?
    let photoUrl: String?
    var followers: [String]
    var followRequests: [String] // New field for follow requests
    var isPublic: Bool // Changed from let to var
    var sesh: Int = 0 // New field for tracking sessions
    var lastGymVisit: Date? = nil // New field
    
    init(auth: AuthDataResultModel, username: String) {
        self.userId = auth.uid
        self.username = username
        self.dateCreated = Date()
        self.email = auth.email
        self.photoUrl = auth.photoUrl
        self.followers = [String]()
        self.followRequests = [String]() // Initialize followRequests
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

    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
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
        let userRef = userDocument(userId: receiver.userId)
        let userDocument = try await userRef.getDocument()
        
        guard var user = try? userDocument.data(as: DBUser.self) else {
            throw NSError(domain: "App ErrorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode user"])
        }
        
        if !user.followers.contains(sender.userId) {
            user.followers.append(sender.userId)
            try userRef.setData(from: user)
            print("Added as follower")
            
            // Create notification for following
            let notification = Notification(
                type: .follow,
                fromUserId: sender.userId,
                postId: nil,
                toUserId: receiver.userId,
                timestamp: Date()
            )
            try await NotificationManager.shared.addNotification(notification)
        } else {
            print("User is already a follower")
        }
    }

    func removeFollower(sender: DBUser, receiver: DBUser) async throws {
        let userRef = userDocument(userId: receiver.userId)
        let userDocument = try await userRef.getDocument()
        
        guard var user = try? userDocument.data(as: DBUser.self) else {
            throw NSError(domain: "App ErrorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode user"])
        }
        
        if let index = user.followers.firstIndex(of: sender.userId) {
            user.followers.remove(at: index)
            try userRef.setData(from: user)
            print("Removed as follower")
        } else {
            print("User is not a follower")
        }
    }

    func isFollowing(senderId: String, receiverId: String) async -> Bool {
        do {
            let receiver = try await getUser(userId: receiverId)
            return receiver.followers.contains(senderId)
        } catch {
            print("Error checking follow status: \(error.localizedDescription)")
            return false
        }
    }

    func sendFollowRequest(sender: DBUser, receiver: DBUser) async throws {
        let userRef = userDocument(userId: receiver.userId)
        let userDocument = try await userRef.getDocument()
        
        guard var user = try? userDocument.data(as: DBUser.self) else {
            throw NSError(domain: "App ErrorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode user"])
        }
        
        if !user.followRequests.contains(sender.userId) {
            user.followRequests.append(sender.userId)
            try userRef.setData(from: user)
            print("Follow request sent")
            
            // Create notification for follow request
            let notification = Notification(
                type: .followRequest,
                fromUserId: sender.userId,
                postId: nil,
                toUserId: receiver.userId,
                timestamp: Date()
            )
            try await NotificationManager.shared.addNotification(notification)
        } else {
            print("Follow request already sent")
        }
    }
    
    func acceptFollowRequest(senderId: String, receiverId: String) async throws {
        let userRef = userDocument(userId: receiverId)
        let userDocument = try await userRef.getDocument()
        
        guard var user = try? userDocument.data(as: DBUser.self) else {
            throw NSError(domain: "App ErrorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode user"])
        }
        
        if let index = user.followRequests.firstIndex(of: senderId) {
            user.followRequests.remove(at: index)
            user.followers.append(senderId)
            try userRef.setData(from: user)
            print("Follow request accepted")
            
            // Create notification for follow request acceptance
            let notification = Notification(
                type: .follow,
                fromUserId: receiverId,
                postId: nil,
                toUserId: senderId,
                timestamp: Date()
            )
            try await NotificationManager.shared.addNotification(notification)
        } else {
            print("Follow request not found")
        }
    }
    
    func declineFollowRequest(senderId: String, receiverId: String) async throws {
        let userRef = userDocument(userId: receiverId)
        let userDocument = try await userRef.getDocument()
        
        guard var user = try? userDocument.data(as: DBUser.self) else {
            throw NSError(domain: "App ErrorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode user"])
        }
        
        if let index = user.followRequests.firstIndex(of: senderId) {
            user.followRequests.remove(at: index)
            try userRef.setData(from: user)
            print("Follow request declined")
        } else {
            print("Follow request not found")
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
    
    func removeFollowRequest(sender: DBUser, receiver: DBUser) async throws {
        let userRef = userDocument(userId: receiver.userId)
        let userDocument = try await userRef.getDocument()
        
        guard var user = try? userDocument.data(as: DBUser.self) else {
            throw NSError(domain: "App ErrorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to decode user"])
        }
        
        if let index = user.followRequests.firstIndex(of: sender.userId) {
            user.followRequests.remove(at: index)
            try userRef.setData(from: user)
            print("Follow request removed")
        } else {
            print("Follow request not found")
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
    
    // New method to get followed user IDs
    func getFollowedUserIds(for userId: String) async throws -> [String] {
        let user = try await getUser(userId: userId)
        return user.followers
    }
    
    // New Session Update Method
    func updateSesh(forUser userId: String, postDate: Date) async throws {
        var user = try await getUser(userId: userId)
        user.sesh += 1
        user.lastGymVisit = postDate
        try await updateUser(user)
    }

    // Add Notification for Liking a Post
    func likePost(postId: String, fromUserId: String, toUserId: String) async throws {
        // Logic to like a post
        
        // Create notification
        let notification = Notification(
            type: .like,
            fromUserId: fromUserId,
            postId: postId,
            toUserId: toUserId,
            timestamp: Date()
        )
        try await NotificationManager.shared.addNotification(notification)
    }

    // Add Notification for Commenting on a Post
    func commentOnPost(postId: String, fromUserId: String, toUserId: String, comment: String) async throws {
        // Logic to add a comment
        
        // Create notification
        let notification = Notification(
            type: .comment,
            fromUserId: fromUserId,
            postId: postId,
            toUserId: toUserId,
            timestamp: Date()
        )
        try await NotificationManager.shared.addNotification(notification)
    }
}
