//
//  UserProfileView.swift
//  fitnessapp
//
//  Created by Harris Kim on 6/5/24.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var userStore: UserStore
    
    
    var body: some View {
        Button(action: {
            //add as a follower
        }) {
            Text("follow")
        }
    }
}

#Preview {
    UserProfileView()
}
