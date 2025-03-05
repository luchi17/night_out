import SwiftUI

import Foundation

struct UserRanking: Identifiable {
    let id = UUID()
    let uid: String
    let username: String
    let drinks: Int
    var position: Int = 0
    var rank: RankingType = .normal
    let isCurrentUser: Bool
    
    enum RankingType {
        case gold
        case silver
        case bronze
        case normal
    }
}
struct RankingRow: View {
    let user: UserRanking
    
    var body: some View {
        HStack {
            Text("\(user.position)")
                .font(.title)
                .bold()
            
            Text(user.username)
                .font(.headline)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if user.rank == .gold {
                Text("🏆 \(user.drinks)")
                    .font(.subheadline)
            } else {
                Text("\(user.drinks)")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(16)
        .shadow(radius: 3)
        .padding(.horizontal)
        .modifier(BounceAnimationModifier(active: user.rank == .gold))
    }
    
    var backgroundColor: Color {
        switch user.rank {
        case .gold: return Color.yellow.opacity(0.8)
        case .silver: return Color.gray.opacity(0.8)
        case .bronze: return Color.brown.opacity(0.8)
        case .normal: return Color.white
        }
    }
    
    var textColor: Color {
        user.isCurrentUser ? .red : .black
    }
}

struct BounceAnimationModifier: ViewModifier {
    @State private var bounce = false
    let active: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(y: bounce ? -10 : 0)
            .animation(active ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: bounce)
            .onAppear {
                if active { bounce.toggle() }
            }
    }
}

