//
//  ChatView.swift
//  fitnessapp
//
//  Created by Harris Kim on 6/17/24.
//

import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    @Binding var chats: [DBChat]
    let chat: DBChat
    @Binding var unreadMessagesCount: Int
    @EnvironmentObject var userStore: UserStore
    @Environment(\.presentationMode) var presentationMode
    @State private var messageText = ""
    @State var messages = [DBMessage]()
    @State private var messagesListener: ListenerRegistration?
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gymPrimary)
                        .padding(.leading, 10)
                }

                HStack {
                    if let profileImage = chat.profileImage, !profileImage.isEmpty {
                        AsyncImage(url: URL(string: profileImage)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                                .frame(width: 50, height: 50)
                        }
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.gymAccent.opacity(0.2))
                                .frame(width: 50, height: 50)
                            Text(chatInitials(for: chat))
                                .font(.headline)
                                .foregroundColor(.gymPrimary)
                        }
                    }

                    Text(chatName(for: chat))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gymPrimary)
                        .padding(.leading, 8)
                }
                .padding(.leading, 10)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.gymPrimary)
                    Text("7") // Placeholder for streak number
                        .foregroundColor(.gymPrimary)
                        .font(.system(size: 20, weight: .bold))
                }
                .padding(.trailing, 10)
            }
            .padding()
            .background(Color.gymBackground)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            .padding(.top, 10)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(self.messages) { message in
                        HStack {
                            if message.senderId == userStore.currentUser!.userId {
                                Spacer()
                                Text(message.text)
                                    .padding()
                                    .background(Color.gymPrimary.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .padding(.trailing)
                                    .font(.system(size: 16, weight: .bold))
                            } else {
                                Text(message.text)
                                    .padding()
                                    .background(Color.green.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .padding(.leading)
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }

            HStack {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button(action: {
                    Task {
                        await sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .imageScale(.large)
                        .foregroundColor(.gymSecondary)
                        .padding(.trailing)
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
        .onAppear {
            addMessagesListener()
            Task {
                await markMessagesAsRead()
            }
        }
        .onDisappear {
            removeMessagesListener()
        }
    }

    private func sendMessage() async {
        guard !messageText.isEmpty else { return }
        guard let currentUser = userStore.currentUser else {
            print("no current user found")
            return
        }
        do {
            if let chatId = chat.id, let receiverId = getReceiverId(from: chat) {
                let newMessage = DBMessage(chatId: chatId, senderId: currentUser.userId, receiverId: receiverId, text: messageText)
                
                try await ChatManager.shared.sendMessage(message: newMessage)
                self.messageText = ""
                await fetchMessages()
            }
        } catch {
            print("error sending message: \(error)")
        }
    }

    private func getReceiverId(from chat: DBChat) -> String? {
        if let currentUserId = userStore.currentUser?.userId {
            return chat.participants.first { $0 != currentUserId }
        }
        return nil
    }
    
    private func fetchMessages() async {
        do {
            if let id = chat.id {
                self.messages = try await ChatManager.shared.getMessages(for: id)
            } else {
                print("no chat id found")
                return
            }
            print("messages fetched")
        } catch {
            print("Error fetching messages: \(error)")
        }
    }
    
    private func addMessagesListener() {
        guard let chatId = chat.id else { return }
        print("Setting up listener for chat ID: \(chatId)")
        messagesListener = ChatManager.shared.addMessagesListener(chatId: chatId) { messages, error in
            if let error = error {
                print("Error listening for messages: \(error)")
                return
            }
            guard let messages = messages else {
                print("No messages in collection")
                return
            }
            self.messages = messages
            print("Messages updated: \(self.messages)")
        }
    }

    private func removeMessagesListener() {
        messagesListener?.remove()
        messagesListener = nil
        print("successfully removed listener")
    }
    
    private func chatName(for chat: DBChat) -> String {
        if let currentUserId = userStore.currentUser?.userId {
            return chat.participantNames
                .filter { $0.key != currentUserId }
                .map { $0.value }
                .joined(separator: ", ")
        } else {
            print("couldnt find user id")
            return ""
        }
    }
    
    private func chatInitials(for chat: DBChat) -> String {
        if let currentUserId = userStore.currentUser?.userId {
            return chat.participantNames
                .filter { $0.key != currentUserId }
                .map { $0.value.initial() }
                .joined(separator: ", ")
        } else {
            print("couldnt find user id")
            return ""
        }
    }
    
    private func markMessagesAsRead() async {
        guard let chatId = chat.id, let userId = userStore.currentUser?.userId else { return }
        do {
            try await ChatManager.shared.markMessagesAsRead(chatId: chatId, userId: userId)
            if let index = chats.firstIndex(where: { $0.id == chat.id }) {
                chats[index].unreadMessages[userId] = 0
                updateUnreadMessagesCount()
            }
        } catch {
            print("Failed to mark messages as read: \(error)")
        }
    }

    private func updateUnreadMessagesCount() {
        guard let currentUserID = userStore.currentUser?.userId else { return }
        unreadMessagesCount = chats.reduce(0) { count, chat in
            count + (chat.unreadMessages[currentUserID] ?? 0)
        }
    }
}

extension String {
    func initial() -> String {
        guard let firstCharacter = self.first else { return "" }
        return String(firstCharacter).uppercased()
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let newChat = DBChat(
            participants: [],
            participantNames: ["":""],
            lastMessage: nil,
            timestamp: Timestamp(),
            profileImage: nil
        )
        
        ChatView(chats: .constant([]), chat: newChat, unreadMessagesCount: .constant(0))
    }
}


import SwiftUI

extension Color {
    static let gymPrimary = Color(red: 34 / 255, green: 34 / 255, blue: 34 / 255)
    static let gymSecondary = Color(red: 86 / 255, green: 167 / 255, blue: 124 / 255)
    static let gymAccent = Color(red: 72 / 255, green: 201 / 255, blue: 176 / 255)
    static let gymBackground = Color(red: 245 / 255, green: 245 / 255, blue: 220 / 255)
}
