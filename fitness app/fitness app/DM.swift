//
//  DM.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/3/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
}

struct Chat: Identifiable, Codable {
    @DocumentID var id: String?
    var users: [String] // User IDs
    var lastMessage: String
    var timestamp: Timestamp
}

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var senderID: String
    var timestamp: Timestamp
}

class DMViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var chats: [Chat] = []
    @Published var messages: [Message] = []
    private var db = Firestore.firestore()

    init() {
        fetchUsers()
        fetchChats()
    }

    func fetchUsers() {
        // Placeholder data
        self.users = [
            User(id: "1", name: "Alice"),
            User(id: "2", name: "Bob"),
            User(id: "3", name: "Charlie")
        ]
    }

    func fetchChats() {
        // Placeholder data
        self.chats = [
            Chat(id: "1", users: ["1", "2"], lastMessage: "Hello, Bob!", timestamp: Timestamp(date: Date())),
            Chat(id: "2", users: ["1", "3"], lastMessage: "Hi, Charlie!", timestamp: Timestamp(date: Date()))
        ]
    }

    func fetchMessages(for chatID: String) {
        // Placeholder data
        self.messages = [
            Message(id: "1", text: "Hello!", senderID: "1", timestamp: Timestamp(date: Date())),
            Message(id: "2", text: "Hi there!", senderID: "2", timestamp: Timestamp(date: Date()))
        ]
    }

    func sendMessage(chatID: String, text: String, senderID: String) {
        let message = Message(text: text, senderID: senderID, timestamp: Timestamp(date: Date()))
        do {
            _ = try db.collection("chats").document(chatID).collection("messages").addDocument(from: message)
            db.collection("chats").document(chatID).updateData([
                "lastMessage": text,
                "timestamp": Timestamp(date: Date())
            ])
        } catch let error {
            print("Error writing message to Firestore: \(error)")
        }
    }

    func createChat(with userIDs: [String], initialMessage: String, senderID: String) {
        let chat = Chat(users: userIDs, lastMessage: initialMessage, timestamp: Timestamp(date: Date()))
        do {
            let ref = try db.collection("chats").addDocument(from: chat)
            sendMessage(chatID: ref.documentID, text: initialMessage, senderID: senderID)
        } catch let error {
            print("Error creating chat: \(error)")
        }
    }
}

struct DMHomeView: View {
    @StateObject var viewModel = DMViewModel()
    let currentUserID: String = "1" // Placeholder current user ID

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    ForEach(viewModel.chats) { chat in
                        NavigationLink(destination: ChatDetailView(viewModel: viewModel, chat: chat)) {
                            ChatCardView(chat: chat, currentUserID: currentUserID)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                    }
                }
                NavigationLink(destination: NewMessageView(viewModel: viewModel, currentUserID: currentUserID)) {
                    Text("New Message")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Direct Messages")
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.gray.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
            )
        }
    }
}

struct ChatCardView: View {
    var chat: Chat
    var currentUserID: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chat.users.filter { $0 != currentUserID }.joined(separator: ", "))
                .font(.headline)
                .foregroundColor(.white)
            Text(chat.lastMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
            HStack {
                Spacer()
                Text(chat.timestamp.dateValue(), style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct ChatDetailView: View {
    @ObservedObject var viewModel: DMViewModel
    var chat: Chat
    @State private var messageText: String = ""
    let currentUserID: String = "1" // Placeholder current user ID

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(viewModel.messages) { message in
                        HStack {
                            if message.senderID == currentUserID {
                                Spacer()
                                Text(message.text)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            } else {
                                Text(message.text)
                                    .padding()
                                    .background(Color.gray)
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(.top)
            .onAppear {
                if let chatID = chat.id {
                    viewModel.fetchMessages(for: chatID)
                }
            }

            HStack {
                TextField("Enter message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button(action: {
                    if let chatID = chat.id {
                        viewModel.sendMessage(chatID: chatID, text: messageText, senderID: currentUserID)
                        messageText = ""
                    }
                }) {
                    Text("Send")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
    }
}

struct NewMessageView: View {
    @ObservedObject var viewModel: DMViewModel
    let currentUserID: String
    @State private var selectedUserIDs: [String] = []
    @State private var initialMessage: String = ""

    var body: some View {
        VStack {
            List(viewModel.users.filter { $0.id != currentUserID }) { user in
                MultipleSelectionRow(user: user, isSelected: selectedUserIDs.contains(user.id!)) {
                    if selectedUserIDs.contains(user.id!) {
                        selectedUserIDs.removeAll { $0 == user.id }
                    } else {
                        selectedUserIDs.append(user.id!)
                    }
                }
            }
            TextField("Enter initial message...", text: $initialMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                if !selectedUserIDs.isEmpty && !initialMessage.isEmpty {
                    viewModel.createChat(with: selectedUserIDs + [currentUserID], initialMessage: initialMessage, senderID: currentUserID)
                }
            }) {
                Text("Start Chat")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedUserIDs.isEmpty || initialMessage.isEmpty)
        }
        .navigationTitle("New Message")
    }
}

struct MultipleSelectionRow: View {
    var user: User
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(user.name)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

struct DMHomeView_Previews: PreviewProvider {
    static var previews: some View {
        DMHomeView()
    }
}

struct ChatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ChatDetailView(viewModel: DMViewModel(), chat: Chat(id: "chatID", users: ["user1", "user2"], lastMessage: "Hello", timestamp: Timestamp(date: Date())))
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        NewMessageView(viewModel: DMViewModel(), currentUserID: "current_user_id")
    }
}
