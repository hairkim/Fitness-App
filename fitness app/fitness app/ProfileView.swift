import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userStore: UserStore
    @Binding var showSignInView: Bool

    @State private var posts = [Post]()
    @State private var leaderboard = [LeaderboardEntry]()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(alignment: .center, spacing: 10) {
                        if let photoUrl = userStore.currentUser?.photoUrl, let url = URL(string: photoUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                @unknown default:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                            .clipShape(Circle())
                            .frame(width: 120, height: 120)
                            .padding(.top)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .frame(width: 120, height: 120)
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

                        // Statistics Section with Placeholders
                        HStack(spacing: 40) {
                            VStack {
                                Text("Sesh")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(userStore.currentUser?.sesh ?? 0) sessions")
                                    .font(.headline)
                            }

                            VStack {
                                Text("Followers")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(userStore.currentUser?.followers.count ?? 0)")
                                    .font(.headline)
                            }
                        }
                    }
                    .padding(.top)

                    // Calendar Layout for Gym Posts
                    VStack(alignment: .leading) {
                        Text("Gym Posts")
                            .font(.headline)
                            .padding(.leading)

                        CalendarView(posts: posts)
                    }
                    .padding()

                    // Leaderboard Section
                    LeaderboardView(leaderboardData: leaderboard)
                    .padding()

                    // Diet and Calories Section
                    VStack(alignment: .leading) {
                        Text("Diet & Calories")
                            .font(.headline)
                            .padding(.leading)

                        DietCaloriesView()
                    }
                    .padding()

                    // Health Tracker Section
                    VStack(alignment: .leading) {
                        Text("Health Tracker")
                            .font(.headline)
                            .padding(.leading)

                        HealthTrackerView()
                    }
                    .padding()
                }
                .padding(.horizontal)
                .edgesIgnoringSafeArea(.top)
            }
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
                    // Fetch current user's posts
                    self.posts = try await PostManager.shared.getPosts(forUser: currentUser.userId)
                    
                    // Fetch current user's friends
                    let friendsIds = currentUser.followers
                    var friends = [DBUser]()
                    
                    for friendId in friendsIds {
                        let friend = try await UserManager.shared.getUser(userId: friendId)
                        friends.append(friend)
                    }
                    
                    // Include current user in the leaderboard
                    var allUsers = friends
                    allUsers.append(currentUser)
                    
                    // Sort users based on sesh count
                    allUsers.sort { $0.sesh > $1.sesh }
                    
                    // Update leaderboard entries
                    self.leaderboard = allUsers.map { user in
                        LeaderboardEntry(username: user.username, sesh: user.sesh)
                    }
                }
            } catch {
                print("Error fetching profile data: \(error)")
            }
        }
    }
}

struct CalendarView: View {
    let posts: [Post]
    
    private var dates: [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: Date()) {
                dates.append(date)
            }
        }
        return dates
    }
    
    private func postForDate(_ date: Date) -> Post? {
        return posts.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
            ForEach(dates, id: \.self) { date in
                if let post = postForDate(date) {
                    AsyncImage(url: URL(string: post.imageName)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 40, height: 50)
                                .cornerRadius(10)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 50)
                                .clipped()
                                .cornerRadius(10)
                        case .failure:
                            Rectangle()
                                .fill(Color.red.opacity(0.5))
                                .frame(width: 40, height: 50)
                                .cornerRadius(10)
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 40, height: 50)
                                .cornerRadius(10)
                        }
                    }
                } else {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 40, height: 50)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let username: String
    let sesh: Int
}

struct LeaderboardView: View {
    let leaderboardData: [LeaderboardEntry]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Leaderboard")
                .font(.headline)
                .padding(.leading)

            ForEach(leaderboardData) { entry in
                HStack {
                    Text(entry.username)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(entry.sesh) sessions")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 5)
                .padding(.horizontal)
                Divider()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct DietCaloriesView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Calories")
                    .font(.headline)
                Spacer()
                Text("1,690 Remaining")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .padding(.bottom, 5)
            
            Divider()
            
            HStack {
                Text("Food")
                    .font(.headline)
                Spacer()
                Text("0")
                    .font(.subheadline)
            }
            .padding(.bottom, 5)
            
            HStack {
                Text("Exercise")
                    .font(.headline)
                Spacer()
                Text("0")
                    .font(.subheadline)
            }
            .padding(.bottom, 5)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct HealthTrackerView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Steps")
                    .font(.headline)
                Spacer()
                Text("3,848 / 10,000")
                    .font(.subheadline)
            }
            .padding(.bottom, 5)
            
            Divider()
            
            HStack {
                Text("Weight")
                    .font(.headline)
                Spacer()
                Text("210 lbs")
                    .font(.subheadline)
            }
            .padding(.bottom, 5)
            
            Divider()
            
            HStack {
                Text("Exercise")
                    .font(.headline)
                Spacer()
                Text("0 cal")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView(showSignInView: .constant(false))
                .environmentObject(UserStore())
        }
    }
}
