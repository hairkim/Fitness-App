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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                Text("Streak: \(entry.streak)")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
            }

            Spacer()

            Text("\(entry.streak)")
                .font(.system(size: 22, weight: .bold))
                .padding(12)
                .background(background(for: rank))
                .clipShape(Circle())
                .foregroundColor(.black)
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
            return AnyView(Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 24, weight: .bold)))
        case 2:
            return AnyView(Image(systemName: "star.fill")
                .foregroundColor(Color.silver)
                .font(.system(size: 24, weight: .bold)))
        case 3:
            return AnyView(Image(systemName: "star.fill")
                .foregroundColor(Color.bronze)
                .font(.system(size: 24, weight: .bold)))
        default:
            return AnyView(Text("\(rank)").foregroundColor(.black))
        }
    }

    func background(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color.silver
        case 3: return Color.bronze
        default: return .clear
        }
    }
    
    func rowBackground(for rank: Int) -> Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.19)
        case 2: return Color.silver.opacity(0.17)
        case 3: return Color.bronze.opacity(0.17)
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
        LeaderboardView(leaderboardData: [
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
        ])
    }
}
