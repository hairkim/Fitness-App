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
                let fetchedPosts = try await PostManager.shared.getPosts()
                DispatchQueue.main.async {
                    posts = fetchedPosts
                }
            } catch {
                // Handle the error appropriately in your app
                print("Error fetching posts: \(error)")
            }
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
                            CommentSheetView(post: $post)
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

struct CommentSheetView: View {
    @Binding var post: Post
    @State private var newCommentText = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(post.comments.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(post.comments[index].username)
                                .font(.headline)
                            Text(post.comments[index].text)
                        }
                    }
                }

                HStack {
                    TextField("Add a comment...", text: $newCommentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: addComment) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                            .padding()
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
            }
            .navigationBarTitle("Comments", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }

    private func addComment() {
        guard !newCommentText.isEmpty else { return }
        let newComment = Comment(username: "Current User", text: newCommentText)
        post.comments.append(newComment)
        newCommentText = ""
    }
}

extension DateFormatter {
    static var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environmentObject(UserStore()) // Provide a mock environment object for preview
    }
}
