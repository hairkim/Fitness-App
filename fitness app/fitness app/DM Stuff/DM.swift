//
//  DM.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/4/24.
//

import SwiftUI
import FirebaseFirestore

struct DMHomeView: View {
    @Binding var showDMHomeView: Bool
    @Binding var chats: [DBChat]
    @Binding var unreadMessagesCount: Int
    @EnvironmentObject var userStore: UserStore

    var body: some View {
        NavigationView {
            List {
                ForEach(sortedChats(), id: \.id) { chat in
                    NavigationLink(destination: ChatView(chats: $chats, chat: chat, unreadMessagesCount: $unreadMessagesCount)) {
                        chatRowView(chat: chat)
                    }
                    .buttonStyle(PlainButtonStyle()) // Ensures the whole row is clickable
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
            if let count = chat.unreadMessages[userStore.currentUser?.userId ?? ""], count > 0 {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .padding(.trailing, 10)
            }
        }
        .padding(.vertical, 10)
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

                self.updateUnreadMessagesCount()
            }
    }

    private func updateUnreadMessagesCount() {
        guard let currentUserID = userStore.currentUser?.userId else { return }
        unreadMessagesCount = chats.reduce(0) { count, chat in
            count + (chat.unreadMessages[currentUserID] ?? 0)
        }
    }
}

struct DMHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        DMHomeView(showDMHomeView: .constant(false), chats: .constant([]), unreadMessagesCount: .constant(0))
            .environmentObject(userStore)
    }
}
