import SwiftUI

import Foundation

struct UserRanking: Identifiable {
    let id = UUID()
    let uid: String
    let username: String
    let drinks: Int
    var position: Int = 0
}


struct RankingRow: View {
    let userRanking: UserRanking
    let isCurrentUser: Bool

    var body: some View {
        HStack {
            Text("\(userRanking.position)")
                .bold()
                .foregroundColor(rankColor)
            
            Text(userRanking.username)
                .foregroundColor(isCurrentUser ? .red : .black)
            
            Spacer()
            
            Text("\(userRanking.drinks) Bebidas")
                .bold()
        }
        .padding()
        .background(rankBackground)
        .cornerRadius(8)
    }
    
    private var rankColor: Color {
        switch userRanking.position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .black
        }
    }
    
    private var rankBackground: Color {
        switch userRanking.position {
        case 1: return Color.yellow.opacity(0.3)
        case 2: return Color.gray.opacity(0.3)
        case 3: return Color.brown.opacity(0.3)
        default: return Color.clear
        }
    }
}
