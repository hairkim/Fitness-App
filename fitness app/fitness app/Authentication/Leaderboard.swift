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
        LeaderboardEntry(name: "Friend5", streak: 60)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Leaderboard")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)
                .padding(.top)

            ForEach(leaderboardData.indices, id: \.self) { index in
                LeaderboardRowView(entry: leaderboardData[index], rank: index + 1)
                if index < leaderboardData.count - 1 {
                    Divider()
                }
            }
        }
        .background(Color(.systemBackground))
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
                    .font(.subheadline)
                    .bold()
                Text("Streak: \(entry.streak)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("\(entry.streak)")
                .font(.headline)
                .bold()
                .padding(12)
                .background(background(for: rank))
                .clipShape(Circle())
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground(for: rank))
    }

    func specialRankIcon(for rank: Int) -> some View {
        switch rank {
        case 1:
            return AnyView(Image(systemName: "trophy.fill").foregroundColor(.orange))
        case 2:
            return AnyView(Image(systemName: "trophy.fill").foregroundColor(.blue))
        case 3:
            return AnyView(Image(systemName: "trophy.fill").foregroundColor(.green))
        default:
            return AnyView(Text("\(rank)").foregroundColor(.primary))
        }
    }

    func background(for rank: Int) -> Color {
        switch rank {
        case 1: return .orange
        case 2: return .blue
        case 3: return .green
        default: return .clear
        }
    }
    
    func rowBackground(for rank: Int) -> Color {
        switch rank {
        case 1: return Color.orange.opacity(0.2)
        case 2: return Color.blue.opacity(0.2)
        case 3: return Color.green.opacity(0.2)
        default: return Color.clear
        }
    }
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
    }
}
