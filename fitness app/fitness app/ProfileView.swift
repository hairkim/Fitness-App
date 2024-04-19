//
//  ProfileView.swift
//  FitnessApp
//
//  Created by Harris Kim on 2/4/24.
//

import SwiftUI


@MainActor
final class ProfileViewModel: ObservableObject{
    
    @Published private(set) var user: AuthDataResultModel? = nil
    
    func loadCurrentUser() throws{
        self.user = try  AuthenticationManager.shared.getAuthenticatedUser()
    }
    
}

struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        List {
            Text("")
        }
        .onAppear{
            try? viewModel.loadCurrentUser()
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "gear")
                    .font(.headline)
            }
        }
    }
    
    
    
    
    
    //    // Example posts data
    //    let posts = (1...21).map { "Post \($0)" } // Replace with your post model or images
    //
    //    // State to manage expanded row
    //    @State private var expandedRow: Int? = nil
    //
    //    // Calculate number of rows based on posts count
    //    var numberOfRows: Int {
    //        return (posts.count + columns.count - 1) / columns.count
    //    }
    //
    //    // Grid layout configuration
    //    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7)
    //
    //    var body: some View {
    //        ScrollView {
    //            VStack(alignment: .center, spacing: 10) {
    //                // Profile Image
    //                Image("naruto")
    //                    .resizable()
    //                    .scaledToFit()
    //                    .clipShape(Circle())
    //                    .frame(width: 100, height: 100)
    //                    .padding(.top, 20)
    //
    //                // Name and Bio
    //                Text("Naruto Uzumaki")
    //                    .font(.title)
    //                Text("Just another tech enthusiast.")
    //                    .font(.subheadline)
    //
    //                // Posts Grid
    //                ForEach(0..<numberOfRows, id: \.self) { rowIndex in
    //                    if expandedRow == rowIndex {
    //                        // Expanded Row
    //                        ScrollView(.horizontal, showsIndicators: false) {
    //                            HStack(spacing: 10) {
    //                                ForEach(rowIndex*columns.count..<min((rowIndex+1)*columns.count, posts.count), id: \.self) { index in
    //                                    // Placeholder for posts, replace with actual image view
    //                                    Text(posts[index])
    //                                        .frame(width: 50, height: 50)
    //                                        .background(Color.gray)
    //                                        .cornerRadius(8)
    //                                        .onTapGesture {
    //                                            // Handle navigation to individual post view
    //                                        }
    //                                }
    //                            }
    //                        }
    //                        .frame(height: 100) // Adjust size as needed
    //                        .onTapGesture {
    //                            self.expandedRow = nil // Collapse the row
    //                        }
    //                    } else {
    //                        // Collapsed Row
    //                        HStack(spacing: 10) {
    //                            ForEach(rowIndex*columns.count..<min((rowIndex+1)*columns.count, posts.count), id: \.self) { index in
    //                                // Placeholder for posts, replace with actual image view
    //                                Text(posts[index])
    //                                    .frame(width: 50, height: 50)
    //                                    .background(Color.gray)
    //                                    .cornerRadius(8)
    //                                    .onTapGesture {
    //                                        self.expandedRow = rowIndex // Expand the row
    //                                    }
    //                            }
    //                        }
    //                    }
    //                }
    //                .padding(.top, 20)
    //            }
    //            .padding()
    //        }
    //    }
    //}
    
    // Uncomment this to see the preview in Xcode
    struct ProfileView_Previews: PreviewProvider {
        static var previews: some View {
            ProfileView()
        }
    }
}
