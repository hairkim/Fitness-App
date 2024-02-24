//
//  ImageChooser.swift
//  FitnessApp
//
//  Created by Harris Kim on 2/10/24.
//

import SwiftUI

struct ImageChooser: View {
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var image: Image?
    @State private var sourceType: UIImagePickerController.SourceType?

    var body: some View {
        NavigationView {
            VStack{
                image?.resizable().scaledToFit()
                HStack(spacing: 30){
                    Button("Select Image"){
                        self.sourceType = .photoLibrary
                        showingImagePicker = true
                    }
                    Button(action: {
                        self.sourceType = .camera
                        showingImagePicker = true
                    }){
                        Image(systemName: "camera")
                    }

                }
            }
            .sheet(item: $sourceType) { sourceType in
                ImagePicker(selectedImage: $inputImage, sourceType: sourceType)
            }
            .onChange(of: inputImage) { oldValue, newValue in loadImage()
            }


        }
    }

    func loadImage(){
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
    }

}
extension UIImagePickerController.SourceType: Identifiable {
    public var id: Int {
        return hashValue
    }
}

#Preview {
    ImageChooser()
}
