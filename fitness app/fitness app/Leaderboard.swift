import SwiftUI

struct LeaderboardView: View {
    let leaderboardData: [LeaderboardEntry]

    var body: some View {
        ZStack {
            Color(red: 245 / 255, green: 245 / 255, blue: 220 / 255)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(leaderboardData.indices, id: \.self) { index in
                            LeaderboardRowView(entry: leaderboardData[index], rank: index + 1)
                            if index < leaderboardData.count - 1 {
                                Divider().background(Color.black)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
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
                .font(.system(size: 22, weight: .bold))
                .frame(width: 40, alignment: .center)

            VStack(alignment: .leading) {
                Text(entry.name)
                    .font(.headline)
                    .foregroundColor(.black)
                Text("Streak: \(entry.streak)")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }

            Spacer()

            Text("\(entry.streak)")
                .font(.headline)
                .padding(8)
                .background(background(for: rank))
                .clipShape(Circle())
                .foregroundColor(.white)
        }
        .padding()
        .background(rowBackground(for: rank))
        .cornerRadius(10)
    }

    func specialRankIcon(for rank: Int) -> some View {
        switch rank {
        case 1:
            return AnyView(Image(systemName: "star.fill")
                .foregroundColor(.yellow))
        case 2:
            return AnyView(Image(systemName: "star.fill")
                .foregroundColor(Color.silver))
        case 3:
            return AnyView(Image(systemName: "star.fill")
                .foregroundColor(Color.bronze))
        default:
            return AnyView(Text("\(rank)").foregroundColor(.black))
        }
    }

    func background(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color.silver
        case 3: return Color.bronze
        default: return .gray
        }
    }
    
    func rowBackground(for rank: Int) -> Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.3)
        case 2: return Color.silver.opacity(0.3)
        case 3: return Color.bronze.opacity(0.3)
        default: return Color.white.opacity(0.1)
        }
    }
}

extension Color {
    static let silver = Color(UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0))
    static let bronze = Color(UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0))
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView(leaderboardData: [
            LeaderboardEntry(name: "Ryan K", streak: 100),
            LeaderboardEntry(name: "Josh", streak: 90),
            LeaderboardEntry(name: "Friend3", streak: 80),
            LeaderboardEntry(name: "Friend4", streak: 70),
            LeaderboardEntry(name: "Friend5", streak: 60),
            LeaderboardEntry(name: "Friend6", streak: 50),
            LeaderboardEntry(name: "Friend7", streak: 40),
            LeaderboardEntry(name: "Friend8", streak: 30),
            LeaderboardEntry(name: "Harris K", streak: 20),
            LeaderboardEntry(name: "Daniel H", streak: 10)
        ])
    }
}

