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
//    @State private var chats: [Chat] = [
//        Chat(name: "John Doe", initials: "JD", lastMessage: "Hey there!", timestamp: "5:11 PM", profileImage: nil, messages: [
//            Message(text: "Hello!", isCurrentUser: false, senderColor: .blue)
//        ]),
//        Chat(name: "Jane Smith", initials: "JS", lastMessage: "How's it going?", timestamp: "4:48 PM", profileImage: nil, messages: [
//            Message(text: "Hi!", isCurrentUser: false, senderColor: .green)
//        ]),
//        Chat(name: "Bob Brown", initials: "BB", lastMessage: "Okok", timestamp: "1:39 PM", profileImage: nil, messages: []),
//        Chat(name: "Alice Johnson", initials: "AJ", lastMessage: "Attachment: 1 Image", timestamp: "1:25 PM", profileImage: nil, messages: []),
//        Chat(name: "Charlie Davis", initials: "CD", lastMessage: "Thys grinding grinding", timestamp: "Yesterday", profileImage: nil, messages: [])
//    ]
    @State private var chats = [DBChat]()
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
//                            NavigationLink(destination: ChatView(chat: chat)) {
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
                                                
//                                                Text(chat.timestamp)
//                                                    .font(.system(size: 13))
//                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Text(chat.lastMessage ?? "")
                                                .font(.system(size: 15))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "dumbbell.fill")
                                            .foregroundColor(.gymSecondary)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 16)
//                                }
//                                .background(Color.gymBackground)
//                                .cornerRadius(12)
//                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .background(Color.clear)
            }
            .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
//            .sheet(isPresented: $showFindFriendsView) {
//                FindFriendsView(startNewChat: startNewChat)
//            }
            .onAppear {
                Task {
                    await fetchChats()
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func startNewChat(reciever: DBUser) async {
        guard let currentUser = userStore.currentUser else {
            print("no current user found")
            return
        }
        do {
            let participants = [currentUser.username, reciever.username]
            var initial = ""
            if let firstCharacter = reciever.username.first {
                initial = String(firstCharacter).uppercased()
            } else {
                print("could not find reciever's initial")
                initial = ""
            }
            let newChat = DBChat(
                participants: participants,
                name: reciever.username,
                initials: initial,
                lastMessage: nil,
                profileImage: nil
            )
            
            try await ChatManager.shared.createNewChat(chat: newChat)
        } catch {
            print("Error creating new chat: \(error.localizedDescription)")
        }
    }
    
    private func fetchChats() async {
        guard let currentUser = userStore.currentUser else {
            print("no current user data available")
            return
        }
        do {
            self.chats = try await ChatManager.shared.getChats(for: currentUser.userId)
            print("chats fetched")
        } catch {
            print("error fetching chats: \(error)")
        }
    }

}

struct DMHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        DMHomeView(showDMHomeView: .constant(false))
            .environmentObject(userStore)
    }
}

