//
//  Forum.swift
//  fitnessapp
//
//  Created by Daniel Han on 5/22/24.
//

import SwiftUI
import PhotosUI
import AVKit

// Data Models
struct ForumPost: Identifiable {
    let id: UUID = UUID()
    let username: String
    let question: String
    var replies: [Reply]
    var media: [MediaItem]
}

struct Reply: Identifiable {
    let id: UUID = UUID()
    let username: String
    let replyText: String
    var media: [MediaItem]
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

// Main Forum View
struct ForumView: View {
    @State private var posts: [ForumPost] = [
        ForumPost(username: "john_doe", question: "What are the best exercises for chest?", replies: [], media: [])
    ]
    @State private var newQuestion = ""
    @State private var selectedMediaItems: [MediaItem] = []

    var body: some View {
        NavigationView {
            VStack {
                TextField("Ask a question...", text: $newQuestion)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                MediaPickerButton(selectedMediaItems: $selectedMediaItems)
                    .padding()

                Button(action: addQuestion) {
                    Text("Post Question")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }

                List {
                    ForEach(posts) { post in
                        ForumPostView(post: post, onReply: { reply in
                            addReply(to: post, reply: reply)
                        })
                    }
                }
            }
            .navigationTitle("Gym Forum")
        }
    }

    private func addQuestion() {
        let newPost = ForumPost(username: "CurrentUser", question: newQuestion, replies: [], media: selectedMediaItems)
        posts.append(newPost)
        newQuestion = ""
        selectedMediaItems = []
    }

    private func addReply(to post: ForumPost, reply: Reply) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].replies.append(reply)
        }
    }
}

// Forum Post View
struct ForumPostView: View {
    let post: ForumPost
    let onReply: (Reply) -> Void
    @State private var newReply = ""
    @State private var selectedMediaItems: [MediaItem] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text(post.username)
                .font(.headline)
                .foregroundColor(.blue)
            Text(post.question)
                .padding(.bottom)

            ForEach(post.media) { media in
                if media.type == .image {
                    Image(uiImage: UIImage(contentsOfFile: media.url.path) ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else if media.type == .video {
                    VideoPlayer(player: AVPlayer(url: media.url))
                        .frame(height: 200)
                }
            }

            ForEach(post.replies) { reply in
                HStack {
                    VStack(alignment: .leading) {
                        Text(reply.username)
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Text(reply.replyText)
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
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            TextField("Add a reply...", text: $newReply)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)

            MediaPickerButton(selectedMediaItems: $selectedMediaItems)
                .padding(.bottom)

            Button(action: addReply) {
                Text("Post Reply")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .padding()
    }

    private func addReply() {
        let reply = Reply(username: "CurrentUser", replyText: newReply, media: selectedMediaItems)
        onReply(reply)
        newReply = ""
        selectedMediaItems = []
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
                Text("Select Media")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray)
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
