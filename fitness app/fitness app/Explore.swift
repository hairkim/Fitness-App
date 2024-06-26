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
    @EnvironmentObject var userStore: UserStore

    var body: some View {
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
                    Text("\(post.date, formatter: DateFormatter.shortDate)")
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
            }
            .background(Color(.systemBackground))
            .padding(.bottom, 10)
        }
        .edgesIgnoringSafeArea(.all) // Ensure content ignores safe area
        .background(Color(.systemBackground))
        .overlay(
            HStack {
                Spacer()
                VStack {
                    Button(action: {
                        toggleLike()
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                    }
                    .padding()

                    Button(action: {
                        // Placeholder for comment action
                    }) {
                        Image(systemName: "message")
                            .foregroundColor(.primary)
                    }
                    .padding()

                    Button(action: {
                        // Placeholder for share action
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.primary)
                    }
                    .padding()
                }
            }
            .padding()
            , alignment: .bottomTrailing
        )
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
    static var shortDate: DateFormatter {
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
