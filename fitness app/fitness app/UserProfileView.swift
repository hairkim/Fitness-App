//
//  UserProfileView.swift
//  fitnessapp
//
//  Created by Harris Kim on 6/5/24.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var userStore: UserStore
    
    let postUser: DBUser
    @State var posts = [Post]() // Using the same Post structure
    @State var leaderboard = [LeaderboardEntryProfile(name: "JohnDoe", streak: 100), LeaderboardEntryProfile(name: "JaneDoe", streak: 200)]
    @State var healthTracker = [HealthPlaceholderEntryProfile(metric: "Calories", value: 1200), HealthPlaceholderEntryProfile(metric: "Steps", value: 10000)]

    @State private var selectedTab = 0
    private let tabTitles = ["Posts", "Leaderboard", "Health Tracker"]

    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture and User Info
            VStack(spacing: 8) {
                if let photoUrl = postUser.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .clipShape(Circle())
                    .frame(width: 100, height: 100)
                    .padding(.top)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .frame(width: 100, height: 100)
                        .padding(.top)
                }

                Text(postUser.username)
                    .font(.title)
                    .fontWeight(.bold)

                Text(postUser.email ?? "Email not available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top)

            // Follow Button
            Button(action: {
                Task {
                    await addFollower()
                }
            }) {
                Text("Follow")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            // Tabs
            Picker("Select Tab", selection: $selectedTab) {
                ForEach(0..<tabTitles.count, id: \.self) {
                    Text(tabTitles[$0])
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Content based on selected tab
            if selectedTab == 0 {
                // Posts (Calendar)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(posts) { post in
                        Rectangle()
                            .fill(Color.gray.opacity(0.5)) // Placeholder for calendar days
                            .frame(height: 50)
                            .cornerRadius(10)
                    }
                }
                .padding()
            } else if selectedTab == 1 {
                // Leaderboard
                LeaderboardViewProfile(leaderboardData: leaderboard)
                    .padding()
            } else if selectedTab == 2 {
                // Health Tracker
                HealthViewProfile(healthDataModel: HealthDataModelProfile())
            }

            Spacer()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchProfileData()
        }
    }

    private func addFollower() async {
        guard let currentUser = userStore.currentUser else {
            print("Current user is nil")
            return
        }
        do {
            try await UserManager.shared.addFollower(sender: currentUser, receiver: postUser)
            print("Follower added successfully")
        } catch {
            print("Error adding follower: \(error.localizedDescription)")
        }
    }

    private func fetchProfileData() {
        Task {
            do {
                self.posts = try await PostManager.shared.getPosts(forUser: postUser.userId)
                // Placeholder for now, replace with actual data fetching later
                // self.leaderboard = try await LeaderboardManager.shared.getEntries(forUser: postUser.userId)
                // self.healthTracker = try await HealthTrackerManager.shared.getEntries(forUser: postUser.userId)
            } catch {
                print("Error fetching profile data: \(error)")
            }
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = MockUser(uid: "12kjksdfj", email: "mockUser@gmail.com", photoURL: nil)
        let authResultModel = AuthenticationManager.shared.createMockUser(mockUser: mockUser)
        return UserProfileView(postUser: DBUser(auth: authResultModel, username: "mock user"))
            .environmentObject(UserStore())
    }
}
