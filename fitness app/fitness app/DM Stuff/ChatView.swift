//
//  ChatView.swift
//  fitnessapp
//
//  Created by Harris Kim on 6/17/24.
//

import SwiftUI

// ChatView

struct ChatView: View {
    @EnvironmentObject var userStore: UserStore
    @Environment(\.presentationMode) var presentationMode
    @State var chat: DBChat
    @State private var messageText = ""
    @State var messages = [DBMessage]()
    
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

                HStack {
                    if let profileImage = chat.profileImage, !profileImage.isEmpty {
                        Image(profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.gymAccent.opacity(0.2))
                                .frame(width: 50, height: 50)
                            Text(chat.initials)
                                .font(.headline)
                                .foregroundColor(.gymPrimary)
                        }
                    }

                    Text(chat.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gymPrimary)
                        .padding(.leading, 8)
                }
                .padding(.leading, 10) // Shift the combined view to the left

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.gymPrimary)
                    Text("7") // Placeholder for streak number
                        .foregroundColor(.gymPrimary)
                        .font(.system(size: 20, weight: .bold))
                }
                .padding(.trailing, 10)
            }
            .padding()
            .background(Color.gymBackground)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            .padding(.top, 10)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(self.messages) { message in
                        HStack {
                            if message.senderId == userStore.currentUser!.userId {
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
                                    .background(Color.green.opacity(0.8))
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
                    Task {
                        await sendMessage()
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .font(.system(size: 16, weight: .medium))

                Button(action: {
                    Task {
                        await sendMessage()
                    }
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
        .onAppear {
            Task {
                await fetchMessages()
            }
        }
    }

    private func sendMessage() async {
        guard !messageText.isEmpty else { return }
        guard let currentUser = userStore.currentUser else {
            print("no current user found")
            return
        }
        do {
            if let chatId = chat.id {
                let newMessage = DBMessage(chatId: chatId, senderId: currentUser.userId, text: messageText)
                
                try await ChatManager.shared.sendMessage(message: newMessage)
                await fetchMessages()
            }
        } catch {
            print("error sending message: \(error)")
        }
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
    
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let newChat = DBChat(
            participants: [],
            name: "mock user",
            initials: "M",
            lastMessage: nil,
            profileImage: nil
        )
        
        ChatView(chat: newChat)
    }
}
