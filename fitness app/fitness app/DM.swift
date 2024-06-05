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

// DMHomeView

struct DMHomeView: View {
    @EnvironmentObject var userStore: UserStore
    @State private var chats: [Chat] = [
        Chat(name: "John Doe", initials: "JD", lastMessage: "Hey there!", messages: [
            Message(text: "Hello!", isCurrentUser: false, senderColor: .blue)
        ]),
        Chat(name: "Jane Smith", initials: "JS", lastMessage: "How's it going?", messages: [
            Message(text: "Hi!", isCurrentUser: false, senderColor: .green)
        ])
    ]
    @State private var friends: [Friend] = [
        Friend(name: "Alice Johnson", initials: "AJ", workoutStatus: "Push Day"),
        Friend(name: "Bob Brown", initials: "BB", workoutStatus: "Rest Day"),
        Friend(name: "Charlie Davis", initials: "CD", workoutStatus: "Chest Day")
    ]
    @State private var showFindFriendsView = false

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    // Title on the left
                    Text("Gym Chat")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.leading)
                    
                    Spacer()
                    
                    // Add Friend Button
                    Button(action: {
                        showFindFriendsView.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                            .foregroundColor(.black)
                            .padding(.trailing)
                    }
                }
                .padding(.vertical)
                
                // Friends' Profile Pictures with Workout Status
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(friends) { friend in
                            VStack {
                                Circle()
                                    .strokeBorder(Color.black, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                                Text(friend.name)
                                    .font(.caption)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: 60)
                                    .lineLimit(1)
                                Text(friend.workoutStatus)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: 60)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)

                ScrollView {
                    LazyVStack {
                        ForEach(chats) { chat in
                            NavigationLink(destination: ChatView(chat: chat)) {
                                HStack {
                                    Circle()
                                        .strokeBorder(Color.black, lineWidth: 2)
                                        .frame(width: 40, height: 40)
                                    
                                    VStack(alignment: .leading) {
                                        Text(chat.name)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.black)
                                        
                                        Text(chat.lastMessage)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 8)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "dumbbell.fill")
                                        .foregroundColor(.black)
                                        .padding(.trailing, 10)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .background(Color(red: 245 / 255, green: 245 / 255, blue: 220 / 255).edgesIgnoringSafeArea(.all))
            .navigationTitle("")
            .sheet(isPresented: $showFindFriendsView) {
                FindFriendsView(startNewChat: startNewChat)
            }
        }
    }
    
    private func startNewChat(with friend: Friend) {
        let newChat = Chat(name: friend.name, initials: friend.initials, lastMessage: "", messages: [])
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
                                    .background(Color.black.opacity(0.8))
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
                        .foregroundColor(.black)
                        .padding(.trailing)
                }
            }
            .padding()
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "bolt.heart.fill")
                    .foregroundColor(.black)
            }
        }
        .background(Color(red: 245 / 255, green: 245 / 255, blue: 220 / 255).edgesIgnoringSafeArea(.all))
    }
    
    private func sendMessage() {
        let newMessage = Message(text: messageText, isCurrentUser: true, senderColor: .black)
        chat.messages.append(newMessage)
        messageText = ""
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(chat: Chat(name: "John Doe", initials: "JD", lastMessage: "Hey there!", messages: [Message(text: "Hello!", isCurrentUser: false, senderColor: .green)]))
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
                        .foregroundColor(.black)
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
                                    Circle()
                                        .strokeBorder(Color.black, lineWidth: 2)
                                        .frame(width: 40, height: 40)
                                    
                                    Text(friend.name)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .background(Color(red: 245 / 255, green: 245 / 255, blue: 220 / 255).edgesIgnoringSafeArea(.all))
            .navigationTitle("")
        }
    }
}

struct FindFriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FindFriendsView(startNewChat: { _ in })
    }
}

// Extensions

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
