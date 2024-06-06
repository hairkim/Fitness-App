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

// Custom Colors
extension Color {
    static let gymPrimary = Color(red: 34 / 255, green: 34 / 255, blue: 34 / 255)
    static let gymSecondary = Color(red: 255 / 255, green: 128 / 255, blue: 0 / 255)
    static let gymBackground = Color(red: 245 / 255, green: 245 / 255, blue: 220 / 255) // Beige color
}

// Helper function to get a unique color based on initials
func color(for initials: String) -> Color {
    let colors: [Color] = [.red, .blue, .green, .purple, .orange, .pink, .yellow, .cyan]
    let index = abs(initials.hashValue) % colors.count
    return colors[index]
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
        ]),
        Chat(name: "Bob Brown", initials: "BB", lastMessage: "", messages: []),
        Chat(name: "Alice Johnson", initials: "AJ", lastMessage: "", messages: []),
        Chat(name: "Charlie Davis", initials: "CD", lastMessage: "", messages: [])
    ]
    @State private var showFindFriendsView = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background icon
                GeometryReader { geometry in
                    Image("gymIcon")
                        .resizable()
                        .scaledToFit()
                        .opacity(0.05) // Make sure the opacity is low to give a faded effect
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.4)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 4) // Position the icon
                }
                .edgesIgnoringSafeArea(.all)

                VStack {
                    HStack {
                        // Title on the left
                        Text("Gym Chat")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.gymPrimary)
                            .padding(.leading)
                        
                        Spacer()
                        
                        // Add Friend Button
                        Button(action: {
                            showFindFriendsView.toggle()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.large)
                                .foregroundColor(.gymSecondary)
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
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                            Text(chat.initials)
                                                .font(.headline)
                                                .foregroundColor(.gymPrimary)
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text(chat.name)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.gymPrimary)
                                            
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
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.9))
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                    )
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                    }
                }
                .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
                .navigationTitle("")
                .sheet(isPresented: $showFindFriendsView) {
                    FindFriendsView(startNewChat: startNewChat)
                }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "bolt.heart.fill")
                    .foregroundColor(.gymSecondary)
            }
        }
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
                        .foregroundColor(.primary)
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
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Text(friend.initials)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Text(friend.name)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.9))
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                )
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
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
