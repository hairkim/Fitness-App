////
////  ChatView.swift
////  fitnessapp
////
////  Created by Harris Kim on 6/17/24.
////
//
//import SwiftUI
//
//// ChatView
//
//struct ChatView: View {
//    @Environment(\.presentationMode) var presentationMode
//    @State var chat: Chat
//    @State private var messageText = ""
//
//    var body: some View {
//        VStack {
//            // Header
//            HStack {
//                Button(action: {
//                    self.presentationMode.wrappedValue.dismiss()
//                }) {
//                    Image(systemName: "chevron.left")
//                        .foregroundColor(.gymPrimary)
//                        .padding(.leading, 10)
//                }
//
//                HStack {
//                    if let profileImage = chat.profileImage, !profileImage.isEmpty {
//                        Image(profileImage)
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .frame(width: 50, height: 50)
//                            .clipShape(Circle())
//                    } else {
//                        ZStack {
//                            Circle()
//                                .fill(Color.gymAccent.opacity(0.2))
//                                .frame(width: 50, height: 50)
//                            Text(chat.initials)
//                                .font(.headline)
//                                .foregroundColor(.gymPrimary)
//                        }
//                    }
//
//                    Text(chat.name)
//                        .font(.system(size: 20, weight: .bold))
//                        .foregroundColor(.gymPrimary)
//                        .padding(.leading, 8)
//                }
//                .padding(.leading, 10) // Shift the combined view to the left
//
//                Spacer()
//
//                HStack(spacing: 4) {
//                    Image(systemName: "dumbbell.fill")
//                        .foregroundColor(.gymPrimary)
//                    Text("7") // Placeholder for streak number
//                        .foregroundColor(.gymPrimary)
//                        .font(.system(size: 20, weight: .bold))
//                }
//                .padding(.trailing, 10)
//            }
//            .padding()
//            .background(Color.gymBackground)
//            .cornerRadius(10)
//            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
//            .padding(.top, 10)
//
//            ScrollView {
//                VStack(spacing: 10) {
//                    ForEach(chat.messages) { message in
//                        HStack {
//                            if message.isCurrentUser {
//                                Spacer()
//                                Text(message.text)
//                                    .padding()
//                                    .background(Color.gymPrimary.opacity(0.8))
//                                    .foregroundColor(.white)
//                                    .cornerRadius(16)
//                                    .padding(.trailing)
//                                    .font(.system(size: 16, weight: .bold))
//                            } else {
//                                Text(message.text)
//                                    .padding()
//                                    .background(message.senderColor.opacity(0.8))
//                                    .foregroundColor(.white)
//                                    .cornerRadius(16)
//                                    .padding(.leading)
//                                    .font(.system(size: 16, weight: .bold))
//                                Spacer()
//                            }
//                        }
//                    }
//                }
//                .padding()
//            }
//
//            HStack {
//                TextField("Type your message...", text: $messageText, onCommit: {
//                    self.sendMessage()
//                })
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding(.horizontal)
//                .font(.system(size: 16, weight: .medium))
//
//                Button(action: {
//                    self.sendMessage()
//                }) {
//                    Image(systemName: "paperplane.fill")
//                        .imageScale(.large)
//                        .foregroundColor(.gymSecondary)
//                        .padding(.trailing)
//                }
//            }
//            .padding()
//        }
//        .navigationTitle("")
//        .navigationBarHidden(true)
//        .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
//    }
//
//    private func sendMessage() {
//        guard !messageText.isEmpty else { return }
//        let newMessage = Message(text: messageText, isCurrentUser: true, senderColor: .gymPrimary)
//        chat.messages.append(newMessage)
//        DispatchQueue.main.async {
//            messageText = "" // Clear the text field
//        }
//    }
//}
//
//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView(chat: Chat(name: "John Doe", initials: "JD", lastMessage: "Hey there!", timestamp: "5:11 PM", profileImage: nil, messages: [Message(text: "Hello!", isCurrentUser: false, senderColor: .green)]))
//    }
//}
