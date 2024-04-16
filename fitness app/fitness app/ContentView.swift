//
//  ContentView.swift
//  FitnessApp
//
//  Created by Harris Kim on 10/30/23.
//

import SwiftUI

struct Comment: Identifiable {
    let id: UUID = UUID()
    let username: String
    let text: String
}

struct Post: Identifiable {
    let id: UUID = UUID()
    let username: String
    let imageName: String
    let caption: String
    let multiplePictures: Bool
    let workoutSplit: String
    let workoutSplitEmoji: String
    var comments: [Comment]
}

struct ContentView: View {
    // Example posts data
    @State var posts: [Post] = [
        Post(username: "john_doe", imageName: "post1", caption: "Enjoying the day at the gym! 💪", multiplePictures: false, workoutSplit: "Push", workoutSplitEmoji: "🏋️‍♂️", comments: []),
        Post(username: "jane_smith", imageName: "post2", caption: "Post workout selfie! 🤳", multiplePictures: false, workoutSplit: "Pull", workoutSplitEmoji: "🏋️‍♀️", comments: []),
        Post(username: "user3", imageName: "post3", caption: "Back at it again! 💪", multiplePictures: true, workoutSplit: "Legs", workoutSplitEmoji: "🦵", comments: []),
        // Add more posts as needed
    ]
    
    @State private var showSignInView: Bool = false
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    // Customized top bar
                    HStack {
                        Text("YourApp")
                            .font(.title)
                            .foregroundColor(.purple)
                            .padding(.leading, 16)
                        
                        Spacer()
                        
                        NavigationLink(destination: SettingsView(showSignInView: $showSignInView)) {
                            Image(systemName: "gear")
                                .imageScale(.large)
                                .foregroundColor(.purple)
                                .padding(.trailing, 16)
                        }
                    }
                    .padding(.horizontal)

                    // List of posts with revised layout
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(posts.indices, id: \.self) { index in
                                CustomPostView(post: $posts[index], deleteComment: { comment in
                                    deleteComment(comment, at: index)
                                })
                            }
                        }
                        .padding()
                    }

                    
                    // Profile icon in the refined bottom navigation bar
                    HStack {
                        Spacer()
                        Spacer()
                        //change this so that it goes to the image chooser
                        NavigationLink(destination: ContentView()) {
                            Image(systemName: "plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.purple)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .padding(10)
                        }
                        .padding(.trailing, 20)
                        
                        Spacer() // Pushes the profile icon to the right
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.purple)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .padding(10)
                        }
                        .padding(.trailing, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                            .shadow(radius: 5)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .navigationTitle("") // Empty title
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        // Left side navigation items can be added here if needed
                    }
                }
            }
        }
    }
    
    // Function to delete a comment
    private func deleteComment(_ comment: Comment, at index: Int) {
        posts[index].comments.removeAll(where: { $0.id == comment.id })
    }
}

struct CustomPostView: View {
    @Binding var post: Post
    let deleteComment: (Comment) -> Void
    
    @State private var isLiked = false
    @State private var animateLike = false
    @State private var isCommenting = false
    @State private var commentText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 32, height: 32)
                
                Text(post.username)
                    .font(.headline)
                    .foregroundColor(.purple)
                
                if post.multiplePictures {
                    Text("📷")
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: {
                    // Action for custom button
                    print("More options button tapped")
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.purple)
                }
            }

            // Display post content with custom styling
            ZStack(alignment: .topTrailing) {
                Image(post.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 400) // Adjusted height for more vertical pictures
                    .clipped()
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                
                HStack {
                    Text(post.workoutSplit)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.purple)
                        .cornerRadius(10)
                    
                    Text(post.workoutSplitEmoji)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.purple)
                        .cornerRadius(10)
                }
                .offset(x: -10, y: 10)
            }

            HStack(spacing: 20) {
                Button(action: {
                    // Action for custom post action (like)
                    withAnimation {
                        self.isLiked.toggle()
                        self.animateLike.toggle()
                    }
                }) {
                    Image(systemName: "dumbbell")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(isLiked ? .green : .purple) // Customize colors as needed
                        .rotationEffect(Angle(degrees: animateLike ? 30 : 0))
                }
                
                Button(action: {
                    // Action for custom post action (comment)
                    self.isCommenting.toggle()
                }) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal, 16)

            Text(post.caption)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            // Display existing comments
            ForEach(post.comments) { comment in
                HStack {
                    Text("\(comment.username): \(comment.text)")
                        .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: {
                        deleteComment(comment)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .padding(.trailing, 16)
                }
            }
            
            // Text field to add new comment
            if isCommenting {
                TextField("Write a comment...", text: $commentText, onCommit: {
                    addComment()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
    
    // Function to add a comment
    private func addComment() {
        post.comments.append(Comment(username: "CurrentUser", text: commentText))
        commentText = ""
        isCommenting = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
       ContentView()
    }
}
