//
//  ImageChooser.swift
//  FitnessApp
//
//  Created by Harris Kim on 2/10/24.
//

import SwiftUI
import CoreData

struct ImageChooser: View {
    @State private var inputImage: UIImage?
    @State private var image: Image?
    @State private var sourceType: UIImagePickerController.SourceType?
    
    @Binding var postImage: UIImage?

    var body: some View {
        NavigationView {
            VStack{
                image?.resizable().scaledToFit()
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
            }
            .sheet(item: $sourceType, onDismiss: nil) { sourceType in
                ImagePicker(selectedImage: $inputImage, sourceType: sourceType)
            }
//            .onChange(of: inputImage) { oldValue, newValue in loadImage()
//            }
            .onChange(of: inputImage) { _, _ in
                loadImage()
            }


        }
    }

    func loadImage(){
        guard let inputImage = inputImage else { return }
        postImage = inputImage
        image = Image(uiImage: inputImage)
    }

}
extension UIImagePickerController.SourceType: Identifiable {
    public var id: Int {
        return hashValue
    }
}

//#Preview {
//    @State static var previewPostImage: UIImage?
//    ImageChooser(postImage: $previewPostImage)
//}

struct ImageChooser_Previews: PreviewProvider {
    @State static var previewPostImage: UIImage?

    static var previews: some View {
        ImageChooser(postImage: $previewPostImage)
    }
}

