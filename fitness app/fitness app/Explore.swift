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
                        ForEach(posts.indices, id: \.self) { index in
                            ExploreItemView(post: $posts[index])
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
    @Binding var post: Post
    @State private var isLiked = false
    @EnvironmentObject var userStore: UserStore

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
                        // Placeholder for comment action
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

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environmentObject(UserStore()) // Provide a mock environment object for preview
    }
}
