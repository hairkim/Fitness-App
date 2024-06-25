//
//  Explorepage.swift
//  fitnessapp
//
//  Created by Ryan Kim on 6/20/24.
//

import SwiftUI

struct ExploreView: View {
    @State private var posts: [Post] = []
    @EnvironmentObject var userStore: UserStore

    var body: some View {
        NavigationView {
            VStack {
                Text("Explore")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                if posts.isEmpty {
                    ProgressView("Loading...")
                        .onAppear(perform: loadMockData)
                } else {
                    TabView {
                        ForEach(posts) { post in
                            ExploreItemView(post: post)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemBackground))
                                .cornerRadius(15)
                                .shadow(radius: 5)
                                .padding()
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                }
            }
            .navigationBarHidden(true)
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
    @State private var post: Post
    @State private var isLiked = false
    @State private var isCommenting = false
    @State private var showComments = false
    @State private var commentText = ""
    @EnvironmentObject var userStore: UserStore // Add this line to use userStore

    init(post: Post) {
        self._post = State(initialValue: post)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                if let url = URL(string: post.imageName) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .background(Color.gray.opacity(0.2))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .background(Color.gray.opacity(0.2))
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .background(Color.gray.opacity(0.2))
                        @unknown default:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .background(Color.gray.opacity(0.2))
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .background(Color.gray.opacity(0.2))
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        toggleLike()
                    }) {
                        Image(systemName: "heart")
                            .font(.title)
                            .foregroundColor(isLiked ? .red : .white)
                            .shadow(radius: 10)
                    }
                    
                    Button(action: {
                        isCommenting.toggle()
                    }) {
                        Image(systemName: "message")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                    
                    Button(action: {
                        // Share action
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
                .padding()
            }
            .sheet(isPresented: $isCommenting) {
                CommentView(post: $post)
                    .environmentObject(userStore)
            }
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

struct CommentView: View {
    @Binding var post: Post
    @EnvironmentObject var userStore: UserStore
    @State private var commentText = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(post.comments) { comment in
                        VStack(alignment: .leading) {
                            Text(comment.username)
                                .font(.headline)
                            Text(comment.text)
                        }
                    }
                }

                HStack {
                    TextField("Write a comment...", text: $commentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: {
                        addComment()
                    }) {
                        Text("Post")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.trailing)
                }
                .padding()
            }
            .navigationBarTitle("Comments", displayMode: .inline)
        }
    }

    private func addComment() {
        let newComment = Comment(id: UUID(), username: userStore.currentUser?.username ?? "User", text: commentText)
        post.comments.append(newComment)
        commentText = ""
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environmentObject(UserStore()) // Provide a mock environment object for preview
    }
}
