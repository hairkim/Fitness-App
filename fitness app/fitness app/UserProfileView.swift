//
//  UserProfileView.swift
//  fitnessapp
//
//  Created by Harris Kim on 6/5/24.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var userStore: UserStore
    
    let postUser: DBUser
    @State var posts = [Post]() // Using the same Post structure

    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture and User Info
            VStack(spacing: 8) {
                if let photoUrl = postUser.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .clipShape(Circle())
                    .frame(width: 100, height: 100)
                    .padding(.top)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .frame(width: 100, height: 100)
                        .padding(.top)
                }

                Text(postUser.username)
                    .font(.title)
                    .fontWeight(.bold)

                Text(postUser.email ?? "Email not available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top)

            // Follow Button
            Button(action: {
                Task {
                    await addFollower()
                }
            }) {
                Text("Follow")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            // Posts (Grid Layout)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(posts) { post in
                        if let url = URL(string: post.imageName) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Color.gray.opacity(0.5)
                                        .frame(height: 150)
                                        .cornerRadius(10)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 150)
                                        .clipped()
                                        .cornerRadius(10)
                                case .failure:
                                    Color.gray.opacity(0.5)
                                        .frame(height: 150)
                                        .cornerRadius(10)
                                @unknown default:
                                    Color.gray.opacity(0.5)
                                        .frame(height: 150)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            Spacer()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchProfileData()
        }
    }

    private func addFollower() async {
        guard let currentUser = userStore.currentUser else {
            print("Current user is nil")
            return
        }
        do {
            try await UserManager.shared.addFollower(sender: currentUser, receiver: postUser)
            print("Follower added successfully")
        } catch {
            print("Error adding follower: \(error.localizedDescription)")
        }
    }

    private func fetchProfileData() {
        Task {
            do {
                self.posts = try await PostManager.shared.getPosts(forUser: postUser.userId)
            } catch {
                print("Error fetching profile data: \(error)")
            }
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = MockUser(uid: "12kjksdfj", email: "mockUser@gmail.com", photoURL: nil)
        let authResultModel = AuthenticationManager.shared.createMockUser(mockUser: mockUser)
        return UserProfileView(postUser: DBUser(auth: authResultModel, username: "mock user"))
            .environmentObject(UserStore())
    }
}
