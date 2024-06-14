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
    @Binding var showDMHomeView: Bool
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
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            showDMHomeView = false
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gymPrimary)
                            .padding(.leading, 10)
                    }
                    
                    Spacer()
                    
                    Text("Gym Chat")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.gymPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        showFindFriendsView.toggle()
                    }) {
                        Image(systemName: "person.badge.plus")
                            .imageScale(.large)
                            .foregroundColor(.gymSecondary)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.horizontal, 10)
                .frame(height: 44) // Align with standard navigation bar height

                HStack {
                    TextField("Search", text: $searchText)
                        .padding(7)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                }
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(chats.filter { searchText.isEmpty ? true : $0.name.lowercased().contains(searchText.lowercased()) }) { chat in
                            NavigationLink(destination: ChatView(chat: chat)) {
                                VStack {
                                    HStack(spacing: 12) {
                                        if let profileImage = chat.profileImage, !profileImage.isEmpty {
                                            Image(profileImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 55, height: 55)
                                                .clipShape(Circle())
                                        } else {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.gymAccent.opacity(0.2))
                                                    .frame(width: 55, height: 55)
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
                                                    .font(.system(size: 17, weight: .bold))
                                                    .foregroundColor(.gymPrimary)
                                                
                                                Spacer()
                                                
                                                Text(chat.timestamp)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Text(chat.lastMessage)
                                                .font(.system(size: 15))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "dumbbell.fill")
                                            .foregroundColor(.gymSecondary)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 16)
                                }
                                .background(Color.gymBackground)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .background(Color.clear)
            }
            .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $showFindFriendsView) {
                FindFriendsView(startNewChat: startNewChat)
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func startNewChat(with friend: Friend) {
        let newChat = Chat(name: friend.name, initials: friend.initials, lastMessage: "", timestamp: "Now", profileImage: nil, messages: [])
        chats.append(newChat)
    }
}

struct DMHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        DMHomeView(showDMHomeView: .constant(false))
            .environmentObject(userStore)
    }
}

// ChatView

struct ChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var chat: Chat
    @State private var messageText = ""

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
                
                Spacer()
                
                Text(chat.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gymPrimary)
                
                Spacer()
                
                if let profileImage = chat.profileImage, !profileImage.isEmpty {
                    Image(profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .padding(.leading, 10)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.gymAccent.opacity(0.2))
                            .frame(width: 50, height: 50)
                        Text(chat.initials)
                            .font(.headline)
                            .foregroundColor(.gymPrimary)
                    }
                    .padding(.leading, 10)
                }
            }
            .padding()
            .background(Color.gymBackground)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            .padding(.top, 10)
            
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
                TextField("Type your message...", text: $messageText, onCommit: {
                    self.sendMessage()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .font(.system(size: 16, weight: .medium))
                
                Button(action: {
                    self.sendMessage()
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
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let newMessage = Message(text: messageText, isCurrentUser: true, senderColor: .gymPrimary)
        chat.messages.append(newMessage)
        DispatchQueue.main.async {
            messageText = "" // Clear the text field
        }
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
        Friend(name: "Charlie Davis", initials: "CD", workoutStatus: "Chest Day"),
        Friend(name: "David Evans", initials: "DE", workoutStatus: "Leg Day"),
        Friend(name: "Eve Foster", initials: "EF", workoutStatus: "Arm Day")
    ]
    @State private var contacts: [Friend] = [
        Friend(name: "Grace Hill", initials: "GH", workoutStatus: "Rest Day"),
        Friend(name: "Hannah Lee", initials: "HL", workoutStatus: "Yoga Day"),
        Friend(name: "Isaac Smith", initials: "IS", workoutStatus: "Cardio Day"),
        Friend(name: "Jackie Wong", initials: "JW", workoutStatus: "Upper Body")
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
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gymPrimary)
                            .padding()
                    }
                }
                .padding(.top)
                .padding(.bottom, 10)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(friends) { friend in
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        // Action for removing this friend card
                                    }) {
                                        Image(systemName: "xmark")
                                            .foregroundColor(.gray)
                                            .padding(5)
                                    }
                                }
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.gymAccent.opacity(0.2))
                                        .frame(width: 75, height: 75)
                                    VStack {
                                        Text(friend.initials)
                                            .font(.headline)
                                            .foregroundColor(.gymPrimary)
                                        Image(systemName: "figure.walk")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 15, height: 15)
                                            .foregroundColor(.gymAccent)
                                    }
                                }
                                
                                Text(friend.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gymPrimary)
                                    .padding(.top, 5)
                                
                                Button(action: {
                                    startNewChat(friend)
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("Follow")
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gymAccent)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .frame(width: 120, height: 200)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                Divider().padding(.horizontal)
                
                HStack {
                    Text("Contacts")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gymPrimary)
                        .padding(.leading)
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(contacts) { contact in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.gymAccent.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    VStack {
                                        Text(contact.initials)
                                            .font(.headline)
                                            .foregroundColor(.gymPrimary)
                                        Image(systemName: "figure.walk")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, height: 12)
                                            .foregroundColor(.gymAccent)
                                    }
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(contact.name)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.gymPrimary)
                                    Text(contact.workoutStatus)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    startNewChat(contact)
                                }) {
                                    Text("Follow")
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gymAccent)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .frame(height: 80)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
                
                Spacer()
            }
            .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("")
        }
        .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
    }
}

struct FindFriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FindFriendsView(startNewChat: { _ in })
    }
}
