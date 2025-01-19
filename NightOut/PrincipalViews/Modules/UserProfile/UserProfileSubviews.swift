import SwiftUI

struct UsersGoingClubSubview: View {
    
    @Binding var users: [UserGoingCellModel]
    let onUserSelected: InputClosure<UserGoingCellModel>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(users) { user in
                    UserGoingCell(
                        model: user,
                        onTap: onUserSelected
                    )
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
        }
        .background(Color.black)
        .frame(height: 120)
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
