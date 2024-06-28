//
//  DM.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/4/24.
//

import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift


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
    @State var chatRooms: [DBChat] = []
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
                    ForEach(chatRooms.filter {
                        searchText.isEmpty ? true : $0.participantNames.contains { id, name in
                            name.lowercased().contains(searchText.lowercased())
                        }
                    }) { (chatRoom) in
                        SearchChatView(chatRoom: chatRoom)
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
            self.chatRooms = try await ChatManager.shared.getChats(for: currentUser.userId)
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
