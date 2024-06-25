//
//  DM.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/4/24.
//

import SwiftUI
import Foundation


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
                
                List {
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
                                                Text(chat.name.prefix(1)) // Assuming initials are the first character of the name
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
                                            
                                            // Assuming `timestamp` is a `Timestamp` object, you need to format it for display
                                            Text(chat.timestamp.dateValue(), style: .time)
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
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
                            }
                        }
                    }
                }
                .background(Color.clear)
            }
            .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
//            .sheet(isPresented: $showFindFriendsView) {
//                FindFriendsView(startNewChat: startNewChat)
//            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            Task {
                await fetchChats()
            }
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
