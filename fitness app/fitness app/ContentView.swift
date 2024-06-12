//
//  ContentView.swift
//  FitnessApp
//
//  Created by Harris Kim on 10/30/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userStore: UserStore
    @State var posts = [Post]()
    
    @State private var showSignInView: Bool = false
    @State private var showImageChooser: Bool = false
    @State private var showDMHomeView: Bool = false
    
    var body: some View {
        Group {
            if userStore.currentUser == nil {
                LoginView(showSignInView: $showSignInView, userStore: userStore)
            } else {
                mainContentView
            }
        }
        .onAppear {
            checkAuthStatus()
            Task {
                await fetchPosts()
            }
        }
    }
    
    var mainContentView: some View {
        ZStack {
            TabView {
                NavigationView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Plates")
                                .font(.title)
                                .foregroundColor(Color(.darkGray))
                                .padding(.leading, 16)
                            
                            Spacer()
                            
                            NavigationLink(destination: DirectMessagesView()) {
                                Image(systemName: "message.fill")
                                    .imageScale(.large)
                                    .foregroundColor(Color(.darkGray))
                                    .padding(.trailing, 16)
                            }
                        }
                        .padding(.horizontal)

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
                    }
                    .navigationTitle("")
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                
                NavigationView {
                    HealthView()
                }
                .tabItem {
                    Image(systemName: "heart.circle.fill")
                    Text("Health")
                }
                
                // Placeholder for the post button
                Text("")
                    .tabItem {
                        Image(systemName: "")
                        Text("")
                    }
                    .disabled(true)
                
                NavigationView {
                    NutritionView()
                }
                .tabItem {
                    Image(systemName: "leaf.circle.fill")
                    Text("Nutrition")
                }
                
                NavigationView {
                    ProfileView(showSignInView: $showSignInView)
                }
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showImageChooser = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color(.darkGray))
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .offset(y: -10) // Adjust the offset to position the button properly
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showImageChooser) {
            ImageChooser()
        }
    }
    
    private func deleteComment(_ comment: Comment, at index: Int) {
        posts[index].comments.removeAll(where: { $0.id == comment.id })
    }
    
    func checkAuthStatus() {
        Task {
            let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
            if let authUser = authUser {
                if let dbUser = try? await UserManager.shared.getUser(userId: authUser.uid) {
                    await MainActor.run {
                        userStore.setCurrentUser(user: dbUser)
                        showSignInView = false
                    }
                } else {
                    await MainActor.run {
                        showSignInView = true
                    }
                }
            } else {
                await MainActor.run {
                    showSignInView = true
                }
            }
        }
    }
    
    private func fetchPosts() async {
        do {
            self.posts = try await PostManager.shared.getPosts()
            print("Posts fetched")
        } catch {
            print("Error fetching posts: \(error)")
        }
    }
}

struct DirectMessagesView: View {
    var body: some View {
        Text("Direct Messages")
            .font(.largeTitle)
            .foregroundColor(Color(.darkGray))
    }
}

struct NutritionView: View {
    var body: some View {
        Text("Nutrition")
            .font(.largeTitle)
            .foregroundColor(Color(.darkGray))
    }
}

struct PlaceholderView: View {
    let pageName: String
    
    var body: some View {
        Text(pageName)
            .font(.largeTitle)
            .foregroundColor(Color(.darkGray))
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
                    .stroke(Color.indigo, lineWidth: 2)
                    .frame(width: 32, height: 32)
                
                Text(post.username)
                    .font(.headline)
                    .foregroundColor(Color(.darkGray))
                
                if post.multiplePictures {
                    Text("📷")
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: {
                    print("More options button tapped")
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color(.darkGray))
                }
            }

            ZStack(alignment: .topTrailing) {
                if let url = URL(string: post.imageName) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "x.circle.fill")
                                .resizable()
                                .scaledToFit()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: 400)
                                .clipped()
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                        @unknown default:
                            Image(systemName: "x.circle.fill")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
                
                HStack {
                    Text(post.workoutSplit)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(getColorForWorkoutSplit(post.workoutSplit))
                        .cornerRadius(10)
                    
                    Text(post.workoutSplitEmoji)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(getColorForWorkoutSplit(post.workoutSplit))
                        .cornerRadius(10)
                }
                .offset(x: -10, y: 10)
            }

            HStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        self.isLiked.toggle()
                        self.animateLike.toggle()
                    }
                }) {
                    Image(systemName: "dumbbell")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(isLiked ? .green : Color(.darkGray))
                        .rotationEffect(Angle(degrees: animateLike ? 30 : 0))
                }
                
                Button(action: {
                    self.isCommenting.toggle()
                }) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color(.darkGray))
                }
            }
            .padding(.horizontal, 16)

            Text(post.caption)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            ForEach(post.comments) { comment in
                HStack {
                    Text("\(comment.username): \(comment.text)")
                        .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    Button(action: {
                        deleteComment(comment)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .padding(.trailing, 16)
                }
            }
            
            if isCommenting {
                TextField("Write a comment...", text: $commentText, onCommit: {
                    Task {
                        await addComment(postId: post.id, username: post.username, text: commentText)
                    }
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
    
    private func getColorForWorkoutSplit(_ workoutSplit: String) -> Color {
        switch workoutSplit {
        case "Push":
            return Color.indigo.opacity(0.8)
        case "Pull":
            return Color.indigo.opacity(0.8)
        case "Legs":
            return Color.green.opacity(0.8)
        default:
            return Color.white.opacity(0.8)
        }
    }
    
    private func addComment(postId: UUID, username: String, text: String) async  {
        do {
            try await PostManager.shared.addComment(postId: postId, username: username, comment: text)
            commentText = ""
            isCommenting = false
        } catch {
            print("error making comment \(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        ContentView()
            .environmentObject(userStore)
    }
}
