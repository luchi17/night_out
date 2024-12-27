// UserGoingToClubAdapter - all
// UserGoingToClubAdapter2 - following

import SwiftUI

struct UsersGoingClubSubview: View {
    
    @State var users: [UserGoingCellModel] = []
    let onUserSelected: InputClosure<UserGoingCellModel>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(users) { user in
                    UserGoingCell(
                        model: user,
                        onTap: onUserSelected
                    )
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.8))
    }
}

struct UserGoingCell: View {
    
    let model: UserGoingCellModel
    let onTap: InputClosure<UserGoingCellModel>
    
    var body: some View {
        VStack(spacing: 10) {
            CircleImage(imageUrl: model.profileImageUrl)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .shadow(radius: 4)
            
            Text(model.username)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(minWidth: 100)
        .padding(.leading, 30)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(model)
        }
    }
}


struct UserGoingCellModel: Identifiable {
    let id: String
    let username: String
    let profileImageUrl: String?
}
