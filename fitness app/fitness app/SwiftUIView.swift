//
//  SwiftUIView.swift
//  fitnessapp
//
//  Created by Harris Kim on 7/6/24.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
        NavigationLink(destination: CreateQuestionView(onAddQuestion: addQuestion), isActive: $isShowingQuestionForm) {
            EmptyView()
        }
    }
}

#Preview {
    SwiftUIView()
}
