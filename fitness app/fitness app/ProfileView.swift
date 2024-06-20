import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userStore: UserStore
    @Binding var showSignInView: Bool

    @State private var posts = [Post]() // Replace with your Post structure
    @State private var leaderboard = [
        LeaderboardEntry(username: "JohnDoe", streak: 30),
        LeaderboardEntry(username: "JaneDoe", streak: 25),
        LeaderboardEntry(username: "JimBeam", streak: 20)
    ]

    var body: some View {
        NavigationView {
            ScrollView { // Added ScrollView
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
                            .frame(width: 120, height: 120) // Slightly larger profile picture
                            .padding(.top)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .frame(width: 120, height: 120) // Slightly larger profile picture
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
                                Text("Streak")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("4 weeks") // Placeholder value
                                    .font(.headline)
                            }

                            VStack {
                                Text("Friends")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("210") // Placeholder value
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
                .padding(.horizontal) // Add horizontal padding to match the design
                .edgesIgnoringSafeArea(.top) // Extend the view to the top edge
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
                    self.posts = try await PostManager.shared.getPosts(forUser: currentUser.userId)
                }
            } catch {
                print("Error fetching profile data: \(error)")
            }
        }
    }
}

struct CalendarView: View {
    let posts: [Post]
    
    // Generate a list of dates for the current month
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
                        .font(.system(size: 14, weight: .medium)) // Adjust font size
                        .frame(width: 40, height: 50)
                        .background(Color.gray.opacity(0.2)) // Slightly lighter background color
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
    let streak: Int
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
                    Text("\(entry.streak) days")
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
                .environmentObject(UserStore()) // Provide an instance of UserStore for preview
        }
    }
}
