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
            VStack {
                headerView
                chatListView
            }
            .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
        }
        .transition(.move(edge: .trailing))
        .onAppear {
            setupChatsListener()
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                withAnimation {
                    showDMHomeView.toggle()
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.gymPrimary)
                    .padding(.leading, 10)
            }
            Text("Messages")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.gymPrimary)
                .padding(.leading, 10)
            Spacer()
        }
        .padding()
        .background(Color.gymBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .padding(.top, 10)
    }

    private var chatListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(sortedChats(), id: \.id) { chat in
                    NavigationLink(destination: ChatView(chats: $chats, chat: chat, unreadMessagesCount: $unreadMessagesCount)) {
                        chatRowView(chat: chat)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.gymBackground)
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
            .padding(.top, 10)
        }
        .background(Color.gymBackground)
    }

    private func sortedChats() -> [DBChat] {
        return chats.sorted { (chat1: DBChat, chat2: DBChat) -> Bool in
            chat1.timestamp.dateValue() > chat2.timestamp.dateValue()
        }
    }

    private func chatRowView(chat: DBChat) -> some View {
        HStack {
            if let participantId = chat.participants.first(where: { $0 != userStore.currentUser?.userId }) {
                ProfileImageView(userId: participantId)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gymPrimary, lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                VStack(alignment: .leading) {
                    Text(chat.participantNames[participantId] ?? "Unknown")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gymPrimary)
                    if let lastMessage = chat.lastMessage {
                        Text(lastMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 10)
            }
            Spacer()
            if let count = chat.unreadMessages[userStore.currentUser?.userId ?? ""], count > 0 {
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text("\(count)")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    )
                    .padding(.trailing, 10)
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal)
    }

    private func setupChatsListener() {
        guard let currentUserID = userStore.currentUser?.userId else { return }
        let db = Firestore.firestore()

        db.collection("chats")
            .whereField("participants", arrayContains: currentUserID)
            .addSnapshotListener { (querySnapshot: QuerySnapshot?, error: Error?) in
                if let error = error {
                    print("Error listening to chats: \(error)")
                    return
                }

                guard let documents = querySnapshot?.documents else { return }
                let fetchedChats: [DBChat] = documents.compactMap { (document: QueryDocumentSnapshot) -> DBChat? in
                    return try? document.data(as: DBChat.self)
                }

                DispatchQueue.main.async {
                    self.chats = fetchedChats
                    self.updateUnreadMessagesCount()
                }
            }
    }

    private func updateUnreadMessagesCount() {
        guard let currentUserID = userStore.currentUser?.userId else { return }
        unreadMessagesCount = chats.reduce(0) { (count: Int, chat: DBChat) -> Int in
            return count + (chat.unreadMessages[currentUserID] ?? 0)
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
