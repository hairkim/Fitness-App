//
//  Explore.swift
//  fitnessapp
//
//  Created by Ryan Kim on 6/25/24.
//

import SwiftUI
import FirebaseFirestore

struct ExploreView: View {
    @State private var posts: [Post] = []
    @EnvironmentObject var userStore: UserStore

    var body: some View {
        NavigationView {
            if posts.isEmpty {
                ProgressView("Loading...")
                    .onAppear(perform: loadPosts)
                    .navigationBarHidden(true)
            } else {
                TabView {
                    ForEach(posts.indices, id: \.self) { index in
                        ExploreItemView(post: $posts[index])
                            .environmentObject(userStore)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .navigationBarHidden(true)
            }
        }
    }

    func loadPosts() {
        Task {
            do {
                guard let currentUser = userStore.currentUser else {
                    print("No current user found.")
                    return
                }

                let followedUserIds = try await UserManager.shared.getFollowedUserIds(for: currentUser.id)
                let fetchedPosts = try await PostManager.shared.getPosts()
                let filteredPosts = fetchedPosts.filter { !followedUserIds.contains($0.userId) }
                
                DispatchQueue.main.async {
                    posts = filteredPosts
                }
            } catch {
                print("Error fetching posts: \(error)")
            }
        }
    }
}

struct ExploreItemView: View {
    @Binding var post: Post
    @State private var isLiked = false
    @State private var showCommentSheet = false
    @State private var showShareSheet = false
    @State private var selectedUsers: [DBUser] = []
    @State private var likesCount: Int = 0
    @EnvironmentObject var userStore: UserStore

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if let url = URL(string: post.imageName) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.2)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                                .clipped()
                        case .failure:
                            Color.gray.opacity(0.2)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        @unknown default:
                            Color.gray.opacity(0.2)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                } else {
                    Color.gray.opacity(0.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(post.username)
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(post.date, formatter: DateFormatter.shortDateFormatter)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding([.horizontal, .top])

                    Text(post.caption)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .padding(.horizontal)

                    HStack {
                        Text(post.workoutSplit)
                            .font(.caption)
                        Text(post.workoutSplitEmoji)
                            .font(.caption)
                    }
                    .padding([.horizontal, .bottom])

                    HStack {
                        Button(action: {
                            toggleLike()
                        }) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(isLiked ? .red : .primary)
                        }
                        .padding(.horizontal)
                        
                        Text("\(likesCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .onTapGesture {
                                showLikesList()
                            }

                        Button(action: {
                            showCommentSheet = true
                        }) {
                            Image(systemName: "message")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showCommentSheet) {
                            ExploreCommentsSheetView(
                                comments: $post.comments,
                                postId: post.id,
                                postUser: userStore.currentUser ?? DBUser.placeholder,
                                currentUser: userStore.currentUser ?? DBUser.placeholder,
                                deleteComment: { comment in
                                    post.comments.removeAll { $0.id == comment.id }
                                },
                                showCommentSheet: $showCommentSheet
                            )
                        }

                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showShareSheet) {
                            ShareSheetView(
                                isPresented: $showShareSheet,
                                selectedUsers: $selectedUsers,
                                post: post
                            ).environmentObject(userStore)
                        }
                        
                        Spacer()
                    }
                    .padding([.horizontal, .bottom])
                }
                .background(Color(.systemBackground))
                .padding(.bottom, 10)
            }
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            loadInitialData()
        }
    }

    private func loadInitialData() {
        Task {
            likesCount = try await PostManager.shared.getLikes(postId: post.id.uuidString)
            self.isLiked = try await PostManager.shared.checkIfUserLikedPost(postId: post.id.uuidString, userId: userStore.currentUser!.userId)
        }
    }

    private func toggleLike() {
        isLiked.toggle()
        if isLiked {
            likesCount += 1
        } else {
            likesCount -= 1
        }
        
        Task {
            if isLiked {
                try await PostManager.shared.incrementLikes(postId: post.id.uuidString, userId: userStore.currentUser!.userId)
            } else {
                try await PostManager.shared.decrementLikes(postId: post.id.uuidString, userId: userStore.currentUser!.userId)
            }
        }
    }

    private func showLikesList() {
        // Functionality to show the list of users who liked the post
    }
}

struct ExploreCommentsSheetView: View {
    @Binding var comments: [Comment]
    let postId: UUID
    let postUser: DBUser
    let currentUser: DBUser
    let deleteComment: (Comment) -> Void
    @Binding var showCommentSheet: Bool
    
    @State private var newCommentText = ""

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(comments.indices, id: \.self) { index in
                            ExploreCommentView(comment: $comments[index], postId: postId, postUser: postUser, deleteComment: { comment in
                                deleteComment(comment)
                                comments.removeAll { $0.id == comment.id }
                            }, currentUser: currentUser)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }
                }
                
                HStack {
                    TextField("Add a comment...", text: $newCommentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Button(action: {
                        Task {
                            await addComment()
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
            }
            .navigationBarTitle("Comments", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                showCommentSheet = false
            })
        }
    }
    
    private func addComment() async {
        if !newCommentText.isEmpty {
            let newComment = Comment(username: currentUser.username, text: newCommentText)
            comments.append(newComment)
            newCommentText = ""
        }
    }
}

struct ExploreCommentView: View {
    @Binding var comment: Comment
    let postId: UUID
    let postUser: DBUser
    let deleteComment: (Comment) -> Void
    let currentUser: DBUser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(comment.username): \(comment.text)")
                        .foregroundColor(.primary)
                    Text(exploreTimeAgoSinceDate(comment.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            comment.isReplying.toggle()
                        }
                    }) {
                        Text(comment.isReplying ? "Cancel" : "Reply")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    if comment.username == currentUser.username {
                        Menu {
                            Button(role: .destructive) {
                                deleteComment(comment)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.vertical, 8)

            if comment.replies.count > 0 {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            comment.showReplies.toggle()
                        }
                    }) {
                        Text(comment.showReplies ? "Hide replies" : "View replies")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }

            if comment.showReplies {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(comment.replies.indices, id: \.self) { index in
                        ExploreNestedReplyView(reply: $comment.replies[index], postId: postId, postUser: postUser, deleteComment: { reply in
                            deleteComment(reply)
                            comment.replies.removeAll { $0.id == reply.id }
                        }, currentUser: currentUser, parentUsername: comment.username)
                        .padding(.leading, 16)
                    }
                }
            }

            if comment.isReplying {
                HStack {
                    TextField("Write a reply...", text: $comment.replyText, onCommit: {
                        Task {
                            await addReply()
                        }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)

                    Button(action: {
                        Task {
                            await addReply()
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 4)
    }

    private func addReply() async {
        if !comment.replyText.isEmpty {
            let newReply = Comment(username: currentUser.username, text: "@\(comment.username) \(comment.replyText)")
            comment.replies.append(newReply)
            comment.replyText = ""
            comment.isReplying = false
            comment.showReplies = true
        }
    }
}

struct ExploreNestedReplyView: View {
    @Binding var reply: Comment
    let postId: UUID
    let postUser: DBUser
    let deleteComment: (Comment) -> Void
    let currentUser: DBUser
    let parentUsername: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(reply.username): \(reply.text)")
                    .foregroundColor(.primary)
                Text(exploreTimeAgoSinceDate(reply.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        reply.isReplying.toggle()
                    }
                }) {
                    Text(reply.isReplying ? "Cancel" : "Reply")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                if reply.username == currentUser.username {
                    Menu {
                        Button(role: .destructive) {
                            deleteComment(reply)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)

        if reply.isReplying {
            HStack {
                TextField("Write a reply...", text: $reply.replyText, onCommit: {
                    Task {
                        await addReply()
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 8)

                Button(action: {
                    Task {
                        await addReply()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
                .padding(.trailing, 16)
            }
            .padding(.horizontal, 16)
        }

        if reply.showReplies {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(reply.replies.indices, id: \.self) { index in
                    ExploreNestedReplyView(reply: $reply.replies[index], postId: postId, postUser: postUser, deleteComment: { nestedReply in
                        deleteComment(nestedReply)
                        reply.replies.removeAll { $0.id == nestedReply.id }
                    }, currentUser: currentUser, parentUsername: reply.username)
                    .padding(.leading, 16)
                }
            }
        }
    }

    private func addReply() async {
        if !reply.replyText.isEmpty {
            let newReply = Comment(username: currentUser.username, text: "@\(parentUsername) \(reply.replyText)")
            reply.replies.append(newReply)
            reply.replyText = ""
            reply.isReplying = false
            reply.showReplies = true
        }
    }
}

func exploreTimeAgoSinceDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute, .second], from: date, to: now)
    
    if let weeks = components.weekOfYear, weeks > 0 {
        return "\(weeks)w"
    } else if let days = components.day, days > 0 {
        return "\(days)d"
    } else if let hours = components.hour, hours > 0 {
        return "\(hours)h"
    } else {
        return "just now"
    }
}

struct ShareSheetView: View {
    @Binding var isPresented: Bool
    @Binding var selectedUsers: [DBUser]
    @State private var allUsers: [DBUser] = []
    let post: Post
    @EnvironmentObject var userStore: UserStore
    
    var body: some View {
        NavigationView {
            VStack {
                List(allUsers, id: \.id) { user in
                    HStack {
                        Text(user.username)
                        Spacer()
                        if selectedUsers.contains(where: { $0.id == user.id }) {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
                            selectedUsers.remove(at: index)
                        } else {
                            selectedUsers.append(user)
                        }
                    }
                }
                .navigationBarTitle("Share Post", displayMode: .inline)
                .onAppear(perform: loadUsers)

                Button(action: {
                    sharePostWithSelectedUsers()
                }) {
                    Text("Send")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
    }
    
    func loadUsers() {
        Task {
            do {
                let users = try await UserManager.shared.getAllUsers()
                DispatchQueue.main.async {
                    allUsers = users
                }
            } catch {
                print("Error loading users: \(error)")
            }
        }
    }
    
    func sharePostWithSelectedUsers() {
        Task {
            guard let currentUserId = userStore.currentUser?.id else {
                print("No current user logged in.")
                return
            }
            for user in selectedUsers {
                if let chat = try? await ChatManager.shared.getChatBetweenUsers(user1Id: currentUserId, user2Id: user.id) {
                    try await ChatManager.shared.sendPostMessage(chatId: chat.id!, senderId: currentUserId, receiverId: user.id, post: post)
                } else {
                    var newChat = DBChat(participants: [currentUserId, user.id], participantNames: [currentUserId: userStore.currentUser?.username ?? "", user.id: user.username])
                    try await ChatManager.shared.createNewChat(chat: &newChat)
                    try await ChatManager.shared.sendPostMessage(chatId: newChat.id!, senderId: currentUserId, receiverId: user.id, post: post)
                }
            }
            isPresented = false
        }
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environmentObject(UserStore()) // Provide a mock environment object for preview
    }
}

extension DateFormatter {
    static var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}
