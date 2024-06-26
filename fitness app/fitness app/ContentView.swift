// created by the daniel han

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userStore: UserStore
    @State var posts = [Post]()
    
    @State private var showSignInView: Bool = false
    @State private var showImageChooser: Bool = false
    @State private var showDMHomeView: Bool = false
    @State private var selectedTab: Int = 0
    @State private var selectedUser: DBUser? = nil
    @State private var showRotationPage: Bool = false
    
    var body: some View {
        Group {
            if userStore.currentUser == nil {
                LoginView(showSignInView: $showSignInView, userStore: userStore)
            } else if showSignInView == false {
                mainContentView
            }
        }
        .onAppear {
            checkAuthStatus()
            Task {
                await fetchPosts()
            }
        }
        .fullScreenCover(isPresented: $showRotationPage) {
            RotationPageView(showRotationPage: $showRotationPage)
        }
    }
    
    var mainContentView: some View {
        NavigationView {
            ZStack {
                if showDMHomeView {
                    DMHomeView(showDMHomeView: $showDMHomeView)
                        .environmentObject(userStore)
                        .transition(.move(edge: .bottom))
                } else {
                    if selectedTab != 1 {
                        TabView(selection: $selectedTab) {
                            homeView
                                .tabItem {
                                    Image(systemName: "house.fill")
                                    Text("Home")
                                }
                                .tag(0)
                            
                            forumView
                                .tabItem {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                    Text("Forum")
                                }
                                .tag(1)
                            
                            Text("")
                                .tabItem {
                                    Image(systemName: "")
                                    Text("")
                                }
                                .disabled(true)
                            
                            healthView
                                .tabItem {
                                    Image(systemName: "heart.circle.fill")
                                    Text("Health")
                                }
                                .tag(2)
                            
                            profileView
                                .tabItem {
                                    Image(systemName: "person.circle.fill")
                                    Text("Profile")
                                }
                                .tag(3)
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
                                .offset(y: -10)
                                Spacer()
                            }
                        }
                    } else {
                        forumView
                    }
                }
            }
            .fullScreenCover(isPresented: $showImageChooser) {
                ImageChooser()
            }
            .background(
                NavigationLink(
                    destination: UserProfileView(postUser: selectedUser ?? DBUser.placeholder),
                    isActive: .constant(selectedUser != nil),
                    label: { EmptyView() }
                )
            )
        }
    }
    
    var homeView: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Plates")
                        .font(.title)
                        .foregroundColor(Color(.darkGray))
                        .padding(.leading, 16)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showDMHomeView.toggle()
                        }
                    }) {
                        Image(systemName: "message.fill")
                            .imageScale(.large)
                            .foregroundColor(Color(.darkGray))
                            .padding(.trailing, 16)
                    }
                    
                    NavigationLink(destination: SearchView(selectedUser: $selectedUser)) {
                        Image(systemName: "magnifyingglass")
                            .imageScale(.large)
                            .foregroundColor(Color(.darkGray))
                    }
                    .padding(.trailing, 16)
                }
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(posts.indices, id: \.self) { index in
                            CustomPostView(userStore: userStore, post: $posts[index], deleteComment: { comment in
                                deleteComment(comment, at: index)
                            })
                        }
                    }
                    .padding()
                }
            }
            .background(Color.white)
            .navigationTitle("")
        }
    }
    
    var forumView: some View {
        NavigationView {
            ForumView()
                .navigationBarItems(leading: Button(action: {
                    withAnimation {
                        selectedTab = 0
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                })
        }
    }
    
    var healthView: some View {
        NavigationView {
            HealthView()
        }
    }
    
    var profileView: some View {
        NavigationView {
            ProfileView(showSignInView: $showSignInView)
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
                        
                        let rotationConfirmedKey = "hasConfirmedRotation-\(authUser.uid)"
                        if !UserDefaults.standard.bool(forKey: rotationConfirmedKey) {
                            showRotationPage = true
                        }
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
            var fetchedPosts = try await PostManager.shared.getPosts()
            fetchedPosts.sort { $0.date > $1.date }
            self.posts = fetchedPosts
        } catch {
            print("Error fetching posts: \(error)")
        }
    }
}

struct CustomPostView: View {
    @Binding var post: Post
    let deleteComment: (Comment) -> Void
    private let userStore: UserStore
    
    @State private var isLiked = false
    @State private var showCommentSheet = false
    
    @State private var comments: [Comment]
    @State private var postUser: DBUser = DBUser.placeholder
    @State private var likesCount: Int = 0
    
    init(userStore: UserStore, post: Binding<Post>, deleteComment: @escaping (Comment) -> Void) {
        self.userStore = userStore
        self._post = post
        self.deleteComment = deleteComment
        self._comments = State(initialValue: post.wrappedValue.comments)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .stroke(Color.indigo, lineWidth: 2)
                        .frame(width: 32, height: 32)
                    
                    NavigationLink(destination: UserProfileView(postUser: postUser)) {
                        Text(post.username)
                            .font(.headline)
                            .foregroundColor(Color(.darkGray))
                    }
                    
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
                
                HStack {
                    HStack(spacing: 20) {
                        Button(action: {
                            withAnimation {
                                self.isLiked.toggle()
                                Task {
                                    if isLiked {
                                        try await PostManager.shared.incrementLikes(postId: post.id)
                                    } else {
                                        try await PostManager.shared.decrementLikes(postId: post.id)
                                    }
                                    likesCount = try await PostManager.shared.getLikes(postId: post.id)
                                }
                            }
                        }) {
                            Image(systemName: "dumbbell")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(isLiked ? .green : Color(.darkGray))
                        }
                        
                        Text("\(likesCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            withAnimation {
                                showCommentSheet.toggle()
                            }
                        }) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color(.darkGray))
                        }
                        
                        Text("\(comments.count + comments.flatMap { $0.replies }.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text(formatTimestamp(post.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
                
                Text(post.caption)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                
                if comments.count > 0 {
                    Button(action: {
                        withAnimation {
                            showCommentSheet.toggle()
                        }
                    }) {
                        Text("View comments")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(8)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 5)
            .onAppear {
                Task {
                    await loadPostUser()
                    likesCount = try await PostManager.shared.getLikes(postId: post.id)
                }
            }
        }
        .sheet(isPresented: $showCommentSheet) {
            CommentsSheetView(comments: $comments, postId: post.id, postUser: postUser, deleteComment: deleteComment, showCommentSheet: $showCommentSheet)
        }
    }
    
    private func loadPostUser() async {
        do {
            let fetchedUser = try await UserManager.shared.getUser(userId: post.userId)
            DispatchQueue.main.async {
                self.postUser = fetchedUser
            }
        } catch {
            DispatchQueue.main.async {
                print("error loading post's user \(error)")
            }
        }
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
    
    private func formatTimestamp(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

import SwiftUI

struct CommentView: View {
    @Binding var comment: Comment
    let postId: UUID
    let postUser: DBUser
    let deleteComment: (Comment) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(comment.username): \(comment.text)")
                        .foregroundColor(.primary)
                    Text(timeAgoSinceDate(comment.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {
                    deleteComment(comment)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 8)
            
            HStack {
                Button(action: {
                    withAnimation {
                        comment.isReplying.toggle()
                    }
                }) {
                    Text(comment.isReplying ? "Cancel" : "Reply")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            
            if comment.replies.count > 0 {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            comment.showReplies.toggle()
                        }
                    }) {
                        Text(comment.showReplies ? "Hide replies" : "View replies")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
            
            if comment.showReplies {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(comment.replies.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(comment.replies[index].username): \(comment.replies[index].text)")
                                    .foregroundColor(.primary)
                                Text(timeAgoSinceDate(comment.replies[index].date))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                deleteComment(comment.replies[index])
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.leading, 16) // Indent replies
                    }
                }
                .padding(.leading, 16)
            }
            
            if comment.isReplying {
                HStack {
                    TextField("Write a reply...", text: $comment.replyText, onCommit: {
                        Task {
                            await addReply()
                        }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)
                    
                    Button(action: {
                        Task {
                            await addReply()
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func addReply() async {
        if !comment.replyText.isEmpty {
            let newReply = Comment(username: postUser.username, text: comment.replyText)
            comment.replies.append(newReply)
            comment.replyText = ""
            comment.isReplying = false
            comment.showReplies = true
            // Save the reply to the server or database if necessary
        }
    }
}

struct CommentsSheetView: View {
    @Binding var comments: [Comment]
    let postId: UUID
    let postUser: DBUser
    let deleteComment: (Comment) -> Void
    @Binding var showCommentSheet: Bool
    
    @State private var newCommentText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(comments.indices, id: \.self) { index in
                            CommentView(comment: $comments[index], postId: postId, postUser: postUser, deleteComment: deleteComment)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }
                    }
                }
                
                HStack {
                    TextField("Add a comment...", text: $newCommentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Button(action: {
                        Task {
                            await addComment()
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
            }
            .navigationBarTitle("Comments", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                showCommentSheet = false
            })
        }
    }
    
    private func addComment() async {
        if !newCommentText.isEmpty {
            do {
                let newComment = Comment(username: postUser.username, text: newCommentText)
                comments.append(newComment)
                newCommentText = ""
                // Save the comment to the server or database if necessary
            } catch {
                print("error adding comment \(error)")
            }
        }
    }
}


func timeAgoSinceDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute, .second], from: date, to: now)
    
    if let weeks = components.weekOfYear, weeks > 0 {
        return "\(weeks)w"
    } else if let days = components.day, days > 0 {
        return "\(days)d"
    } else if let hours = components.hour, hours > 0 {
        return "\(hours)h"
    } else {
        return "just now"
    }
}




struct RotationPageView: View {
    @Binding var showRotationPage: Bool
    
    var body: some View {
        RotationMainView(showRotationPage: $showRotationPage)
            .onDisappear {
                showRotationPage = false
            }
    }
}

struct RotationMainView: View {
    @Binding var showRotationPage: Bool
    
    var body: some View {
        NavigationView {
            RotationInstructionsView(showRotationPage: $showRotationPage)
        }
    }
}

struct RotationInstructionsView: View {
    @Binding var showRotationPage: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Welcome to the Workout Scheduler")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("To stay consistent and not skip a day at the gym, please select the days you would like to work out each week.")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            NavigationLink(destination: RotationWorkoutCalendarView(showRotationPage: $showRotationPage)) {
                Text("Choose Workout Days")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            Spacer()
        }
        .padding()
    }
}

struct RotationWorkoutCalendarView: View {
    @Binding var showRotationPage: Bool
    @State private var currentDate = Date()
    @State private var selectedDates: [Date] = []
    @State private var showConfirmDialog = false
    @State private var numberOfDaysSelected = 0
    @State private var showFinalConfirmationView = false
    
    private var currentMonthAndYear: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: currentDate)
    }
    
    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
              let range = calendar.range(of: .day, in: .month, for: currentDate) else {
            return []
        }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    private var weeks: [[Date?]] {
        let calendar = Calendar.current
        var weeks: [[Date?]] = [[]]
        guard let firstDay = daysInMonth.first else { return weeks }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        for _ in 1..<firstWeekday {
            weeks[0].append(nil)
        }
        
        for date in daysInMonth {
            if weeks[weeks.count - 1].count == 7 {
                weeks.append([date])
            } else {
                weeks[weeks.count - 1].append(date)
            }
        }
        
        while weeks[weeks.count - 1].count < 7 {
            weeks[weeks.count - 1].append(nil)
        }
        
        return weeks
    }
    
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func dateTapped(_ date: Date) {
        if selectedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
            selectedDates.removeAll { Calendar.current.isDate($0, inSameDayAs: date) }
        } else {
            if selectedDates.count >= 7 {
                selectedDates.removeFirst()
            }
            selectedDates.append(date)
        }
        print("Selected dates: \(selectedDates)")
    }
    
    private func confirmSelection() {
        numberOfDaysSelected = selectedDates.count
        showConfirmDialog = true
    }
    
    var body: some View {
        VStack {
            header
            daysOfWeek
            calendarGrid
            confirmButton
            Spacer()
        }
        .padding()
        .alert(isPresented: $showConfirmDialog) {
            Alert(
                title: Text("Confirm Selection"),
                message: Text("You have selected \(numberOfDaysSelected) days within the week. Do you want to proceed?"),
                primaryButton: .default(Text("Yes"), action: {
                    showFinalConfirmationView = true
                }),
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showFinalConfirmationView) {
            RotationFinalConfirmationView(numberOfDaysSelected: numberOfDaysSelected, selectedDates: selectedDates, showRotationPage: $showRotationPage)
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .padding()
            }
            Spacer()
            Text(currentMonthAndYear)
                .font(.title)
                .padding()
            Spacer()
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .padding()
            }
        }
    }
    
    private var daysOfWeek: some View {
        HStack {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
    
    private var calendarGrid: some View {
        VStack(spacing: 5) {
            ForEach(weeks, id: \.self) { week in
                HStack(spacing: 5) {
                    ForEach(week, id: \.self) { date in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isDateSelected(date) ? Color.blue.opacity(0.2) : Color.white)
                                )
                                .frame(height: 50)
                            
                            if let date = date {
                                Button(action: {
                                    dateTapped(date)
                                }) {
                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.clear)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    private func isDateSelected(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let calendar = Calendar.current
        let selectedWeekdays = Set(selectedDates.map { calendar.component(.weekday, from: $0) })
        return selectedWeekdays.contains(calendar.component(.weekday, from: date))
    }
    
    private var confirmButton: some View {
        Button(action: confirmSelection) {
            Text("Confirm")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
}

struct RotationFinalConfirmationView: View {
    let numberOfDaysSelected: Int
    let selectedDates: [Date]
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userStore: UserStore
    @Binding var showRotationPage: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Final Confirmation")
                .font(.largeTitle)
                .padding()
            
            Text("You have selected \(numberOfDaysSelected) days to work out each week.")
                .font(.title2)
            
            List {
                ForEach(selectedDates, id: \.self) { date in
                    Text("\(formattedDate(date))")
                }
            }
            .frame(height: 200)
            
            Button(action: {
                storeSelectedDates()
                if let currentUserId = userStore.currentUser?.id {
                    UserDefaults.standard.set(true, forKey: "hasConfirmedRotation-\(currentUserId)")
                }
                showRotationPage = false
            }) {
                Text("Confirm")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        return dateFormatter.string(from: date)
    }
    
    private func storeSelectedDates() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDatesStrings = selectedDates.map { dateFormatter.string(from: $0) }
        if let currentUserId = userStore.currentUser?.id {
            UserDefaults.standard.set(selectedDatesStrings, forKey: "selectedWorkoutDates-\(currentUserId)")
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
