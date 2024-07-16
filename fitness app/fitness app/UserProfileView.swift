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

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var userStore: UserStore
    
    let postUser: DBUser
    @Binding var chats: [DBChat]
    @State var posts = [Post]()
    @StateObject private var chatViewModel: ChatViewModel
    @State private var showChatView = false
    @State private var isFollowing = false
    @State private var followRequestSent = false
    
    init(postUser: DBUser, userStore: UserStore, chats: Binding<[DBChat]>) {
        self.postUser = postUser
        self._chatViewModel = StateObject(wrappedValue: ChatViewModel(userStore: userStore))
        self._chats = chats
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
                    if isFollowing {
                        Button(action: {
                            Task {
                                await unfollow()
                            }
                        }) {
                            Text("Following")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(10)
                        }
                    } else if followRequestSent {
                        Text("Follow Request Sent")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(10)
                    } else if postUser.isPublic {
                        Button(action: {
                            Task {
                                await follow()
                            }
                        }) {
                            Text("Follow")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            Task {
                                await sendFollowRequest()
                            }
                        }) {
                            Text("Request Follow")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }

                    Button(action: {
                        Task {
                            if let currentUser = userStore.currentUser {
                                try await chatViewModel.checkAndCreateChat(user1: currentUser, user2: postUser)
                                showChatView = true
                            } else {
                                print("Could not find current user")
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

                // Calendar Layout for Gym Posts
                VStack(alignment: .leading) {
                    Text("Gym Posts")
                        .font(.headline)
                        .padding(.leading)

                    CalendarView(posts: posts)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchProfileData()
                checkFollowingStatus()
            }
            .fullScreenCover(isPresented: $showChatView) {
                if let chat = chatViewModel.chat {
                    ChatView(chats: $chats, chat: chat, unreadMessagesCount: .constant(0))
                        .environmentObject(userStore)
                }
            }
        }
    }

    private func follow() async {
        guard let currentUser = userStore.currentUser else {
            print("Current user is nil")
            return
        }
        do {
            try await UserManager.shared.addFollower(sender: currentUser, receiver: postUser)
            isFollowing = true
            print("Follower added successfully")
        } catch {
            print("Error adding follower: \(error.localizedDescription)")
        }
    }

    private func sendFollowRequest() async {
        guard let currentUser = userStore.currentUser else {
            print("Current user is nil")
            return
        }
        do {
            try await UserManager.shared.sendFollowRequest(sender: currentUser, receiver: postUser)
            followRequestSent = true
            print("Follow request sent successfully")
        } catch {
            print("Error sending follow request: \(error.localizedDescription)")
        }
    }

    private func unfollow() async {
        guard let currentUser = userStore.currentUser else {
            print("Current user is nil")
            return
        }
        do {
            try await UserManager.shared.removeFollower(sender: currentUser, receiver: postUser)
            isFollowing = false
            print("Unfollowed successfully")
        } catch {
            print("Error unfollowing: \(error.localizedDescription)")
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

    private func checkFollowingStatus() {
        Task {
            guard let currentUser = userStore.currentUser else { return }
            do {
                isFollowing = try await UserManager.shared.isFollowing(senderId: currentUser.userId, receiverId: postUser.userId)
                if !isFollowing && !postUser.isPublic {
                    followRequestSent = postUser.followRequests.contains(currentUser.userId)
                }
            } catch {
                print("Error checking following status: \(error)")
            }
        }
    }
}


struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = MockUser(uid: "12kjksdfj", email: "mockUser@gmail.com", photoURL: nil)
        let authResultModel = AuthenticationManager.shared.createMockUser(mockUser: mockUser)
        return UserProfileView(postUser: DBUser(auth: authResultModel, username: "mock user"), userStore: UserStore(), chats: .constant([]))
            .environmentObject(UserStore())
    }
}
