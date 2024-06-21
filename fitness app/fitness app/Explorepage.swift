//
//  Explorepage.swift
//  fitnessapp
//
//  Created by Ryan Kim on 6/20/24.
//

import SwiftUI

struct ExploreView: View {
    let items = Array(1...10).map { "Item \($0)" }

    var body: some View {
        NavigationView {
            VStack {
                Text("Explore")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                TabView {
                    ForEach(items, id: \.self) { item in
                        ExploreItemView(item: item)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .padding()
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            }
            .navigationBarHidden(true)
        }
    }
}

struct ExploreItemView: View {
    let item: String

    var body: some View {
        VStack {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                
                HStack(spacing: 20) {
                    Button(action: {
                        // Like action
                    }) {
                        Image(systemName: "heart")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                    
                    Button(action: {
                        // Comment action
                    }) {
                        Image(systemName: "message")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                    
                    Button(action: {
                        // Share action
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                }
                .padding()
            }

            Text(item)
                .font(.headline)
                .padding(.top)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}

