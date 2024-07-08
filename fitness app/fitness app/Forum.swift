//
//  Forum.swift
//  fitnessapp
//
//  Created by Ryan Kim on 5/22/24.
//
import SwiftUI
import AVKit
import PhotosUI

// Main Forum View
struct ForumView: View {
    @EnvironmentObject var userStore: UserStore
    @State private var posts: [ForumPost] = []
    @State private var isShowingQuestionForm = false
    @State private var isShowingFilters = false
    @State private var selectedSortOption: SortOption = .hot
    @State private var searchText: String = ""

    var body: some View {
        VStack(spacing: 0) { // Adjust the spacing here
            SearchBar(text: $searchText, placeholder: "Search questions")
                .padding(.horizontal)

            List {
                ForEach(filteredPosts) { post in
                    ForumPostRow(post: post, onLike: {
                        await likePost(post: post)
                    }, onNavigate: {
                        navigateToDetail(post: post)
                    })
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navigateToDetail(post: post)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .padding(.top, -8) // Adjust the padding here

            NavigationLink(destination: CreateQuestionView(onAddQuestion: addQuestion), isActive: $isShowingQuestionForm) {
                EmptyView()
            }
        }
        .navigationTitle("Gym Forum")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: {
            isShowingFilters.toggle()
        }) {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .imageScale(.large)
        })
        .background(Color(.systemBackground))
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { isShowingQuestionForm = true }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    Spacer()
                }
            }
        )
        .sheet(isPresented: $isShowingFilters) {
            FilterView(selectedSortOption: $selectedSortOption)
        }
        .onAppear {
            Task {
                self.posts = try await ForumManager.shared.getAllForumPosts()
                print("forum psots fetched")
//                print(self.posts.count)
            }
        }
    }

    private var sortedPosts: [ForumPost] {
        switch selectedSortOption {
        case .hot:
            return posts.sorted(by: { $0.likes.count > $1.likes.count && $0.createdAt > $1.createdAt })
        case .topDay:
            return posts.filter { $0.createdAt > Calendar.current.date(byAdding: .day, value: -1, to: Date())! }
                .sorted(by: { $0.likes.count > $1.likes.count })
        case .topWeek:
            return posts.filter { $0.createdAt > Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())! }
                .sorted(by: { $0.likes.count > $1.likes.count })
        case .topMonth:
            return posts.filter { $0.createdAt > Calendar.current.date(byAdding: .month, value: -1, to: Date())! }
                .sorted(by: { $0.likes.count > $1.likes.count })
        case .topYear:
            return posts.filter { $0.createdAt > Calendar.current.date(byAdding: .year, value: -1, to: Date())! }
                .sorted(by: { $0.likes.count > $1.likes.count })
        case .topAllTime:
            return posts.sorted(by: { $0.likes.count > $1.likes.count })
        }
    }

    private var filteredPosts: [ForumPost] {
        if searchText.isEmpty {
            return sortedPosts
        } else {
            return sortedPosts.filter { post in
                post.title.lowercased().contains(searchText.lowercased()) || post.body.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    //------------------------

    private func addQuestion(title: String, body: String, media: [MediaItem], link: URL?) async {
        guard let username = userStore.currentUser?.username else {
            print("couldnt find username")
            return
        }
        guard let userId = userStore.currentUser?.userId else {
            print("couldnt find userid")
            return
        }
        do {
            let newPost = ForumPost(userId: userId, username: username, title: title, body: body, replies: [], media: media, link: link)
            try await ForumManager.shared.createNewForumPost(forumPost: newPost)
            isShowingQuestionForm = false // Hide the question form after adding the post
            print("Post created successfully")
        } catch {
            print("couldnt create question post \(error)")
        }
    }

    private func likePost(post: ForumPost) async {
        guard let forumPostId = post.id else {
            print("couldnt find forum post id")
            return
        }
        guard let userId = userStore.currentUser?.userId else {
            print("couldnt find user id")
            return
        }
        do {
            if let index = posts.firstIndex(where: { $0.id == forumPostId }) {
                try await ForumManager.shared.likePost(for: forumPostId, userId: userId)
                print("liked the post")
            }
        } catch {
            print("couldnt like the post: \(error)")
        }
    }

    private func likeReply(_ reply: Reply, in post: ForumPost) async {
        guard let replyId = reply.id else {
            print("Couldn't find post id")
            return
        }
        guard let userId = userStore.currentUser?.userId else {
            print("Couldnt get the user id")
            return
        }
        do {
            if let postIndex = posts.firstIndex(where: { $0.id == post.id }) {
                try await ForumManager.shared.likeReply(userId: userId, for: reply, in: post)
            }
        } catch {
            print("couldnt like reply")
        }
    }

    private func findReplyIndex(_ replyID: String, in replies: inout [Reply]) -> Int? {
        for (index, item) in replies.enumerated() {
            if item.id == replyID {
                return index
            } else if let nestedIndex = findReplyIndex(replyID, in: &replies[index].replies) {
                return nestedIndex
            }
        }
        return nil
    }
    
    func addReply(to post: ForumPost, reply: Reply) async {
        do {
            if posts.contains(where: { $0.id == post.id }) {
                try await ForumManager.shared.createNewReply(for: post, reply: reply)
                print("reply added")
            }
        } catch {
            print("couldnt add reply")
        }
    }

    func addReply(to parentReply: Reply, in post: ForumPost, reply: Reply) async {
        guard let parentReplyId = parentReply.id else {
            print("Couldn't find post id")
            return
        }
        do {
            if let postIndex = posts.firstIndex(where: { $0.id == post.id }) {
                try await ForumManager.shared.createNewReply(for: parentReply, reply: reply)
                print("created child reply")
            }
        } catch {
            print("couldnt add reply: \(error)")
        }
    }

    private func navigateToDetail(post: ForumPost) {
        let destination = PostDetailView(post: post, onReply: { reply in
            await addReply(to: post, reply: reply)
        }, onLike: {
            await likePost(post: post)
        }, onReplyToReply: { parentReply, reply in
            await addReply(to: parentReply, in: post, reply: reply)
        }, onLikeReply: { reply in
            await likeReply(reply, in: post)
        })
        .environmentObject(userStore)

        if let window = UIApplication.shared.windows.first {
            window.rootViewController?.show(UIHostingController(rootView: destination), sender: nil)
        }
    }
}

// Forum Post Row View
struct ForumPostRow: View {
    @EnvironmentObject var userStore: UserStore
    @ObservedObject var post: ForumPost
    @State private var likedByUser: Bool = false
    let onLike: () async -> Void
    let onNavigate: () -> Void

    var body: some View {
        Button(action: onNavigate) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(post.username)
                        .font(.headline)
                        .foregroundColor(.blue)
                    Spacer()
                    HStack(spacing: 15) {
                        Button(action: {
                            Task {
                                await onLike()
                            }
                        }) {
                            HStack {
                                Image(systemName: likedByUser ? "heart.fill" : "heart")
                                    .foregroundColor(likedByUser ? .red : .gray)
                                Text("\(post.likes.count)")
                            }
                        }
                        HStack {
                            Image(systemName: "bubble.right.fill")
                                .foregroundColor(.gray)
                            Text("\(post.replies.count)")
                        }
                    }
                }

                Text(post.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(post.body)
                    .font(.body)
                    .foregroundColor(.secondary)

                if let link = post.link {
                    Link("Related Link", destination: link)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                ForEach(post.media) { media in
                    if media.type == .image {
                        Image(uiImage: UIImage(contentsOfFile: media.url.path) ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    } else if media.type == .video {
                        VideoPlayer(player: AVPlayer(url: media.url))
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle()) // This removes the default button styling
        .onAppear {
            checkIfUserLiked()
        }
    }
    
    private func checkIfUserLiked() {
        guard let userId = userStore.currentUser?.userId else {
            print("couldnt get user's id while checking if they liked")
            return
        }
        
        if self.post.likes.contains(where: { $0 == userId }) {
            self.likedByUser = true
        }
    }
}

// Post Detail View
struct PostDetailView: View {
    @EnvironmentObject var userStore: UserStore
    @ObservedObject var post: ForumPost
    let onReply: (Reply) async -> Void
    let onLike: () async -> Void
    let onReplyToReply: (Reply, Reply) async -> Void
    let onLikeReply: (Reply) async -> Void
    @State private var newReply = ""
    @State private var selectedMediaItems: [MediaItem] = []
    @State private var replyingTo: Reply?
    @State private var likedByUser: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.vertical, 8) // Adjust vertical padding
                        .padding(.horizontal, 12) // Adjust horizontal padding
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading) {
                    ForumPostRow(post: post, onLike: onLike, onNavigate: {})
                        .onTapGesture(count: 2) {
                            Task {
                                await onLike()
                            }
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            MediaPickerButton(selectedMediaItems: $selectedMediaItems)
                                .frame(width: 20, height: 20)
                                .padding(.leading, 8)

                            TextField("Add a reply...", text: $newReply)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .onSubmit {
                                    Task {
                                        await addReply()
                                    }
                                }

                            Button(action: {
                                Task {
                                    await addReply()
                                }
                            }){
                                Image(systemName: "arrow.up.circle.fill")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(newReply.isEmpty ? .gray : .blue)
                            }
                            .disabled(newReply.isEmpty)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 4)

                    ForEach(post.replies) { reply in
                        ReplyView(reply: reply, onReplyToReply: { parentReply, newReply in
                            await onReplyToReply(parentReply, newReply)
                        }, onLikeReply: { likedReply in
                            await onLikeReply(likedReply)
                        })
                        .padding(.leading, 20) // Add this line to indent replies
                    }
                }
                .padding()
            }
            .navigationTitle("Post Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                Task {
                    onLike
                }
            }) {
                Image(systemName: "heart.fill")
                    .foregroundColor(likedByUser ? .gray : .red)
            })
        }
        .onAppear {
            checkIfUserLiked()
        }
    }

    private func addReply() async {
        guard !newReply.isEmpty else { return }
        guard let postId = post.id else {
            print("couldnt get post id [1234]")
            return
        }
        guard let username = userStore.currentUser?.username else {
            print("couldnt get user id [24432]")
            return
        }

        let replyText: String
        if let replyingTo = replyingTo {
            replyText = "@\(replyingTo.username) \(newReply)"
        } else {
            replyText = newReply
        }

        let reply = Reply(forumPostId: postId, username: username, replyText: replyText, media: selectedMediaItems)

        if let replyingTo = replyingTo {
            await onReplyToReply(replyingTo, reply)
        } else {
            await onReply(reply)
        }

        newReply = ""
        selectedMediaItems = []
        replyingTo = nil
    }
    
    private func checkIfUserLiked() {
        guard let userId = userStore.currentUser?.userId else {
            print("couldnt get user's id while checking if they liked")
            return
        }
        
        if self.post.likes.contains(where: { $0 == userId }) {
            self.likedByUser = true
        }
    }
}

// Reply View
struct ReplyView: View {
    @EnvironmentObject var userStore: UserStore
    @ObservedObject var reply: Reply
    let onReplyToReply: (Reply, Reply) async -> Void
    let onLikeReply: (Reply) async -> Void
    @State private var showReplyField = false
    @State private var newReplyText = ""
    @State private var selectedMediaItems: [MediaItem] = []
    @State private var likedByUser: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(reply.username)
                    .font(.subheadline)
                    .foregroundColor(.green)
                Spacer()
                HStack(spacing: 20) {
                    Button(action: { 
                        Task {
                            await onLikeReply(reply)
                        }
                    }) {
                        HStack {
                            Image(systemName: likedByUser ? "heart.fill" : "heart")
                                .foregroundColor(likedByUser ? .red : .gray)
                            Text("\(reply.likes.count)")
                        }
                    }
                    Button(action: { showReplyField.toggle() }) {
                        Text("Reply")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.trailing, 10)
            }

            Text(reply.replyText)
                .font(.body)

            ForEach(reply.media) { media in
                if media.type == .image {
                    Image(uiImage: UIImage(contentsOfFile: media.url.path) ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .cornerRadius(10)
                } else if media.type == .video {
                    VideoPlayer(player: AVPlayer(url: media.url))
                        .frame(height: 100)
                        .cornerRadius(10)
                }
            }

            if showReplyField {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        MediaPickerButton(selectedMediaItems: $selectedMediaItems)
                            .frame(width: 20, height: 20)
                            .padding(.leading, 8)

                        TextField("Add a reply...", text: $newReplyText)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onSubmit {
                                Task {
                                    await postReply()
                                }
                            }

                        Button(action: {
                            Task {
                                await postReply()
                            }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(newReplyText.isEmpty ? .gray : .blue)
                        }
                        .disabled(newReplyText.isEmpty)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding(.vertical, 4)
            }

            ForEach(reply.replies) { nestedReply in
                ReplyView(reply: nestedReply, onReplyToReply: onReplyToReply, onLikeReply: onLikeReply)
                    .padding(.leading, 20) // Add this line to indent nested replies
            }
        }
        .padding(.vertical, 4)
        .background(Color.clear) // Remove gray background
        .cornerRadius(10) // Round corners for better aesthetics
        .padding(.bottom, 8) // Add bottom padding for spacing between replies
    }

    private func postReply() async {
        guard !newReplyText.isEmpty else { return }
        do {
            let newReply = Reply(forumPostId: reply.forumPostId, username: "CurrentUser", replyText: "@\(reply.username) \(newReplyText)", media: selectedMediaItems)
            await onReplyToReply(reply, newReply)
            newReplyText = ""
            selectedMediaItems = []
            showReplyField = false
        }
    }
}

// Media Picker Button
struct MediaPickerButton: View {
    @EnvironmentObject var userStore: UserStore
    @Binding var selectedMediaItems: [MediaItem]
    @State private var isPresentingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideo: URL?

    var body: some View {
        Button(action: { isPresentingImagePicker = true }) {
            Image(systemName: "photo")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(.blue)
        }
        .sheet(isPresented: $isPresentingImagePicker) {
            CustomImagePicker(selectedImages: $selectedImages, selectedVideo: $selectedVideo)
                .onDisappear {
                    for image in selectedImages {
                        if let url = saveImage(image) {
                            selectedMediaItems.append(MediaItem(type: .image, url: url))
                        }
                    }
                    if let videoURL = selectedVideo {
                        selectedMediaItems.append(MediaItem(type: .video, url: videoURL))
                    }
                    selectedImages = []
                    selectedVideo = nil
                }
        }
    }

    private func saveImage(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 1) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        return url
    }
}

// Custom Image Picker
struct CustomImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideo: URL?

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        var parent: CustomImagePicker

        init(_ parent: CustomImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                        if let image = object as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(image)
                            }
                        }
                    }
                } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { (url, error) in
                        if let url = url {
                            DispatchQueue.main.async {
                                self.parent.selectedVideo = url
                            }
                        }
                    }
                }
            }
        }
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 0
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}

// Filter View
struct FilterView: View {
    @Binding var selectedSortOption: SortOption

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sort by")) {
                    Picker("Sort by", selection: $selectedSortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }

    private func dismiss() {
        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
    }
}

// SearchBar View
struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

// Preview Provider
struct ForumView_Previews: PreviewProvider {
    static var previews: some View {
        ForumView()
    }
}

