//
//  Search.swift
//  fitnessapp
//
//  Created by Daniel Han on 6/18/24.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var users = [DBUser]()
    @Binding var selectedUser: DBUser? // Binding to pass the selected user to the parent view
    @State private var isUserSelected: Bool = false

    var body: some View {
        VStack {
            CustomSearchBar(text: $searchText, placeholder: "Search users")
                .padding(.horizontal)
                .onChange(of: searchText) { newValue in
                    searchUsers(query: newValue)
                }

            List(users) { user in
                Button(action: {
                    selectedUser = user // Set the selected user
                    isUserSelected = true // Trigger the navigation
                }) {
                    HStack {
                        if let photoUrl = user.photoUrl, let url = URL(string: photoUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                        VStack(alignment: .leading) {
                            Text(user.username)
                                .font(.headline)
                            Text(user.email ?? "")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search Users")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            NavigationLink(
                destination: UserProfileView(postUser: selectedUser ?? DBUser.placeholder),
                isActive: $isUserSelected,
                label: { EmptyView() }
            )
        )
    }

    private func searchUsers(query: String) {
        Task {
            do {
                let allUsers = try await UserManager.shared.getAllUsers()
                self.users = allUsers.filter { $0.username.lowercased().contains(query.lowercased()) }
            } catch {
                print("Error searching users: \(error)")
            }
        }
    }
}

// CustomSearchBar component
struct CustomSearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

// Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(selectedUser: .constant(nil))
    }
}
