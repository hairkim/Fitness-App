import SwiftUI

struct SeshView: View {
    let post: Post
    @State private var liked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let imageUrl = URL(string: post.imageName) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        Rectangle().fill(Color.gray.opacity(0.5))
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle().fill(Color.red.opacity(0.5))
                    @unknown default:
                        Rectangle().fill(Color.gray.opacity(0.5))
                    }
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(10)
            }

            Text(post.caption)
                .font(.body)
                .padding()

            Text("\(post.workoutSplitEmoji) \(post.workoutSplit)")
                .font(.headline)
                .padding(.horizontal)

            HStack {
                Button(action: {
                    liked.toggle()
                    Task {
                        do {
                            if liked {
                                try await PostManager.shared.incrementLikes(postId: post.id.uuidString, userId: post.userId)
                            } else {
                                try await PostManager.shared.decrementLikes(postId: post.id.uuidString, userId: post.userId)
                            }
                        } catch {
                            print("Error updating likes: \(error)")
                        }
                    }
                }) {
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .foregroundColor(liked ? .red : .gray)
                }
                Text("\(post.likes)")
                    .font(.subheadline)
            }
            .padding(.horizontal)

            Text("Comments")
                .font(.headline)
                .padding(.horizontal)

            ForEach(post.comments) { comment in
                VStack(alignment: .leading) {
                    Text(comment.username)
                        .font(.subheadline)
                        .bold()
                    Text(comment.text)
                        .font(.body)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Sesh Details")
    }
}
