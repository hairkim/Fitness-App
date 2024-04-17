//
//  ImageChooser.swift
//  FitnessApp
//
//  Created by Harris Kim on 2/10/24.
//

import SwiftUI
import CoreData
import Photos

struct ImageChooser: View {
    @State private var inputImage: UIImage?
    @State private var image: Image?
    @State private var sourceType: UIImagePickerController.SourceType?

    var body: some View {
        NavigationView {
            VStack{
                Spacer()
                if let image = image {
                    image.resizable().scaledToFit()
                } else {
                    Text("No image selected").foregroundColor(.gray)
                }
                Spacer()
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
                .padding(50)
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
    }

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

