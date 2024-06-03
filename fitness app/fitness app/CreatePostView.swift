//
//  CreatePostView.swift
//  fitnessapp
//
//  Created by Harris Kim on 6/1/24.
//

import SwiftUI
import Firebase
import FirebaseStorage

struct CreatePostView: View {
    @EnvironmentObject var userStore: UserStore
    @State private var caption: String = ""
    @State private var selectedWorkoutSplit: String = ""
    @State private var selectedEmoji: String = ""
    @State private var workoutSplits: [String] = ["Upper Body", "Lower Body", "Full Body", "Cardio", "Rest Day", "Push", "Pull", "Legs"]
    @State private var workoutSplitEmojis: [String] = ["💀", "💪", "🦵", "🏋️‍♀️"]
    
    var image: Image?
    var inputImage: UIImage?
    
    
    var body: some View {
        VStack() {
            Text("New Post")
                .font(.title)
                .foregroundColor(Color(.darkGray))
                .padding(.leading, 16)
                .padding(20)
            
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 250)
                    .padding(30)
            } else {
                Text("No image selected").foregroundColor(.gray)
            }
            Spacer()
            TextField("Write a caption...", text: $caption)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .trailing, .top])
            Text("Select Workout Split")
                .font(.headline)
                .padding([.leading, .top])
            
            Picker("Workout Split", selection: $selectedWorkoutSplit) {
                ForEach(workoutSplits, id: \.self) { split in
                    Text(split)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding([.leading, .trailing])
            
            Text("Select Workout Split Emoji")
                .font(.headline)
                .padding([.leading, .top])
            
            Picker("Workout Split Emojis", selection: $selectedEmoji) {
                ForEach(workoutSplitEmojis, id: \.self) { emoji in
                    Text(emoji)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding([.leading, .trailing])
            
            Spacer()
            Button(action: {
                Task {
                    await createPost()
                }
            }) {
                Text("Post")
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding([.leading, .trailing, .bottom])
            }
        }
    }
    
    func createPost() async {
        guard let inputImage = inputImage, let currentUser = userStore.currentUser else {
            print("No image or user data available")
            return
        }
        
        do {
            let imageUrl = try await uploadImageToFirebase(image: inputImage)
            print("Image URL: \(imageUrl.absoluteString)")
            
            let newPost = Post(
                username: currentUser.username,
                imageName: imageUrl.absoluteString,
                caption: caption,
                multiplePictures: false,
                workoutSplit: selectedWorkoutSplit,
                workoutSplitEmoji: selectedEmoji,
                comments: []
            )
            
            try await PostManager.shared.createNewPost(post: newPost)
            print("Post created successfully")
        } catch {
            print("Error creating post: \(error.localizedDescription)")
        }
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
}

struct CreatePostView_Previews: PreviewProvider {
    
    static var previews: some View {
        CreatePostView(image: Image(systemName: "photo"), inputImage: UIImage())
    }
}

enum ImageUploadError: Error {
    case compressionFailed
    case urlNil
}

extension ImageUploadError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return NSLocalizedString("Failed to compress image", comment: "")
        case .urlNil:
            return NSLocalizedString("URL is nil", comment: "")
        }
    }
}
