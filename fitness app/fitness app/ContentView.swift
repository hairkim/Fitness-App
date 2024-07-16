// created by the daniel han

import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    @EnvironmentObject var userStore: UserStore
    @State var posts = [Post]()
    @State var chats = [DBChat]()
    
    @State private var showSignInView: Bool = false
    @State private var showImageChooser: Bool = false
    @State private var showDMHomeView: Bool = false
    @State private var showNotificationView: Bool = false
    @State private var selectedTab: Int = 0
    @State private var selectedUser: DBUser? = nil
    @State private var unreadMessagesCount: Int = 0

    var body: some View {
        Group {
            if userStore.currentUser == nil {
                LoginView(showSignInView: $showSignInView, userStore: userStore)
            } else if !showSignInView {
                mainContentView
            }
        }
        .onAppear {
            checkAuthStatus()
            setupUnreadMessagesListener()
            setupPostsListener()
            requestNotificationPermissions()
        }
    }
    
    var mainContentView: some View {
        NavigationView {
            ZStack {
                if showDMHomeView {
                    DMHomeView(showDMHomeView: $showDMHomeView, chats: $chats, unreadMessagesCount: $unreadMessagesCount)
                        .environmentObject(userStore)
                        .transition(.move(edge: .trailing))
                } else if showNotificationView {
                    NotificationView(userStore: userStore, showNotificationView: $showNotificationView)
                        .environmentObject(userStore)
                        .transition(.move(edge: .trailing))
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
                            
                            exploreView
                                .tabItem {
                                    Image(systemName: "magnifyingglass")
                                    Text("Explore")
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
                    destination: UserProfileView(postUser: selectedUser ?? DBUser.placeholder, userStore: userStore, chats: $chats),
                    isActive: Binding<Bool>(
                        get: { selectedUser != nil },
                        set: { if !$0 { selectedUser = nil } }
                    ),
                    label: { EmptyView() }
                )
            )
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
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
                        ZStack {
                            Image(systemName: "message.fill")
                            if unreadMessagesCount > 0 {
                                Text("\(unreadMessagesCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(5)
                                    .background(Circle().fill(Color.red))
                                    .offset(x: 10, y: -10)
                            }
                        }
                        .imageScale(.large)
                        .foregroundColor(Color(.darkGray))
                    }
                    .padding(.trailing, 16)

                    Button(action: {
                        withAnimation {
                            showNotificationView.toggle()
                        }
                    }) {
                        Image(systemName: "bell.fill")
                            .imageScale(.large)
                            .foregroundColor(Color(.darkGray))
                    }
                    .padding(.trailing, 16)

                    NavigationLink(destination: SearchView(selectedUser: $selectedUser, chats: $chats)) {
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
                            CustomPostView(post: $posts[index], deleteComment: { comment in
                                deleteComment(comment, at: index)
                            }, deletePost: {
                                deletePost(at: index)
                            }, onUsernameTapped: { user in
                                self.selectedUser = user
                            })
                            .environmentObject(userStore)
                            .id(posts[index].id) // Use the post ID to uniquely identify each view
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
    
    var exploreView: some View {
        VStack {
            NavigationView {
                ExploreView()
                    .navigationBarItems(leading: Button(action: {
                        withAnimation {
                            selectedTab = 0
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    })
            }
            .navigationBarBackButtonHidden(true)
            Spacer()
            Divider()
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
    
    private func deletePost(at index: Int) {
        let post = posts[index]
        let db = Firestore.firestore()
        
        db.collection("posts").document(post.id.uuidString).delete { error in
            if let error = error {
                print("Error removing post: \(error)")
            } else {
                // Update local state after successful deletion
                DispatchQueue.main.async {
                    posts.remove(at: index)
                }
            }
        }
    }
    
    private func setupPostsListener() {
        let db = Firestore.firestore()
        db.collection("posts").addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error fetching posts: \(error)")
                return
            }
            
            if let documents = querySnapshot?.documents {
                DispatchQueue.main.async {
                    self.posts = documents.compactMap { try? $0.data(as: Post.self) }
                    self.posts.sort { $0.date > $1.date }
                }
            }
        }
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
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }

    private func setupUnreadMessagesListener() {
        guard let currentUserID = userStore.currentUser?.userId else { return }
        let db = Firestore.firestore()
        
        db.collection("chats")
            .whereField("participants", arrayContains: currentUserID)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error listening to chats: \(error)")
                    return
                }

                guard let documents = querySnapshot?.documents else { return }
                self.chats = documents.compactMap { try? $0.data(as: DBChat.self) }

                self.updateUnreadMessagesCount()
            }
    }

    private func updateUnreadMessagesCount() {
        guard let currentUserID = userStore.currentUser?.userId else { return }
        unreadMessagesCount = chats.reduce(0) { count, chat in
            count + (chat.unreadMessages[currentUserID] ?? 0)
        }
    }
}

import SwiftUI

struct CustomPostView: View {
    @Binding var post: Post
    let deleteComment: (Comment) -> Void
    let deletePost: () -> Void
    let onUsernameTapped: (DBUser) -> Void
    @EnvironmentObject private var userStore: UserStore

    @State private var isLiked = false
    @State private var showCommentSheet = false
    @State private var showActionSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showLikesList = false
    @State private var isCaptionExpanded = false
    @State private var showReportSheet = false

    @State private var comments: [Comment]
    @State private var postUser: DBUser = DBUser.placeholder
    @State private var likesCount: Int = 0
    @State private var isOwnPost: Bool = false
    @State private var captionExceedsTwoLines: Bool = false

    init(post: Binding<Post>, deleteComment: @escaping (Comment) -> Void, deletePost: @escaping () -> Void, onUsernameTapped: @escaping (DBUser) -> Void) {
        self._post = post
        self.deleteComment = deleteComment
        self.deletePost = deletePost
        self.onUsernameTapped = onUsernameTapped
        self._comments = State(initialValue: post.wrappedValue.comments)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
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

                Circle()
                    .stroke(Color.indigo, lineWidth: 2)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle().fill(Color.white).frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                            )
                    )
                    .padding([.top, .leading], 10)
            }

            HStack {
                HStack(spacing: 20) {
                    Button(action: {
                        Task {
                            if isLiked {
                                try await PostManager.shared.decrementLikes(postId: post.id.uuidString, userId: userStore.currentUser!.userId)
                            } else {
                                try await PostManager.shared.incrementLikes(postId: post.id.uuidString, userId: userStore.currentUser!.userId)
                            }
                            isLiked.toggle()
                            likesCount = try await PostManager.shared.getLikes(postId: post.id.uuidString)
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
                        .onTapGesture {
                            showLikesList.toggle()
                        }

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

                HStack {
                    Text(formatTimestamp(post.date))
                        .font(.caption)
                        .foregroundColor(.gray)

                    Button(action: {
                        showActionSheet.toggle()
                    }) {
                        Image(systemName: "ellipsis")
                            .resizable()
                            .frame(width: 20, height: 5)
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                    }
                    .actionSheet(isPresented: $showActionSheet) {
                        actionSheetContent()
                    }
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Delete Post"),
                            message: Text("Are you sure you want to delete this post?"),
                            primaryButton: .destructive(Text("Delete")) {
                                Task {
                                    try await PostManager.shared.deletePost(postId: post.id.uuidString)
                                    deletePost()
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Button(action: {
                        onUsernameTapped(postUser)
                    }) {
                        Text(postUser.username)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Text(firstLineOfCaption(post.caption))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                Text(secondLineOfCaption(post.caption))
                    .foregroundColor(.primary)
                    .lineLimit(isCaptionExpanded ? nil : 1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 0)
                
                if captionExceedsTwoLines {
                    if !isCaptionExpanded {
                        Button(action: {
                            isCaptionExpanded.toggle()
                        }) {
                            Text("more")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.leading, 0)
                    }
                }
            }
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
                likesCount = try await PostManager.shared.getLikes(postId: post.id.uuidString)
                self.isLiked = try await PostManager.shared.checkIfUserLikedPost(postId: post.id.uuidString, userId: userStore.currentUser!.userId)
                self.isOwnPost = post.userId == userStore.currentUser?.userId
                self.captionExceedsTwoLines = doesCaptionExceedTwoLines(post.caption)
            }
        }
        .sheet(isPresented: $showCommentSheet) {
            CommentsSheetView(comments: $comments, postId: post.id, postUser: postUser, currentUser: userStore.currentUser!, deleteComment: deleteComment, showCommentSheet: $showCommentSheet)
        }
        .sheet(isPresented: $showLikesList) {
            LikesListView(postId: post.id.uuidString)
        }
        .sheet(isPresented: $showReportSheet) {
            ReportView(post: post, showReportSheet: $showReportSheet)
        }
    }

    private func actionSheetContent() -> ActionSheet {
        if isOwnPost {
            return ActionSheet(
                title: Text("Actions"),
                buttons: [
                    .destructive(Text("Delete Post")) {
                        showDeleteConfirmation.toggle()
                    },
                    .cancel()
                ]
            )
        } else {
            return ActionSheet(
                title: Text("Actions"),
                buttons: [
                    .default(Text("Report")) {
                        showReportSheet.toggle()
                    },
                    .cancel()
                ]
            )
        }
    }

    private func firstLineOfCaption(_ caption: String) -> String {
        let words = caption.split(separator: " ")
        var firstLine = ""
        for word in words {
            if (firstLine + " " + word).count > 30 { // Adjust the character count threshold as needed
                break
            }
            firstLine += firstLine.isEmpty ? String(word) : " " + word
        }
        return firstLine
    }

    private func secondLineOfCaption(_ caption: String) -> String {
        let words = caption.split(separator: " ")
        var firstLine = ""
        var secondLine = ""
        var onSecondLine = false
        
        for word in words {
            if !onSecondLine && (firstLine + " " + word).count > 30 {
                onSecondLine = true
            }
            if onSecondLine {
                secondLine += secondLine.isEmpty ? String(word) : " " + word
            } else {
                firstLine += firstLine.isEmpty ? String(word) : " " + word
            }
        }
        return secondLine
    }

    private func doesCaptionExceedTwoLines(_ caption: String) -> Bool {
        let words = caption.split(separator: " ")
        var lineCount = 0
        var currentLine = ""
        
        for word in words {
            if (currentLine + " " + word).count > 30 { // Adjust the character count threshold as needed
                lineCount += 1
                currentLine = ""
            }
            currentLine += currentLine.isEmpty ? String(word) : " " + word
        }
        
        return lineCount >= 2
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
        let now = Date()
        let elapsedTime = now.timeIntervalSince(date)

        if elapsedTime < 86400 { // Less than a day
            let hours = Int(elapsedTime / 3600)
            return "\(hours)h ago"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            return dateFormatter.string(from: date)
        }
    }
}

import SwiftUI

struct CommentView: View {
    @Binding var comment: Comment
    let postId: UUID
    let postUser: DBUser
    let deleteComment: (Comment) -> Void
    let currentUser: DBUser
    
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
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            comment.isReplying.toggle()
                        }
                    }) {
                        Text(comment.isReplying ? "Cancel" : "Reply")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    if comment.username == currentUser.username {
                        Menu {
                            Button(role: .destructive) {
                                deleteComment(comment)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.vertical, 8)

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
                        NestedReplyView(reply: $comment.replies[index], postId: postId, postUser: postUser, deleteComment: { reply in
                            deleteComment(reply)
                            comment.replies.removeAll { $0.id == reply.id }
                        }, currentUser: currentUser, parentUsername: comment.username)
                        .padding(.leading, 16)
                    }
                }
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
            let newReply = Comment(username: currentUser.username, text: "@\(comment.username) \(comment.replyText)")
            comment.replies.append(newReply)
            comment.replyText = ""
            comment.isReplying = false
            comment.showReplies = true
        }
    }
}

struct NestedReplyView: View {
    @Binding var reply: Comment
    let postId: UUID
    let postUser: DBUser
    let deleteComment: (Comment) -> Void
    let currentUser: DBUser
    let parentUsername: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(reply.username): \(reply.text)")
                    .foregroundColor(.primary)
                Text(timeAgoSinceDate(reply.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        reply.isReplying.toggle()
                    }
                }) {
                    Text(reply.isReplying ? "Cancel" : "Reply")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                if reply.username == currentUser.username {
                    Menu {
                        Button(role: .destructive) {
                            deleteComment(reply)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)

        if reply.isReplying {
            HStack {
                TextField("Write a reply...", text: $reply.replyText, onCommit: {
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

        if reply.showReplies {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(reply.replies.indices, id: \.self) { index in
                    NestedReplyView(reply: $reply.replies[index], postId: postId, postUser: postUser, deleteComment: { nestedReply in
                        deleteComment(nestedReply)
                        reply.replies.removeAll { $0.id == nestedReply.id }
                    }, currentUser: currentUser, parentUsername: reply.username)
                    .padding(.leading, 16)
                }
            }
        }
    }

    private func addReply() async {
        if !reply.replyText.isEmpty {
            let newReply = Comment(username: currentUser.username, text: "@\(parentUsername) \(reply.replyText)")
            reply.replies.append(newReply)
            reply.replyText = ""
            reply.isReplying = false
            reply.showReplies = true
        }
    }
}

struct CommentsSheetView: View {
    @Binding var comments: [Comment]
    let postId: UUID
    let postUser: DBUser
    let currentUser: DBUser
    let deleteComment: (Comment) -> Void
    @Binding var showCommentSheet: Bool
    
    @State private var newCommentText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(comments.indices, id: \.self) { index in
                            CommentView(comment: $comments[index], postId: postId, postUser: postUser, deleteComment: { comment in
                                deleteComment(comment)
                                comments.removeAll { $0.id == comment.id }
                            }, currentUser: currentUser)
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
            let newComment = Comment(username: currentUser.username, text: newCommentText)
            comments.append(newComment)
            newCommentText = ""
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


// struct RotationPageView: View {
//     @Binding var showRotationPage: Bool
//
//     var body: some View {
//         RotationMainView(showRotationPage: $showRotationPage)
//             .onDisappear {
//                 showRotationPage = false
//             }
//     }
// }
//
// struct RotationMainView: View {
//     @Binding var showRotationPage: Bool
//
//     var body: some View {
//         NavigationView {
//             RotationInstructionsView(showRotationPage: $showRotationPage)
//         }
//     }
// }
//
// struct RotationInstructionsView: View {
//     @Binding var showRotationPage: Bool
//
//     var body: some View {
//         VStack(spacing: 20) {
//             Spacer()
//             Text("Welcome to the Workout Scheduler")
//                 .font(.largeTitle)
//                 .multilineTextAlignment(.center)
//                 .padding(.horizontal)
//
//             Text("To stay consistent and not skip a day at the gym, please select the days you would like to work out each week.")
//                 .font(.title2)
//                 .multilineTextAlignment(.center)
//                 .padding()
//
//             NavigationLink(destination: RotationWorkoutCalendarView(showRotationPage: $showRotationPage)) {
//                 Text("Choose Workout Days")
//                     .padding()
//                     .background(Color.blue)
//                     .foregroundColor(.white)
//                     .cornerRadius(8)
//             }
//             Spacer()
//         }
//         .padding()
//     }
// }
//
// struct RotationWorkoutCalendarView: View {
//     @Binding var showRotationPage: Bool
//     @State private var currentDate = Date()
//     @State private var selectedDates: [Date] = []
//     @State private var showConfirmDialog = false
//     @State private var numberOfDaysSelected = 0
//     @State private var showFinalConfirmationView = false
//
//     private var currentMonthAndYear: String {
//         let dateFormatter = DateFormatter()
//         dateFormatter.dateFormat = "MMMM yyyy"
//         return dateFormatter.string(from: currentDate)
//     }
//
//     private var daysInMonth: [Date] {
//         let calendar = Calendar.current
//         guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
//               let range = calendar.range(of: .day, in: .month, for: currentDate) else {
//             return []
//         }
//         return range.compactMap { day in
//             calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
//         }
//     }
//
//     private var weeks: [[Date?]] {
//         let calendar = Calendar.current
//         var weeks: [[Date?]] = [[]]
//         guard let firstDay = daysInMonth.first else { return weeks }
//
//         let firstWeekday = calendar.component(.weekday, from: firstDay)
//
//         for _ in 1..<firstWeekday {
//             weeks[0].append(nil)
//         }
//
//         for date in daysInMonth {
//             if weeks[weeks.count - 1].count == 7 {
//                 weeks.append([date])
//             } else {
//                 weeks[weeks.count - 1].append(date)
//             }
//         }
//
//         while weeks[weeks.count - 1].count < 7 {
//             weeks[weeks.count - 1].append(nil)
//         }
//
//         return weeks
//     }
//
//     private func previousMonth() {
//         if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
//             currentDate = newDate
//         }
//     }
//
//     private func nextMonth() {
//         if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
//             currentDate = newDate
//         }
//     }
//
//     private func dateTapped(_ date: Date) {
//         if selectedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
//             selectedDates.removeAll { Calendar.current.isDate($0, inSameDayAs: date) }
//         } else {
//             if selectedDates.count >= 7 {
//                 selectedDates.removeFirst()
//             }
//             selectedDates.append(date)
//         }
//         print("Selected dates: \(selectedDates)")
//     }
//
//     private func confirmSelection() {
//         numberOfDaysSelected = selectedDates.count
//         showConfirmDialog = true
//     }
//
//     var body: some View {
//         VStack {
//             header
//             daysOfWeek
//             calendarGrid
//             confirmButton
//             Spacer()
//         }
//         .padding()
//         .alert(isPresented: $showConfirmDialog) {
//             Alert(
//                 title: Text("Confirm Selection"),
//                 message: Text("You have selected \(numberOfDaysSelected) days within the week. Do you want to proceed?"),
//                 primaryButton: .default(Text("Yes"), action: {
//                     showFinalConfirmationView = true
//                 }),
//                 secondaryButton: .cancel()
//             )
//         }
//         .sheet(isPresented: $showFinalConfirmationView) {
//             RotationFinalConfirmationView(numberOfDaysSelected: numberOfDaysSelected, selectedDates: selectedDates, showRotationPage: $showRotationPage)
//         }
//     }
//
//     private var header: some View {
//         HStack {
//             Button(action: previousMonth) {
//                 Image(systemName: "chevron.left")
//                     .padding()
//             }
//             Spacer()
//             Text(currentMonthAndYear)
//                 .font(.title)
//                 .padding()
//             Spacer()
//             Button(action: nextMonth) {
//                 Image(systemName: "chevron.right")
//                     .padding()
//             }
//         }
//     }
//
//     private var daysOfWeek: some View {
//         HStack {
//             ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
//                 Text(day)
//                     .frame(maxWidth: .infinity)
//                     .padding()
//             }
//         }
//     }
//
//     private var calendarGrid: some View {
//         VStack(spacing: 5) {
//             ForEach(weeks, id: \.self) { week in
//                 HStack(spacing: 5) {
//                     ForEach(week, id: \.self) { date in
//                         ZStack {
//                             RoundedRectangle(cornerRadius: 8)
//                                 .stroke(Color.gray, lineWidth: 1)
//                                 .background(
//                                     RoundedRectangle(cornerRadius: 8)
//                                         .fill(isDateSelected(date) ? Color.blue.opacity(0.2) : Color.white)
//                                 )
//                                 .frame(height: 50)
//
//                             if let date = date {
//                                 Button(action: {
//                                     dateTapped(date)
//                                 }) {
//                                     Text("\(Calendar.current.component(.day, from: date))")
//                                         .frame(maxWidth: .infinity, maxHeight: .infinity)
//                                         .background(Color.clear)
//                                         .cornerRadius(8)
//                                 }
//                                 .buttonStyle(PlainButtonStyle())
//                             }
//                         }
//                         .frame(maxWidth: .infinity)
//                     }
//                 }
//             }
//         }
//     }
//
//     private func isDateSelected(_ date: Date?) -> Bool {
//         guard let date = date else { return false }
//         let calendar = Calendar.current
//         let selectedWeekdays = Set(selectedDates.map { calendar.component(.weekday, from: $0) })
//         return selectedWeekdays.contains(calendar.component(.weekday, from: date))
//     }
//
//     private var confirmButton: some View {
//         Button(action: confirmSelection) {
//             Text("Confirm")
//                 .padding()
//                 .background(Color.blue)
//                 .foregroundColor(.white)
//                 .cornerRadius(8)
//         }
//         .padding()
//     }
// }
//
// struct RotationFinalConfirmationView: View {
//     let numberOfDaysSelected: Int
//     let selectedDates: [Date]
//     @Environment(\.presentationMode) var presentationMode
//     @EnvironmentObject var userStore: UserStore
//     @Binding var showRotationPage: Bool
//
//     var body: some View {
//         VStack(spacing: 20) {
//             Text("Final Confirmation")
//                 .font(.largeTitle)
//                 .padding()
//
//             Text("You have selected \(numberOfDaysSelected) days to work out each week.")
//                 .font(.title2)
//
//             List {
//                 ForEach(selectedDates, id: \.self) { date in
//                     Text("\(formattedDate(date))")
//                 }
//             }
//             .frame(height: 200)
//
//             Button(action: {
//                 storeSelectedDates()
//                 if let currentUserId = userStore.currentUser?.id {
//                     UserDefaults.standard.set(true, forKey: "hasConfirmedRotation-\(currentUserId)")
//                 }
//                 showRotationPage = false
//             }) {
//                 Text("Confirm")
//                     .padding()
//                     .background(Color.blue)
//                     .foregroundColor(.white)
//                     .cornerRadius(8)
//             }
//             .padding()
//         }
//         .padding()
//     }
//
//     private func formattedDate(_ date: Date) -> String {
//         let dateFormatter = DateFormatter()
//         dateFormatter.dateStyle = .full
//         return dateFormatter.string(from: date)
//     }
//
//     private func storeSelectedDates() {
//         let dateFormatter = DateFormatter()
//         dateFormatter.dateFormat = "yyyy-MM-dd"
//         let selectedDatesStrings = selectedDates.map { dateFormatter.string(from: $0) }
//         if let currentUserId = userStore.currentUser?.id {
//             UserDefaults.standard.set(selectedDatesStrings, forKey: "selectedWorkoutDates-\(currentUserId)")
//         }
//     }
// }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        ContentView()
            .environmentObject(userStore)
    }
}
