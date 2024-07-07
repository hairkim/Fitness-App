//
//  ProfilePicView.swift
//  fitnessapp
//
//  Created by Daniel Han on 7/6/24.
//

import SwiftUI
import Firebase

struct ProfileImageView: View {
    let userId: String
    @State private var profileImage: Image? = nil

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 40)
            
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            }
        }
        .onAppear {
            fetchProfileImage()
        }
    }

    private func fetchProfileImage() {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                if let photoUrl = data?["photoUrl"] as? String, let url = URL(string: photoUrl) {
                    DispatchQueue.global().async {
                        if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.profileImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                }
            }
        }
    }
}
