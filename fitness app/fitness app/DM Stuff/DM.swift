//
//  DM.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/4/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


struct DMHomeView: View {
    @EnvironmentObject var userStore: UserStore
    @Binding var showDMHomeView: Bool
    @State private var chats = [DBChat]()
    
    var body: some View {
        NavigationView {
            List(chats) { chat in
                NavigationLink(destination: ChatView(chat: chat).environmentObject(userStore)) {
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

                        VStack(alignment: .leading) {
                            Text(chatName(for: chat))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(chat.lastMessage ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                        
                        if let currentUserId = userStore.currentUser?.userId,
                           chat.unreadMessages[currentUserId] ?? 0 > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarItems(leading: Button(action: {
                withAnimation {
                    showDMHomeView.toggle()
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            })
            .onAppear {
                fetchChats()
            }
        }
    }

    private func chatName(for chat: DBChat) -> String {
        if let currentUserId = userStore.currentUser?.userId {
            return chat.participantNames
                .filter { $0.key != currentUserId }
                .map { $0.value }
                .joined(separator: ", ")
        } else {
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
            return ""
        }
    }
    
    private func fetchChats() {
        Task {
            guard let currentUserID = userStore.currentUser?.userId else { return }
            do {
                self.chats = try await ChatManager.shared.getChats(for: currentUserID)
            } catch {
                print("Error fetching chats: \(error)")
            }
        }
    }
}

struct DMHomeView_Previews: PreviewProvider {
    static var previews: some View {
        DMHomeView(showDMHomeView: .constant(true))
            .environmentObject(UserStore())
    }
}
