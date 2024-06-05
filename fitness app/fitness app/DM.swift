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
}

// DMHomeView

struct DMHomeView: View {
    @EnvironmentObject var userStore: UserStore
    @State private var chats: [Chat] = [
        Chat(name: "John Doe", initials: "JD", lastMessage: "Hey there!", messages: [
            Message(text: "Hello!", isCurrentUser: false, senderColor: .green)
        ]),
        Chat(name: "Jane Smith", initials: "JS", lastMessage: "How's it going?", messages: [
            Message(text: "Hi!", isCurrentUser: false, senderColor: .red)
        ])
    ]
    @State private var showFindFriendsView = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                VStack {
                    HStack {
                        Text("Gym Chat")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(Color.purple)
                            .padding(.leading)
                        
                        Spacer()
                        
                        Button(action: {
                            showFindFriendsView.toggle()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.large)
                                .foregroundColor(Color.purple)
                                .padding(.trailing)
                        }
                    }
                    .padding(.vertical)

                    ScrollView {
                        LazyVStack {
                            ForEach(chats) { chat in
                                NavigationLink(destination: ChatView(chat: chat)) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.purple)
                                            
                                            Text(chat.initials)
                                                .foregroundColor(.white)
                                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text(chat.name)
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(.purple)
                                            
                                            Text(chat.lastMessage)
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(.purple.opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "figure.walk.circle.fill")
                                            .foregroundColor(.purple)
                                            .padding(.trailing, 10)
                                    }
                                    .padding()
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
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
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(chat.messages) { message in
                            HStack {
                                if message.isCurrentUser {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.purple.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(20, corners: [.topLeft, .bottomLeft, .topRight])
                                        .padding(.trailing)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .background(message.senderColor.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(20, corners: [.topRight, .bottomRight, .topLeft])
                                        .padding(.leading)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
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
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .imageScale(.large)
                            .foregroundColor(.purple)
                            .padding(.trailing)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "bolt.heart.fill")
                    .foregroundColor(.purple)
            }
        }
    }
    
    private func sendMessage() {
        let newMessage = Message(text: messageText, isCurrentUser: true, senderColor: .purple)
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
        Friend(name: "Alice Johnson", initials: "AJ"),
        Friend(name: "Bob Brown", initials: "BB"),
        Friend(name: "Charlie Davis", initials: "CD")
    ]
    var startNewChat: (Friend) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                VStack {
                    HStack {
                        Text("Find Friends")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(Color.purple)
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
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.purple)
                                            
                                            Text(friend.initials)
                                                .foregroundColor(.white)
                                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                        }
                                        
                                        Text(friend.name)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(.purple)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "figure.walk.circle.fill")
                                            .foregroundColor(.purple)
                                            .padding(.trailing, 10)
                                    }
                                    .padding()
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
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
