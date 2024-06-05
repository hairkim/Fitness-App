//
//  Leaderboard.swift
//  fitnessapp
//
//  Created by Ryan Kim on 6/3/24.
//

import SwiftUI

struct LeaderboardView: View {
    let leaderboardData: [LeaderboardEntry] = [
        LeaderboardEntry(name: "Friend1", streak: 100),
        LeaderboardEntry(name: "Friend2", streak: 90),
        LeaderboardEntry(name: "Friend3", streak: 80),
        LeaderboardEntry(name: "Friend4", streak: 70),
        LeaderboardEntry(name: "Friend5", streak: 60),
        LeaderboardEntry(name: "Friend6", streak: 50),
        LeaderboardEntry(name: "Friend7", streak: 40),
        LeaderboardEntry(name: "Friend8", streak: 30),
        LeaderboardEntry(name: "Friend9", streak: 20),
        LeaderboardEntry(name: "Friend10", streak: 10)
    ]

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(.systemIndigo), Color(.systemPurple)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Leaderboard")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(leaderboardData.indices, id: \.self) { index in
                            LeaderboardRowView(entry: leaderboardData[index], rank: index + 1)
                            if index < leaderboardData.count - 1 {
                                Divider().background(Color.white)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitle("Leaderboard", displayMode: .inline)
    }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let name: String
    let streak: Int
}

struct LeaderboardRowView: View {
    var entry: LeaderboardEntry
    var rank: Int

    var body: some View {
        HStack {
            specialRankIcon(for: rank)
                .font(.headline)
                .frame(width: 40, alignment: .center)

            VStack(alignment: .leading) {
                Text(entry.name)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                Text("Streak: \(entry.streak)")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }

            Spacer()

            Text("\(entry.streak)")
                .font(.title2)
                .bold()
                .padding(12)
                .background(background(for: rank))
                .clipShape(Circle())
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground(for: rank))
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    func specialRankIcon(for rank: Int) -> some View {
        switch rank {
        case 1:
            return AnyView(Image(systemName: "star.fill").foregroundColor(.yellow))
        case 2:
            return AnyView(Image(systemName: "star.fill").foregroundColor(.silver))
        case 3:
            return AnyView(Image(systemName: "star.fill").foregroundColor(.bronze))
        default:
            return AnyView(Text("\(rank)").foregroundColor(.white))
        }
    }

    func background(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.brown
        default: return .clear
        }
    }
    
    func rowBackground(for rank: Int) -> Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.2)
        case 2: return Color.gray.opacity(0.2)
        case 3: return Color.brown.opacity(0.2)
        default: return Color.clear
        }
    }
}

extension Color {
    static let silver = Color(UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0))
    static let bronze = Color(UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0))
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
    }
}
