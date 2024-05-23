//
//  CreateForum.swift
//  fitnessapp
//
//  Created by Daniel Han on 5/23/24.
//

import SwiftUI

struct CreateQuestionView: View {
    @State private var username: String = "CurrentUser"
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var link: String = ""
    @State private var selectedMediaItems: [MediaItem] = []
    var onAddQuestion: (String, String, String, [MediaItem], URL?) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Username")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(username)
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
                let url = URL(string: link)
                onAddQuestion(username, title, bodyText, selectedMediaItems, url)
                presentationMode.wrappedValue.dismiss() // Dismiss the view after adding the post
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
}

// Preview Provider
struct CreateQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateQuestionView(onAddQuestion: { _, _, _, _, _ in })
    }
}
