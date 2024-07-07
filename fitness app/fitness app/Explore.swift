//
//  Explore.swift
//  fitnessapp
//
//  Created by Ryan Kim on 6/25/24.
//

import SwiftUI

struct ExploreView: View {
    @State private var posts: [Post] = []
    @EnvironmentObject var userStore: UserStore

    var body: some View {
        NavigationView {
            if posts.isEmpty {
                ProgressView("Loading...")
                    .onAppear(perform: loadMockData)
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

    func loadMockData() {
        let mockPosts = [
            Post(
                id: UUID(),
                userId: "user1",
                username: "User 1",
                imageName: "https://via.placeholder.com/150",
                caption: "This is a sample post",
                multiplePictures: false,
                workoutSplit: "Push",
                workoutSplitEmoji: "💪",
                comments: [],
                date: Date(),
                likes: 10
            ),
            Post(
                id: UUID(),
                userId: "user2",
                username: "User 2",
                imageName: "https://via.placeholder.com/150",
                caption: "Another sample post",
                multiplePictures: false,
                workoutSplit: "Pull",
                workoutSplitEmoji: "🏋️‍♂️",
                comments: [],
                date: Date(),
                likes: 5
            )
        ]

        DispatchQueue.main.async {
            posts = mockPosts
        }
    }
}

struct ExploreItemView: View {
    @Binding var post: Post
    @State private var isLiked = false
    @State private var showCommentSheet = false
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
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                        Text(post.workoutSplitEmoji)
                            .font(.caption)
                    }
                    .padding([.horizontal, .bottom])

                    HStack {
                        Button(action: {
                            toggleLike()
                        }) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .primary)
                        }
                        .padding(.horizontal)

                        Button(action: {
                            showCommentSheet = true
                        }) {
                            Image(systemName: "message")
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
                            // Placeholder for share action
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding([.horizontal, .bottom])
                }
                .background(Color(.systemBackground))
                .padding(.bottom, 10)
            }
            .background(Color(.systemBackground))
            .contentShape(Rectangle()) // Make the entire area tappable to avoid issues with the TabView
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func toggleLike() {
        isLiked.toggle()
        if isLiked {
            post.likes += 1
        } else {
            post.likes -= 1
        }
    }
}

extension DateFormatter {
    static var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
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
                    Text(timeAgoSinceDate(comment.date))
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
                Text(timeAgoSinceDate(reply.date))
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

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environmentObject(UserStore()) // Provide a mock environment object for preview
    }
}
