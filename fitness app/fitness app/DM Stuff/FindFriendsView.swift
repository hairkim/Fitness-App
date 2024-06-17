////
////  FindFriendsView.swift
////  fitnessapp
////
////  Created by Harris Kim on 6/17/24.
////
//
//import SwiftUI
//
//// FindFriendsView
//
//struct FindFriendsView: View {
//    @Environment(\.presentationMode) var presentationMode
////    @State private var friends: [Friend] = [
////        Friend(name: "Alice Johnson", initials: "AJ", workoutStatus: "Push Day"),
////        Friend(name: "Bob Brown", initials: "BB", workoutStatus: "Rest Day"),
////        Friend(name: "Charlie Davis", initials: "CD", workoutStatus: "Chest Day"),
////        Friend(name: "David Evans", initials: "DE", workoutStatus: "Leg Day"),
////        Friend(name: "Eve Foster", initials: "EF", workoutStatus: "Arm Day")
////    ]
//    @State private var friends = [DBUser]()
////    @State private var contacts: [Friend] = [
////        Friend(name: "Grace Hill", initials: "GH", workoutStatus: "Rest Day"),
////        Friend(name: "Hannah Lee", initials: "HL", workoutStatus: "Yoga Day"),
////        Friend(name: "Isaac Smith", initials: "IS", workoutStatus: "Cardio Day"),
////        Friend(name: "Jackie Wong", initials: "JW", workoutStatus: "Upper Body")
////    ]
//    var startNewChat: (DBUser) -> Void
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                HStack {
//                    Text("Find Friends")
//                        .font(.system(size: 28, weight: .bold))
//                        .foregroundColor(.gymPrimary)
//                        .padding(.leading)
//                    
//                    Spacer()
//                    
//                    Button(action: {
//                        presentationMode.wrappedValue.dismiss()
//                    }) {
//                        Image(systemName: "xmark")
//                            .foregroundColor(.gymPrimary)
//                            .padding()
//                    }
//                }
//                .padding(.top)
//                .padding(.bottom, 10)
//                
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 20) {
//                        ForEach(friends) { friend in
//                            VStack {
//                                HStack {
//                                    Spacer()
//                                    Button(action: {
//                                        // Action for removing this friend card
//                                    }) {
//                                        Image(systemName: "xmark")
//                                            .foregroundColor(.gray)
//                                            .padding(5)
//                                    }
//                                }
//                                
//                                ZStack {
//                                    Circle()
//                                        .fill(Color.gymAccent.opacity(0.2))
//                                        .frame(width: 75, height: 75)
//                                    VStack {
//                                        Text(friend.initials)
//                                            .font(.headline)
//                                            .foregroundColor(.gymPrimary)
//                                        Image(systemName: "figure.walk")
//                                            .resizable()
//                                            .scaledToFit()
//                                            .frame(width: 15, height: 15)
//                                            .foregroundColor(.gymAccent)
//                                    }
//                                }
//                                
//                                Text(friend.name)
//                                    .font(.system(size: 16, weight: .bold))
//                                    .foregroundColor(.gymPrimary)
//                                    .padding(.top, 5)
//                                
//                                Button(action: {
//                                    startNewChat(friend)
//                                    presentationMode.wrappedValue.dismiss()
//                                }) {
//                                    Text("Follow")
//                                        .font(.system(size: 14, weight: .bold))
//                                        .padding(.horizontal, 12)
//                                        .padding(.vertical, 6)
//                                        .background(Color.gymAccent)
//                                        .foregroundColor(.white)
//                                        .cornerRadius(8)
//                                }
//                            }
//                            .padding()
//                            .frame(width: 120, height: 200)
//                            .background(Color.white)
//                            .cornerRadius(12)
//                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//                .padding(.bottom)
//                
//                Divider().padding(.horizontal)
//                
//                HStack {
//                    Text("Contacts")
//                        .font(.system(size: 24, weight: .bold))
//                        .foregroundColor(.gymPrimary)
//                        .padding(.leading)
//                    Spacer()
//                }
//                .padding(.top, 10)
//                .padding(.bottom, 5)
//                
////                ScrollView {
////                    VStack(spacing: 15) {
////                        ForEach(contacts) { contact in
////                            HStack {
////                                ZStack {
////                                    Circle()
////                                        .fill(Color.gymAccent.opacity(0.2))
////                                        .frame(width: 50, height: 50)
////                                    VStack {
////                                        Text(contact.initials)
////                                            .font(.headline)
////                                            .foregroundColor(.gymPrimary)
////                                        Image(systemName: "figure.walk")
////                                            .resizable()
////                                            .scaledToFit()
////                                            .frame(width: 12, height: 12)
////                                            .foregroundColor(.gymAccent)
////                                    }
////                                }
////                                
////                                VStack(alignment: .leading) {
////                                    Text(contact.name)
////                                        .font(.system(size: 16, weight: .bold))
////                                        .foregroundColor(.gymPrimary)
////                                    Text(contact.workoutStatus)
////                                        .font(.system(size: 14))
////                                        .foregroundColor(.gray)
////                                }
////                                
////                                Spacer()
////                                
////                                Button(action: {
////                                    startNewChat(contact)
////                                }) {
////                                    Text("Follow")
////                                        .font(.system(size: 14, weight: .bold))
////                                        .padding(.horizontal, 12)
////                                        .padding(.vertical, 6)
////                                        .background(Color.gymAccent)
////                                        .foregroundColor(.white)
////                                        .cornerRadius(8)
////                                }
////                            }
////                            .padding()
////                            .frame(height: 80)
////                            .background(Color.white)
////                            .cornerRadius(12)
////                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
////                        }
////                    }
////                    .padding(.horizontal)
////                }
////                .padding(.top)
//                
//                Spacer()
//            }
//            .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
//            .navigationTitle("")
//        }
//        .background(Color.gymBackground.edgesIgnoringSafeArea(.all))
//    }
//}
//
//struct FindFriendsView_Previews: PreviewProvider {
//    static var previews: some View {
//        FindFriendsView(startNewChat: { _ in })
//    }
//}
