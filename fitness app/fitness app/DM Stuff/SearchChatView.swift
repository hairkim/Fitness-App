//
//  SearchChatView.swift
//  fitnessapp
//
//  Created by Harris Kim on 6/28/24.
//

import SwiftUI

struct SearchChatView: View {
    @EnvironmentObject var userStore: UserStore
    let chatRoom: DBChat
    
    var body: some View {
        NavigationLink(destination: ChatView(chat: chatRoom)) {
            VStack {
                HStack(spacing: 12) {
                    if let profileImage = chatRoom.profileImage, !profileImage.isEmpty {
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
                                Text(chatInitials(for: chatRoom))
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
                            Text(chatName(for: chatRoom))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.gymPrimary)
                            
                            Spacer()
                            
                            Text(chatRoom.timestamp.dateValue(), style: .time)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        
                        Text(chatRoom.lastMessage ?? "")
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
        }
        
    }
        
    private func chatName(for chat: DBChat) -> String {
        if let currentUserId = userStore.currentUser?.userId {
            // Exclude the current user's name from the participant names
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
            // Exclude the current user's initials from the participant names and get initials for other participants
            return chat.participantNames
                .filter { $0.key != currentUserId }
                .map { $0.value.initials() }
                .joined(separator: ", ")
        } else {
            print("couldnt find user id")
            return ""
        }
    }
}
    
extension String {
    func initials() -> String {
        self.split(separator: " ")
            .map { $0.first.map { String($0) } ?? "" }
            .joined()
    }
}

struct SearchChatView_Previews: PreviewProvider {
    static var previews: some View {
        let userStore = UserStore()
        let newChat = DBChat(
            participants: [],
            participantNames: ["":""],
            lastMessage: "",
            profileImage: nil
        )
        SearchChatView(chatRoom: newChat)
            .environmentObject(userStore)
    }
}
