import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userStore: UserStore
    @Binding var showSignInView: Bool

    @State var posts = [Post]() // Using the same Post structure
    @State var leaderboard = [LeaderboardEntry(name: "JohnDoe", streak: 100), LeaderboardEntry(name: "JaneDoe", streak: 200)]
    @State var healthTracker = [HealthPlaceholderEntry(metric: "Calories", value: 1200), HealthPlaceholderEntry(metric: "Steps", value: 10000)]

    @State private var selectedTab = 0
    private let tabTitles = ["Posts", "Leaderboard", "Health Tracker"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Picture and User Info
                    VStack(spacing: 8) {
                        if let photoUrl = userStore.currentUser?.photoUrl, let url = URL(string: photoUrl) {
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

                        Text(userStore.currentUser?.username ?? "Username")
                            .font(.title)
                            .fontWeight(.bold)

                        Text(userStore.currentUser?.email ?? "Email not available")
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
                                Text("4 weeks")
                                    .font(.headline)
                            }

                            VStack {
                                Text("Friends")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("210")
                                    .font(.headline)
                            }
                        }
                    }
                    .padding(.top)

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
                        LeaderboardView(leaderboardData: leaderboard)
                            .padding()
                    } else if selectedTab == 2 {
                        // Health Tracker
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                            ForEach(healthTracker) { entry in
                                VStack {
                                    Text(entry.metric)
                                    Text("\(entry.value)")
                                }
                                .padding()
                                .background(Color.gray.opacity(0.5))
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView(showSignInView: $showSignInView, userStore: userStore)) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .foregroundColor(.purple)
                    }
                }
            }
            .onAppear {
                fetchProfileData()
            }
        }
    }

    private func fetchProfileData() {
        Task {
            do {
                if let currentUser = userStore.currentUser {
                    self.posts = try await PostManager.shared.getPosts(forUser: currentUser.userId)
                    // Placeholder for now, replace with actual data fetching later
                    // self.leaderboard = try await LeaderboardManager.shared.getEntries(forUser: currentUser.userId)
                    // self.healthTracker = try await HealthTrackerManager.shared.getEntries(forUser: currentUser.userId)
                }
            } catch {
                print("Error fetching profile data: \(error)")
            }
        }
    }
}

// Assuming SettingsView takes `showSignInView` and `userStore` as parameters
//struct SettingsView: View {
//    @Binding var showSignInView: Bool
//    @EnvironmentObject var userStore: UserStore
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
                .environmentObject(UserStore()) // Provide an instance of UserStore for preview
        }
    }
}

// Placeholder struct for HealthEntry
struct HealthPlaceholderEntry: Identifiable {
    let id = UUID()
    let metric: String
    let value: Int
}
