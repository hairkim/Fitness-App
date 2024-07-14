//
//  ChatView.swift
//  fitnessapp
//
//  Created by Harris Kim on 6/17/24.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatView: View {
    @Binding var chats: [DBChat]
    let chat: DBChat
    @Binding var unreadMessagesCount: Int
    @EnvironmentObject var userStore: UserStore
    @Environment(\.presentationMode) var presentationMode
    @State private var messageText = ""
    @State var messages = [DBMessage]()
    @State private var messagesListener: ListenerRegistration?
    @State private var scrollToBottom = false
    @State private var showUserProfile = false
    @State private var selectedUser: DBUser?
    @State private var seshCount: Int = 0
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isFullScreenImagePresented: IdentifiableImageURL?

    var body: some View {
        VStack {
            ChatHeaderView(
                chat: chat,
                showUserProfile: $showUserProfile,
                selectedUser: $selectedUser,
                seshCount: seshCount,
                presentationMode: presentationMode
            )
            .padding()
            .background(Color.gymBackground)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            .padding(.top, 10)

            ScrollViewReader { proxy in
                ScrollView {
                    ChatMessagesView(
                        messages: messages,
                        userStore: userStore,
                        isFullScreenImagePresented: $isFullScreenImagePresented
                    )
                    .padding()
                    .onChange(of: messages) { _ in
                        scrollToLastMessage(proxy: proxy)
                    }
                    .onAppear {
                        scrollToLastMessage(proxy: proxy)
                    }
                }
            }

            HStack {
                Button(action: {
                    showImagePicker.toggle()
                }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.gymSecondary)
                        .padding(.leading, 12)
                }

                TextField("Type your message...", text: $messageText)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(
                        HStack {
                            Spacer()
                            Button(action: {
                                Task {
                                    await sendMessage()
                                }
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.gymSecondary)
                                    .padding(.trailing, 12)
                            }
                        }
                    )
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
        .onAppear {
            addMessagesListener()
            Task {
                await fetchMessages()
                await markMessagesAsRead()
                scrollToBottom = true // Set the flag to scroll to the bottom
                await fetchSeshCount()
            }
        }
        .onDisappear {
            removeMessagesListener()
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if let image = selectedImage {
                Task {
                    await uploadImage(image)
                }
            }
        }) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .fullScreenCover(item: $isFullScreenImagePresented) { fullScreenImage in
            FullScreenImageView(imageURL: fullScreenImage.url, isPresented: $isFullScreenImagePresented)
        }
    }

    private func scrollToLastMessage(proxy: ScrollViewProxy) {
        if let lastMessageID = messages.last?.id {
            proxy.scrollTo(lastMessageID, anchor: .bottom)
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
            Task {
                await markMessagesAsRead()
            }
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
            print("Marking messages as read for chatId: \(chatId), userId: \(userId)")
            try await ChatManager.shared.markMessagesAsRead(chatId: chatId, userId: userId)
            if let index = chats.firstIndex(where: { $0.id == chat.id }) {
                chats[index].unreadMessages[userId] = 0
                await MainActor.run {
                    updateUnreadMessagesCount()
                }
                print("Marked messages as read and updated unread count")
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

    private func fetchSeshCount() async {
        do {
            if let currentUser = userStore.currentUser {
                let user = try await UserManager.shared.getUser(userId: currentUser.userId)
                seshCount = user.sesh
            }
        } catch {
            print("Failed to fetch sesh count: \(error)")
        }
    }

    private func uploadImage(_ image: UIImage) async {
        guard let currentUser = userStore.currentUser else { return }
        do {
            if let chatId = chat.id, let receiverId = getReceiverId(from: chat) {
                try await ChatManager.shared.sendImageMessage(chatId: chatId, senderId: currentUser.userId, receiverId: receiverId, image: image)
                await fetchMessages()
            }
        } catch {
            print("Error uploading image: \(error)")
        }
    }
}

// Extension to add the initial() method to String
extension String {
    func initial() -> String {
        guard let firstCharacter = self.first else { return "" }
        return String(firstCharacter).uppercased()
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        let newChat = DBChat(
            participants: ["user1", "user2"],
            participantNames: ["user1": "John", "user2": "Doe"],
            lastMessage: "Hello",
            timestamp: Timestamp(),
            profileImage: nil
        )

        ChatView(chats: .constant([newChat]), chat: newChat, unreadMessagesCount: .constant(0))
            .environmentObject(userStore)
    }
}

struct IdentifiableImageURL: Identifiable {
    var id: String { url }
    var url: String
}

struct FullScreenImageView: View {
    var imageURL: String
    @Binding var isPresented: IdentifiableImageURL?

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    isPresented = nil
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding()
            }
            Spacer()
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } placeholder: {
                ProgressView()
            }
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct ChatHeaderView: View {
    let chat: DBChat
    @Binding var showUserProfile: Bool
    @Binding var selectedUser: DBUser?
    let seshCount: Int
    let presentationMode: Binding<PresentationMode>

    var body: some View {
        HStack {
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.gymPrimary)
                    .padding(.leading, 10)
            }

            NavigationLink(destination: UserProfileView(postUser: selectedUser ?? DBUser.placeholder, userStore: UserStore(), chats: .constant([])), isActive: $showUserProfile) {
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
                .onTapGesture {
                    Task {
                        if let participantId = chat.participants.first(where: { $0 != UserStore().currentUser?.userId }) {
                            self.selectedUser = try? await UserManager.shared.getUser(userId: participantId)
                            if self.selectedUser != nil {
                                self.showUserProfile.toggle()
                            }
                        }
                    }
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.gymPrimary)
                Text("\(seshCount)")
                    .foregroundColor(.gymPrimary)
                    .font(.system(size: 20, weight: .bold))
            }
            .padding(.trailing, 10)
        }
    }

    private func chatName(for chat: DBChat) -> String {
        if let currentUserId = UserStore().currentUser?.userId {
            return chat.participantNames
                .filter { $0.key != currentUserId }
                .map { $0.value }
                .joined(separator: ", ")
        } else {
            print("couldn't find user id")
            return ""
        }
    }

    private func chatInitials(for chat: DBChat) -> String {
        if let currentUserId = UserStore().currentUser?.userId {
            return chat.participantNames
                .filter { $0.key != currentUserId }
                .map { $0.value.initial() }
                .joined(separator: ", ")
        } else {
            print("couldn't find user id")
            return ""
        }
    }
}

struct ChatMessagesView: View {
    let messages: [DBMessage]
    let userStore: UserStore
    @Binding var isFullScreenImagePresented: IdentifiableImageURL?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(messages) { message in
                HStack {
                    if message.senderId == userStore.currentUser!.userId {
                        Spacer()
                        if let imageURL = message.imageURL, !imageURL.isEmpty {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(16)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 150, height: 150)
                            }
                            .padding(.trailing)
                            .onTapGesture {
                                isFullScreenImagePresented = IdentifiableImageURL(url: imageURL)
                            }
                        } else {
                            Text(message.text)
                                .padding()
                                .background(Color.gymPrimary.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .padding(.trailing)
                                .font(.system(size: 16, weight: .bold))
                        }
                    } else {
                        if let imageURL = message.imageURL, !imageURL.isEmpty {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(16)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 150, height: 150)
                            }
                            .padding(.leading)
                            .onTapGesture {
                                isFullScreenImagePresented = IdentifiableImageURL(url: imageURL)
                            }
                        } else {
                            Text(message.text)
                                .padding()
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .padding(.leading)
                                .font(.system(size: 16, weight: .bold))
                        }
                        Spacer()
                    }
                }
                .id(message.id)
            }
        }
    }
}


import SwiftUI

extension Color {
    static let gymPrimary = Color(red: 34 / 255, green: 34 / 255, blue: 34 / 255)
    static let gymSecondary = Color(red: 86 / 255, green: 167 / 255, blue: 124 / 255)
    static let gymAccent = Color(red: 72 / 255, green: 201 / 255, blue: 176 / 255)
    static let gymBackground = Color(red: 245 / 255, green: 245 / 255, blue: 220 / 255)
}
