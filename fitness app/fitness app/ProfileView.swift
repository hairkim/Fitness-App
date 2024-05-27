import SwiftUI

struct ProfileView: View {
    @Binding var showSignInView: Bool

    // Placeholder data for posts, workouts, and forum posts
    let posts = Array(repeating: "post_placeholder", count: 10) // Replace with your actual placeholder image name
    let workouts = Array(repeating: "workout_placeholder", count: 10)
    let forumPosts = Array(repeating: "forum_post_placeholder", count: 10)

    @State private var selectedTab = 0
    private let tabTitles = ["Calendar", "Workouts", "Forum Posts"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Picture and User Info
                    VStack(spacing: 8) {
                        Image("berger") // Replace with your actual placeholder image name
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: 100, height: 100)
                            .padding(.top)

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
                        ForEach(0..<tabTitles.count) {
                            Text(tabTitles[$0])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // Content based on selected tab
                    if selectedTab == 0 {
                        // Calendar
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                            ForEach(0..<posts.count, id: \.self) { index in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.5)) // Placeholder for calendar days
                                    .frame(height: 50)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                    } else if selectedTab == 1 {
                        // Workouts
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                            ForEach(0..<workouts.count, id: \.self) { index in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.5)) // Placeholder for workout posts
                                    .frame(height: 150)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                    } else if selectedTab == 2 {
                        // Forum Posts
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                            ForEach(0..<forumPosts.count, id: \.self) { index in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.5)) // Placeholder for forum posts
                                    .frame(height: 150)
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
                    NavigationLink(destination: SettingsView(showSignInView: $showSignInView)) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .foregroundColor(.purple)
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
