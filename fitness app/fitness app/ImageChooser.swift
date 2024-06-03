//
//  ImageChooser.swift
//  FitnessApp
//
//  Created by Harris Kim on 2/10/24.
//

import SwiftUI
import CoreData
import Photos
import Firebase
import FirebaseStorage

struct ImageChooser: View {
    @EnvironmentObject var userStore: UserStore
    @State private var inputImage: UIImage?
    @State private var image: Image?
    @State private var sourceType: UIImagePickerController.SourceType?

    var body: some View {
        VStack{
            Spacer()
            if let image = image {
                image.resizable().scaledToFit()
            } else {
                Text("No image selected").foregroundColor(.gray)
            }
            Spacer()
            VStack{
                HStack(spacing: 30){
                    Button("Select Image"){
                        self.sourceType = .photoLibrary
                    }
                    Button(action: {
                        self.sourceType = .camera
                    }){
                        Image(systemName: "camera")
                    }

                }
//                    Button("Post") {
//                        Task {
//                            //await createPost()
//                        }
//
//                    }
                NavigationLink(destination: CreatePostView(image: image, inputImage: inputImage)) {
                    Text("Post")
                }
                
                .padding(20)
            }
        }
        .sheet(item: $sourceType, onDismiss: nil) { sourceType in
            ImagePicker(selectedImage: $inputImage, sourceType: sourceType)
        }
//            .onChange(of: inputImage) { oldValue, newValue in loadImage()
//            }
        .onChange(of: inputImage) { _, _ in
            loadImage()
        }
        .onAppear {
            loadLastImageFromCameraRoll()
        }


    }
    
    
    
    //beginning of functions

    func loadImage(){
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
    }
    
    func loadLastImageFromCameraRoll() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        if let lastAsset = fetchResult.firstObject {
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.version = .current
            options.isSynchronous = true  // You might choose asynchronous based on your use case
            manager.requestImage(for: lastAsset,
                                 targetSize: PHImageManagerMaximumSize,  // Request the full-sized image
                                 contentMode: .aspectFit,
                                 options: options) { image, _ in
                DispatchQueue.main.async {
                    if let image = image {
                        self.inputImage = image
                        self.image = Image(uiImage: image)
                    }
                }
            }
        }
    }

    //    func createPost() async {
    //        guard let inputImage = inputImage, let currentUser = userStore.currentUser else {
    //            print("no image or user data available")
    //            return
    //        }
    //
    //        do {
    //            let imageUrl = try await uploadImageToFirebase(image: inputImage)
    //
    //            let newPost = Post(username: currentUser.username, imageName: imageUrl.absoluteString, caption: "placeholder", multiplePictures: false, workoutSplit: "Push", workoutSplitEmoji: "💀", comments: [])
    //            try await PostManager.shared.createNewPost(post: newPost)
    //
    //            print("Post created successfully")
    //        } catch {
    //            print("Error creating post: \(error.localizedDescription)")
    //        }
    //    }
    
    
//    func uploadImageToFirebase(image: UIImage) async throws -> URL {
//        let storageRef = Storage.storage().reference().child("images/\(UUID().uuidString).jpg")
//        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//            throw NSError(domain: "ImageChooser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
//        }
//        
//        return try await withCheckedThrowingContinuation { continuation in
//            storageRef.putData(imageData, metadata: nil) { _, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                
//                storageRef.downloadURL { url, error in
//                    if let error = error {
//                        continuation.resume(throwing: error)
//                        return
//                    }
//                    
//                    if let url = url {
//                        continuation.resume(returning: url)
//                    } else {
//                        continuation.resume(throwing: NSError(domain: "ImageChooser", code: 2, userInfo: [NSLocalizedDescriptionKey: "URL is nil"]))
//                    }
//                }
//            }
//        }
//    }

}
extension UIImagePickerController.SourceType: Identifiable {
    public var id: Int {
        return hashValue
    }
}


struct ImageChooser_Previews: PreviewProvider {
    @State static var previewPostImage: UIImage?

    static var previews: some View {
        ImageChooser()
    }
}


