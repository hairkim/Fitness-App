//
//  DM.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/4/24.
//

import SwiftUI
import Foundation

// Models

struct Chat: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    var lastMessage: String
    var timestamp: String
    var profileImage: String? // URL to the profile image
    var messages: [Message]
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isCurrentUser: Bool
    let senderColor: Color
}

struct Friend: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let workoutStatus: String
}

// Custom Colors
extension Color {
    static let gymPrimary = Color(red: 34 / 255, green: 34 / 255, blue: 34 / 255)
    static let gymSecondary = Color(red: 86 / 255, green: 167 / 255, blue: 124 / 255) // Muted green
    static let gymAccent = Color(red: 72 / 255, green: 201 / 255, blue: 176 / 255)
    static let gymBackground = Color(red: 245 / 255, green: 245 / 255, blue: 220 / 255) // Light beige
}

// DMHomeView

struct DMHomeView: View {
    @EnvironmentObject var userStore: UserStore
    @State private var chats: [Chat] = [
        Chat(name: "John Doe", initials: "JD", lastMessage: "Hey there!", timestamp: "5:11 PM", profileImage: nil, messages: [
            Message(text: "Hello!", isCurrentUser: false, senderColor: .blue)
        ]),
        Chat(name: "Jane Smith", initials: "JS", lastMessage: "How's it going?", timestamp: "4:48 PM", profileImage: nil, messages: [
            Message(text: "Hi!", isCurrentUser: false, senderColor: .green)
        ]),
        Chat(name: "Bob Brown", initials: "BB", lastMessage: "Okok", timestamp: "1:39 PM", profileImage: nil, messages: []),
        Chat(name: "Alice Johnson", initials: "AJ", lastMessage: "Attachment: 1 Image", timestamp: "1:25 PM", profileImage: nil, messages: []),
        Chat(name: "Charlie Davis", initials: "CD", lastMessage: "Thys grinding grinding", timestamp: "Yesterday", profileImage: nil, messages: [])
    ]
    @State private var showFindFriendsView = false
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.gymBackground.edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Text("Gym Chat")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.gymPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            showFindFriendsView.toggle()
                        }) {
                            Image(systemName: "person.badge.plus")
                                .imageScale(.large)
                                .padding()
                                .foregroundColor(.gymSecondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 20)

                    HStack {
                        TextField("Search", text: $searchText)
                            .padding(7)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                            .padding(.horizontal, 10)
                    }
                    .padding(.bottom, 10)
                    
                    ScrollView {
                        VStack(spacing: 15) { // Adjusted spacing between cards
                            ForEach(chats.filter { searchText.isEmpty ? true : $0.name.lowercased().contains(searchText.lowercased()) }) { chat in
                                VStack {
                                    HStack(spacing: 12) {
                                        if let profileImage = chat.profileImage, !profileImage.isEmpty {
                                            // Profile Image
                                            Image(profileImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 55, height: 55) // Medium size
                                                .clipShape(Circle())
                                        } else {
                                            // Initials Circle with Gym Icon
                                            ZStack {
                                                Circle()
                                                    .fill(Color.gymAccent.opacity(0.2))
                                                    .frame(width: 55, height: 55) // Medium size
                                                VStack {
                                                    Text(chat.initials)
                                                        .font(.headline)
                                                        .foregroundColor(.gymPrimary)
                                                    Image(systemName: "figure.walk")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 13, height: 13)
                                                        .foregroundColor(.gymAccent)
                                                }
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(chat.name)
                                                    .font(.system(size: 17, weight: .bold)) // Medium font size
                                                    .foregroundColor(.gymPrimary)
                                                
                                                Spacer()
                                                
                                                Text(chat.timestamp)
                                                    .font(.system(size: 13)) // Medium font size
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Text(chat.lastMessage)
                                                .font(.system(size: 15)) // Medium font size
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "dumbbell.fill")
                                            .foregroundColor(.gymSecondary)
                                    }
                                    .padding(.vertical, 16) // Medium padding
                                    .padding(.horizontal, 16) // Medium padding
                                }
                                .background(Color.gymBackground)
                                .cornerRadius(12) // Medium corner radius
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .background(Color.clear)
                }
                .padding(.top, 10)
                .sheet(isPresented: $showFindFriendsView) {
                    FindFriendsView(startNewChat: startNewChat)
                }
            }
        }
    }

    private func startNewChat(with friend: Friend) {
        let newChat = Chat(name: friend.name, initials: friend.initials, lastMessage: "", timestamp: "Now", profileImage: nil, messages: [])
        chats.append(newChat)
    }
}

struct DMHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        DMHomeView()
            .environmentObject(userStore)
    }
}

// ChatView

struct ChatView: View {
    @State var chat: Chat
    @State private var messageText = ""

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(chat.messages) { message in
                        HStack {
                            if message.isCurrentUser {
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
                                    .background(message.senderColor.opacity(0.8))
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
                    .font(.system(size: 16, weight: .medium))
                
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .imageScale(.large)
                        .foregroundColor(.gymSecondary)
                        .padding(.trailing)
                }
            }
            .padding()
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
    }
    
    private func sendMessage() {
        let newMessage = Message(text: messageText, isCurrentUser: true, senderColor: .gymPrimary)
        chat.messages.append(newMessage)
        messageText = ""
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(chat: Chat(name: "John Doe", initials: "JD", lastMessage: "Hey there!", timestamp: "5:11 PM", profileImage: nil, messages: [Message(text: "Hello!", isCurrentUser: false, senderColor: .green)]))
    }
}

// FindFriendsView

struct FindFriendsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var friends: [Friend] = [
        Friend(name: "Alice Johnson", initials: "AJ", workoutStatus: "Push Day"),
        Friend(name: "Bob Brown", initials: "BB", workoutStatus: "Rest Day"),
        Friend(name: "Charlie Davis", initials: "CD", workoutStatus: "Chest Day")
    ]
    var startNewChat: (Friend) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Find Friends")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.gymPrimary)
                        .padding(.leading)
                    
                    Spacer()
                }
                .padding(.vertical)
                
                ScrollView {
                    LazyVStack {
                        ForEach(friends) { friend in
                            Button(action: {
                                startNewChat(friend)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gymAccent.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                        VStack {
                                            Text(friend.initials)
                                                .font(.headline)
                                                .foregroundColor(.gymPrimary)
                                            Image(systemName: "figure.walk")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 12, height: 12)
                                                .foregroundColor(.gymAccent)
                                        }
                                    }
                                    
                                    Text(friend.name)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.gymPrimary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("")
        }
    }
}

struct FindFriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FindFriendsView(startNewChat: { _ in })
    }
}
