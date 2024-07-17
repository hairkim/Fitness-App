//
//  CreateForum.swift
//  fitnessapp
//
//  Created by Daniel Han on 5/23/24.
//

import SwiftUI
import FirebaseStorage

struct CreateQuestionView: View {
    @EnvironmentObject var userStore: UserStore
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var link: String = ""
    @State private var selectedMediaItems: [MediaItem] = []
    var onAddQuestion: (String, String, [MediaItem], URL?) async -> Void
    @Environment(\.presentationMode) var presentationMode
    

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Username")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(userStore.currentUser?.username ?? "Loading...")
                    .font(.body)
                    .foregroundColor(.primary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("Enter title...", text: $title)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(.vertical, 4)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Body")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextEditor(text: $bodyText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(height: 150)
                    .padding(.vertical, 4)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Link (Optional)")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("Enter link...", text: $link)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.vertical, 4)
            }

            MediaPickerButton(selectedMediaItems: $selectedMediaItems)
                .padding(.vertical)

            Button(action: {
                Task {
                    let uploadedMediaItems = await uploadAllMedia()
                    await onAddQuestion(title, bodyText, uploadedMediaItems, URL(string: link))
                    presentationMode.wrappedValue.dismiss() // Dismiss the view after adding the post
                }
            }) {
                Text("Post Question")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top)

            Spacer()
        }
        .padding()
        .navigationTitle("Create Question")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    
    func uploadImageToFirebase(image: UIImage) async throws -> URL {
        let storageRef = Storage.storage().reference().child("images/\(UUID().uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageUploadError.compressionFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                print("Image uploaded successfully, fetching download URL...")
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error fetching download URL: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let url = url else {
                        print("Download URL is nil")
                        continuation.resume(throwing: ImageUploadError.urlNil)
                        return
                    }
                    
                    print("Download URL fetched successfully: \(url.absoluteString)")
                    continuation.resume(returning: url)
                }
            }
        }
    }
    
    //        let storageRef = Storage.storage().reference().child("videos/\(UUID().uuidString)")
    //        let metadata = StorageMetadata()
    //        metadata.contentType = "video/quicktime"
    //
    //        do {
    //            let _ = try await storageRef.putDataAsync(videoData, metadata: metadata)
    //            let url = try await storageRef.downloadURL()
    //            return url.absoluteString
    //        } catch {
    //            print("failed to upload video with error: \(error.localizedDescription)")
    //            return nil
    //        }
    
    func uploadVideoToFirebase(videoURL: URL) async throws -> URL {
        let storageRef = Storage.storage().reference().child("videos/\(UUID().uuidString).mp4")
        
        // Ensure that the video file exists
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            print("File does not exist at path: \(videoURL)")
            throw ImageUploadError.urlNil
        }
        
        // Read the video data
        let videoData = try Data(contentsOf: videoURL)

        return try await withCheckedThrowingContinuation { continuation in
            storageRef.putData(videoData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading video: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error fetching download URL: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let url = url else {
                        print("Download URL is nil")
                        continuation.resume(throwing: ImageUploadError.urlNil)
                        return
                    }
                    print("Download URL fetched successfully: \(url.absoluteString)")
                    continuation.resume(returning: url)
                }
            }
        }
    }



    func uploadAllMedia() async -> [MediaItem] {
        var uploadedMediaItems: [MediaItem] = []
        
        for mediaItem in selectedMediaItems {
            do {
                if mediaItem.type == .image, let image = UIImage(contentsOfFile: mediaItem.url.path) {
                    let url = try await uploadImageToFirebase(image: image)
                    uploadedMediaItems.append(MediaItem(type: .image, url: url))
                } else if mediaItem.type == .video {
                    let url = try await uploadVideoToFirebase(videoURL: mediaItem.url)
                    uploadedMediaItems.append(MediaItem(type: .video, url: url))
                }
            } catch {
                print("Error uploading media: \(error)")
            }
        }

        return uploadedMediaItems
    }
}

// Preview Provider
struct CreateQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        CreateQuestionView(onAddQuestion: { _, _, _, _ in })
            .environmentObject(userStore)
    }
}
