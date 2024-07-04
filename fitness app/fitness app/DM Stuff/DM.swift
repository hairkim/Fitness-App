//
//  DM.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/4/24.
//

import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift


// Custom Colors
extension Color {
    static let gymPrimary = Color(red: 34 / 255, green: 34 / 255, blue: 34 / 255)
    static let gymSecondary = Color(red: 86 / 255, green: 167 / 255, blue: 124 / 255) // Muted green
    static let gymAccent = Color(red: 72 / 255, green: 201 / 255, blue: 176 / 255)
    static let gymBackground = Color(red: 245 / 255, green: 245 / 255, blue: 220 / 255) // Light beige
}


// DMHomeView

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DMHomeView: View {
    @Binding var showDMHomeView: Bool
    @EnvironmentObject var userStore: UserStore
    @State private var chats = [DBChat]()
    @State private var unreadMessages = [String: Int]() // Dictionary to hold unread messages count for each chat

    var body: some View {
        NavigationView {
            List {
                ForEach(chats) { chat in
                    NavigationLink(destination: ChatView(chat: chat)) {
                        HStack {
                            Text(chat.participantNames.first(where: { $0.key != userStore.currentUser?.userId })?.value ?? "Unknown")
                            Spacer()
                            if let count = unreadMessages[chat.id ?? ""], count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(5)
                                    .background(Circle().fill(Color.red).frame(width: 20, height: 20))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            showDMHomeView.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                setupChatsListener()
            }
        }
    }

    private func setupChatsListener() {
        guard let currentUserID = userStore.currentUser?.userId else { return }
        let db = Firestore.firestore()

        db.collection("chats")
            .whereField("participants", arrayContains: currentUserID)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error listening to chats: \(error)")
                    return
                }

                guard let documents = querySnapshot?.documents else { return }
                self.chats = documents.compactMap { document -> DBChat? in
                    try? document.data(as: DBChat.self)
                }

                // Listen for unread messages for each chat
                for chat in self.chats {
                    if let chatId = chat.id {
                        setupUnreadMessagesListener(chatId: chatId)
                    }
                }
            }
    }

    private func setupUnreadMessagesListener(chatId: String) {
        guard let currentUserID = userStore.currentUser?.userId else { return }
        let db = Firestore.firestore()

        db.collection("chats").document(chatId).collection("messages")
            .whereField("receiverId", isEqualTo: currentUserID)
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error listening to unread messages: \(error)")
                    return
                }

                guard let documents = querySnapshot?.documents else { return }
                self.unreadMessages[chatId] = documents.count
            }
    }
}

struct DMHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        DMHomeView(showDMHomeView: .constant(false))
            .environmentObject(userStore)
    }
}
