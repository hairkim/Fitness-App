//
//  ProfileView.swift
//  FitnessApp
//
//  Created by Harris Kim on 2/4/24.
import SwiftUI

import SwiftUI

struct ProfileView: View {
    @Binding var showSignInView: Bool
    
    // Placeholder data for posts
    let posts = Array(repeating: "post_placeholder", count: 21) // Replace "post_placeholder" with your actual placeholder image name
    @State private var expandedRow: Int? = nil
    
    private let columns = [GridItem](repeating: .init(.flexible()), count: 5)
    
    var body: some View {
        NavigationView {
            VStack {
                // Profile Picture and User Info
                VStack(spacing: 8) {
                    Image("berger") // Replace with your actual placeholder image name
                        .resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .frame(width: 100, height: 100)
                    
                    Text("Berger")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("I like burgers.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Statistics Section
                    HStack(spacing: 40) {
                        VStack {
                            Text("Streaks")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("10")
                                .font(.headline)
                        }
                        
                        VStack {
                            Text("Followers")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("250")
                                .font(.headline)
                        }
                        
                        VStack {
                            Text("Following")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("180")
                                .font(.headline)
                        }
                    }
                    .padding(.top)
                }
                .padding(.top)
                
                // Posts Grid
                ScrollView {
                    VStack {
                        ForEach(0..<(posts.count / 5 + (posts.count % 5 == 0 ? 0 : 1)), id: \.self) { rowIndex in
                            if expandedRow == rowIndex {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(rowIndex * 5..<min((rowIndex + 1) * 5, posts.count), id: \.self) { index in
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.5)) // Placeholder for image
                                                .frame(height: 200) // Adjust size as needed
                                                .frame(width: 200)
                                                .cornerRadius(10)
                                                .shadow(radius: 5)
                                                .onTapGesture {
                                                    expandedRow = nil // Collapse the row
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                HStack(spacing: 10) {
                                    ForEach(rowIndex * 5..<min((rowIndex + 1) * 5, posts.count), id: \.self) { index in
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.5)) // Placeholder for image
                                            .frame(height: 50) // Adjust size as needed
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                            .onTapGesture {
                                                expandedRow = rowIndex // Expand the row
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView(showSignInView: $showSignInView)) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .foregroundColor(.purple)
                            .padding(.trailing, 16)
                    }
                }
            }
        }
    }
}

//struct SettingsView: View {
//    @Binding var showSignInView: Bool
//
//    var body: some View {
//        Text("Settings View")
//            .navigationTitle("Settings")
//    }
//}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView(showSignInView: .constant(false))
        }
    }
}



////
//import SwiftUI
//
//@MainActor
//final class ProfileViewModel: ObservableObject {
//    @Published private(set) var user: DBUser? = nil
//
//    func loadCurrentUser() async throws {
//        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
//        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
//    }
//}
//
//struct ProfileView: View {
//    @StateObject private var viewModel = ProfileViewModel()
//    @Binding var showSignInView: Bool
//
//    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                if let user = viewModel.user {
//                    // Profile Picture and User Info
//                    VStack(spacing: 16) {
//                        Image("profile_placeholder")
//                            .resizable()
//                            .scaledToFit()
//                            .clipShape(Circle())
//                            .frame(width: 100, height: 100)
//
//                        Text(user.username)
//                            .font(.title)
//                            .fontWeight(.bold)
//
////                        Text(user.bio ?? "Welcome to my profile!")
////                            .font(.subheadline)
////                            .foregroundColor(.gray)
////                            .multilineTextAlignment(.center)
////                            .padding(.horizontal)
//
//                        // Statistics Section
//                        HStack(spacing: 40) {
//                            VStack {
//                                Text("Posts")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                Text("\(user.posts.count)")
//                                    .font(.headline)
//                            }
//
//                            VStack {
//                                Text("Followers")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                Text("\(user.followers.count)")
//                                    .font(.headline)
//                            }
//
//                            VStack {
//                                Text("Following")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                Text("\(user.following.count)")
//                                    .font(.headline)
//                            }
//                        }
//                        .padding(.top)
//                    }
//                    .padding(.top)
//
//                    // Posts Grid
//                    ScrollView {
//                        LazyVGrid(columns: columns, spacing: 16) {
//                            ForEach(user.posts) { post in
//                                NavigationLink(destination: PostDetailView(post: post)) {
//                                    Image(post.imageName)
//                                        .resizable()
//                                        .scaledToFit()
//                                        .cornerRadius(10)
//                                        .shadow(radius: 5)
//                                }
//                            }
//                        }
//                        .padding()
//                    }
//                } else {
//                    Text("No user found")
//                        .font(.title)
//                        .foregroundColor(.gray)
//                }
//            }
//            .navigationTitle("Profile")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    NavigationLink(destination: SettingsView(showSignInView: $showSignInView)) {
//                        Image(systemName: "gear")
//                            .imageScale(.large)
//                            .foregroundColor(.purple)
//                            .padding(.trailing, 16)
//                    }
//                }
//            }
//            .task {
//                try? await viewModel.loadCurrentUser()
//            }
//        }
//    }
//}
//
//struct PostDetailView: View {
//    let post: Post
//
//    var body: some View {
//        VStack {
//            Image(post.imageName)
//                .resizable()
//                .scaledToFit()
//                .cornerRadius(10)
//                .shadow(radius: 5)
//                .padding()
//
//            Text(post.caption)
//                .font(.headline)
//                .padding()
//
//            Spacer()
//        }
//        .navigationTitle("Post Detail")
//    }
//}
//
//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            ProfileView(showSignInView: .constant(false))
//        }
//    }
//}
