//
//  LikesListView.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/6/24.
//

import SwiftUI
import Firebase

struct LikesListView: View {
    let postId: String
    @State private var likes = [DBUser]()
    
    var body: some View {
        NavigationView {
            List(likes) { user in
                Text(user.username)
            }
            .navigationTitle("Liked By")
            .onAppear {
                fetchLikes()
            }
        }
    }
    
    private func fetchLikes() {
        Task {
            do {
                let likedUsers = try await PostManager.shared.getUsersWhoLikedPost(postId: postId)
                self.likes = likedUsers
            } catch {
                print("Error fetching likes: \(error)")
            }
        }
    }
}

struct LikesListView_Previews: PreviewProvider {
    static var previews: some View {
        LikesListView(postId: UUID().uuidString) // Convert UUID to String
    }
}
