//
//  Forum.swift
//  fitnessapp
//
//  Created by Ryan Kim on 5/22/24.
//

import SwiftUI
import PhotosUI
import AVKit

// Data Models
class ForumPost: Identifiable, ObservableObject {
    let id: UUID = UUID()
    let username: String
    let title: String
    let body: String
    @Published var replies: [Reply]
    let media: [MediaItem]
    let link: URL?
    @Published var likes: Int
    @Published var likedByCurrentUser: Bool
    let createdAt: Date

    init(username: String, title: String, body: String, replies: [Reply] = [], media: [MediaItem] = [], link: URL? = nil, likes: Int = 0, likedByCurrentUser: Bool = false, createdAt: Date = Date()) {
        self.username = username
        self.title = title
        self.body = body
        self.replies = replies
        self.media = media
        self.link = link
        self.likes = likes
        self.likedByCurrentUser = likedByCurrentUser
        self.createdAt = createdAt
    }
}

class Reply: Identifiable, ObservableObject {
    let id: UUID = UUID()
    let username: String
    let replyText: String
    @Published var media: [MediaItem]
    @Published var likes: Int
    @Published var likedByCurrentUser: Bool
    @Published var replies: [Reply]
    let createdAt: Date

    init(username: String, replyText: String, media: [MediaItem] = [], likes: Int = 0, likedByCurrentUser: Bool = false, replies: [Reply] = [], createdAt: Date = Date()) {
        self.username = username
        self.replyText = replyText
        self.media = media
        self.likes = likes
        self.likedByCurrentUser = likedByCurrentUser
        self.replies = replies
        self.createdAt = createdAt
    }
}

struct MediaItem: Identifiable {
    let id: UUID = UUID()
    let type: MediaType
    let url: URL
}

enum MediaType {
    case image
    case video
}

enum SortOption: String, CaseIterable {
    case hot = "Hot"
    case topDay = "Top (Day)"
    case topWeek = "Top (Week)"
    case topMonth = "Top (Month)"
    case topYear = "Top (Year)"
    case topAllTime = "Top (All Time)"
}

// Main Forum View
struct ForumView: View {
    @State private var posts: [ForumPost] = [
        ForumPost(username: "john_doe", title: "Best Chest Exercises", body: "What are the best exercises for chest?")
    ]
    @State private var isShowingQuestionForm = false
    @State private var isShowingFilters = false
    @State private var selectedSortOption: SortOption = .hot

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(sortedPosts) { post in
                        NavigationLink(destination: PostDetailView(post: post, onReply: { reply in
                            addReply(to: post, reply: reply)
                        }, onLike: {
                            likePost(post)
                        }, onReplyToReply: { reply, newReply in
                            addReply(to: reply, in: post, reply: newReply)
                        }, onLikeReply: { reply in
                            likeReply(reply, in: post)
                        })) {
                            ForumPostRow(post: post, onLike: {
                                likePost(post)
                            })
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(PlainListStyle())

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
        }
    }

    private var sortedPosts: [ForumPost] {
        switch selectedSortOption {
        case .hot:
            return posts.sorted(by: { $0.likes > $1.likes && $0.createdAt > $1.createdAt })
        case .topDay:
            return posts.filter { $0.createdAt > Calendar.current.date(byAdding: .day, value: -1, to: Date())! }
                .sorted(by: { $0.likes > $1.likes })
        case .topWeek:
            return posts.filter { $0.createdAt > Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())! }
                .sorted(by: { $0.likes > $1.likes })
        case .topMonth:
            return posts.filter { $0.createdAt > Calendar.current.date(byAdding: .month, value: -1, to: Date())! }
                .sorted(by: { $0.likes > $1.likes })
        case .topYear:
            return posts.filter { $0.createdAt > Calendar.current.date(byAdding: .year, value: -1, to: Date())! }
                .sorted(by: { $0.likes > $1.likes })
        case .topAllTime:
            return posts.sorted(by: { $0.likes > $1.likes })
        }
    }

    private func addQuestion(username: String, title: String, body: String, media: [MediaItem], link: URL?) {
        let newPost = ForumPost(username: username, title: title, body: body, replies: [], media: media, link: link)
        posts.append(newPost)
        isShowingQuestionForm = false // Hide the question form after adding the post
    }

    private func addReply(to post: ForumPost, reply: Reply) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].replies.append(reply)
        }
    }

    private func addReply(to reply: Reply, in post: ForumPost, reply newReply: Reply) {
        if let postIndex = posts.firstIndex(where: { $0.id == post.id }) {
            if let replyIndex = findReplyIndex(reply, in: &posts[postIndex].replies) {
                posts[postIndex].replies[replyIndex].replies.append(newReply)
            }
        }
    }

    private func likePost(_ post: ForumPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            if posts[index].likedByCurrentUser {
                posts[index].likes -= 1
            } else {
                posts[index].likes += 1
            }
            posts[index].likedByCurrentUser.toggle()
        }
    }

    private func likeReply(_ reply: Reply, in post: ForumPost) {
        if let postIndex = posts.firstIndex(where: { $0.id == post.id }) {
            likeNestedReply(&posts[postIndex].replies, reply)
        }
    }

    private func likeNestedReply(_ replies: inout [Reply], _ targetReply: Reply) {
        for index in replies.indices {
            if replies[index].id == targetReply.id {
                if replies[index].likedByCurrentUser {
                    replies[index].likes -= 1
                } else {
                    replies[index].likes += 1
                }
                replies[index].likedByCurrentUser.toggle()
                return
            } else {
                likeNestedReply(&replies[index].replies, targetReply)
            }
        }
    }

    private func findReplyIndex(_ reply: Reply, in replies: inout [Reply]) -> Int? {
        for (index, item) in replies.enumerated() {
            if item.id == reply.id {
                return index
            } else if let nestedIndex = findReplyIndex(reply, in: &replies[index].replies) {
                return nestedIndex
            }
        }
        return nil
    }

    private func toggleLike(_ reply: inout Reply) {
        if reply.likedByCurrentUser {
            reply.likes -= 1
        } else {
            reply.likes += 1
        }
        reply.likedByCurrentUser.toggle()
    }
}

// Forum Post Row View
struct ForumPostRow: View {
    @ObservedObject var post: ForumPost
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(post.username)
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                HStack(spacing: 20) {
                    HStack {
                        Image(systemName: post.likedByCurrentUser ? "heart.fill" : "heart")
                            .foregroundColor(post.likedByCurrentUser ? .red : .gray)
                        Text("\(post.likes)")
                            .onTapGesture {
                                onLike()
                            }
                    }
                    HStack {
                        Image(systemName: "bubble.right.fill")
                            .foregroundColor(.gray)
                        Text("\(post.replies.count)")
                    }
                }
            }
            .padding(.bottom, 2)

            Text(post.title)
                .font(.title2)
                .padding(.bottom, 2)

            Text(post.body)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.bottom, 2)

            if let link = post.link {
                Link("Related Link", destination: link)
                    .padding(.bottom, 2)
            }

            ForEach(post.media) { media in
                if media.type == .image {
                    Image(uiImage: UIImage(contentsOfFile: media.url.path) ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding(.bottom, 2)
                } else if media.type == .video {
                    VideoPlayer(player: AVPlayer(url: media.url))
                        .frame(height: 200)
                        .padding(.bottom, 2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .onTapGesture(count: 2) {
            onLike()
        }
    }
}

// Post Detail View
struct PostDetailView: View {
    @ObservedObject var post: ForumPost
    let onReply: (Reply) -> Void
    let onLike: () -> Void
    let onReplyToReply: (Reply, Reply) -> Void
    let onLikeReply: (Reply) -> Void
    @State private var newReply = ""
    @State private var selectedMediaItems: [MediaItem] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForumPostRow(post: post, onLike: onLike)
                    .onTapGesture(count: 2) {
                        onLike()
                    }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Add a reply...", text: $newReply)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    Button(action: addReply) {
                        Text("Post Reply")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)

                MediaPickerButton(selectedMediaItems: $selectedMediaItems)
                    .padding(.vertical, 4)

                ForEach($post.replies) { $reply in
                    ReplyView(reply: $reply, onReplyToReply: { newReply in
                        onReplyToReply(reply, newReply)
                    }, onLikeReply: { likedReply in
                        onLikeReply(likedReply)
                    })
                }
            }
            .padding()
        }
        .navigationTitle("Post Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: onLike) {
            Image(systemName: "heart.fill")
                .foregroundColor(post.likedByCurrentUser ? .gray : .red)
        })
    }

    private func addReply() {
        let reply = Reply(username: "CurrentUser", replyText: newReply, media: selectedMediaItems)
        onReply(reply)
        newReply = ""
        selectedMediaItems = []
    }
}

// Reply View
struct ReplyView: View {
    @Binding var reply: Reply
    let onReplyToReply: (Reply) -> Void
    let onLikeReply: (Reply) -> Void
    @State private var showReplyField = false
    @State private var newReplyText = ""
    @State private var selectedMediaItems: [MediaItem] = []

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(reply.username)
                    .font(.subheadline)
                    .foregroundColor(.green)
                Spacer()
                HStack(spacing: 20) {
                    Button(action: { onLikeReply(reply) }) {
                        HStack {
                            Image(systemName: reply.likedByCurrentUser ? "heart.fill" : "heart")
                                .foregroundColor(reply.likedByCurrentUser ? .red : .gray)
                            Text("\(reply.likes)")
                        }
                    }
                    Button(action: { showReplyField.toggle() }) {
                        Text("Reply")
                            .foregroundColor(.gray)
                    }
                }
            }

            Text(reply.replyText)
                .font(.body)

            ForEach(reply.media) { media in
                if media.type == .image {
                    Image(uiImage: UIImage(contentsOfFile: media.url.path) ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                } else if media.type == .video {
                    VideoPlayer(player: AVPlayer(url: media.url))
                        .frame(height: 100)
                }
            }

            if showReplyField {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Add a reply...", text: $newReplyText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    MediaPickerButton(selectedMediaItems: $selectedMediaItems)
                        .padding(.vertical, 4)

                    Button(action: postReply) {
                        Text("Post Reply")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }

            ForEach($reply.replies) { $nestedReply in
                ReplyView(reply: $nestedReply, onReplyToReply: onReplyToReply, onLikeReply: onLikeReply)
                    .padding(.leading, 20)
            }
        }
        .padding(.vertical, 4)
    }

    private func postReply() {
        let newReply = Reply(username: "CurrentUser", replyText: newReplyText, media: selectedMediaItems)
        onReplyToReply(newReply)
        newReplyText = ""
        selectedMediaItems = []
        showReplyField = false
    }
}

// Media Picker Button
struct MediaPickerButton: View {
    @Binding var selectedMediaItems: [MediaItem]
    @State private var isPresentingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideo: URL?

    var body: some View {
        VStack {
            Button(action: { isPresentingImagePicker = true }) {
                HStack {
                    Image(systemName: "photo")
                    Text("Select Media")
                }
                .foregroundColor(.blue)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
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

// Preview Provider
struct ForumView_Previews: PreviewProvider {
    static var previews: some View {
        ForumView()
    }
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
