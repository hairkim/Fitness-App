//
//  UserProfileView.swift
//  fitnessapp
//
//  Created by Harris Kim on 6/5/24.
//

import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    private let userStore: UserStore
    @Published var chat: DBChat?
    @Published var errorMessage: String?
    
    init(userStore: UserStore) {
        self.userStore = userStore
    }
    
    func checkAndCreateChat(user1: DBUser, user2: DBUser) async {
        do {
            guard let currentUser = userStore.currentUser else {
                errorMessage = "Couldn't find current user"
                return
            }
            
            let otherUser = currentUser.id == user1.id ? user2 : user1
            
            if let existingChat = try await ChatManager.shared.getChatBetweenUsers(user1Id: user1.userId, user2Id: user2.userId) {
                if let chatId = existingChat.id {
                    print("Existing chat found with ID: \(chatId)")
                } else {
                    print("Couldn't find chat's ID")
                }
                chat = existingChat
            } else {
                print("No chat exists between the users, creating a new one.")
                
                let participantNames = [
                    user1.userId: user1.username,
                    user2.userId: user2.username
                ]
                
                var newChat = DBChat(
                    participants: [user1.userId, user2.userId],
                    participantNames: participantNames,
                    lastMessage: nil,
                    profileImage: nil
                )
                
                do {
                    try await ChatManager.shared.createNewChat(chat: &newChat)
                } catch {
                    errorMessage = "Failed to create new chat: \(error.localizedDescription)"
                    return
                }
                
                do {
                    if let chatRoom = try await ChatManager.shared.getChatBetweenUsers(user1Id: user1.userId, user2Id: user2.userId) {
                        if let chatId = chatRoom.id {
                            print("New chat created successfully with ID: \(chatId)")
                        } else {
                            print("Could not find chat's ID")
                        }
                        chat = chatRoom
                    } else {
                        errorMessage = "Failed to verify the newly created chat."
                    }
                } catch {
                    errorMessage = "Failed to retrieve the newly created chat: \(error.localizedDescription)"
                }
            }
        } catch {
            errorMessage = "Failed to create or fetch chat: \(error.localizedDescription)"
        }
    }

}

struct UserProfileView: View {
    @EnvironmentObject var userStore: UserStore
    
    let postUser: DBUser
    @State var posts = [Post]() // Using the same Post structure
    
    @StateObject private var chatViewModel: ChatViewModel
    
    @State private var showChatView = false
    
    init(postUser: DBUser, userStore: UserStore) {
        self.postUser = postUser
        self._chatViewModel = StateObject(wrappedValue: ChatViewModel(userStore: userStore))
    }

    var body: some View {
        NavigationStack {
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
                
                HStack {
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
                    
//                    if let chat = chatViewModel.chat {
//                        NavigationLink(destination: ChatView(chat: chat)) {
//                            Text("Message")
//                                .font(.headline)
//                                .foregroundColor(.white)
//                                .padding()
//                                .background(Color.blue)
//                                .cornerRadius(10)
//                        }
//                    } else {
//                        
//                    }
                    Button(action: {
                        Task {
                            if let currentUser = userStore.currentUser {
                                await chatViewModel.checkAndCreateChat(user1: currentUser, user2: postUser)
                                showChatView = true
                            } else {
                                print("could not find current user")
                            }
                        }
                    }) {
                        Text("Message")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }

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
            .fullScreenCover(isPresented: $showChatView) {
                if let chat = chatViewModel.chat {
                    ChatView(chat: chat)
                }
            }
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
        return UserProfileView(postUser: DBUser(auth: authResultModel, username: "mock user"), userStore: UserStore())
            .environmentObject(UserStore())
    }
}
