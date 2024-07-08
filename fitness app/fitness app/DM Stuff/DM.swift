//
//  DM.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/4/24.
//

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
                ForEach(sortedChats(), id: \.id) { chat in
                    NavigationLink(destination: ChatView(chat: chat).environmentObject(userStore)) {
                        chatRowView(chat: chat)
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
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                setupChatsListener()
            }
        }
        .transition(.move(edge: .trailing))
    }

    private func sortedChats() -> [DBChat] {
        return chats.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
    }

    private func chatRowView(chat: DBChat) -> some View {
        HStack {
            if let participantId = chat.participants.first(where: { $0 != userStore.currentUser?.userId }) {
                ProfileImageView(userId: participantId)
                    .frame(width: 40, height: 40)
                Text(chat.participantNames[participantId] ?? "Unknown")
                    .padding(.leading, 10)
            }
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
                sendNotification(for: chatId, count: documents.count)
            }
    }

    private func sendNotification(for chatId: String, count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "New Message"
        content.body = "You have \(count) unread messages."
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: chatId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

struct DMHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        DMHomeView(showDMHomeView: .constant(false))
            .environmentObject(userStore)
    }
}
