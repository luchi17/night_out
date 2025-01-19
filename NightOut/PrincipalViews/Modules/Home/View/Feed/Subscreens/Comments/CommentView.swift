import Combine
import SwiftUI

struct UserCommentModel {
    var userImageUrl: String?
    var username: String?
    var comment: String?
    let uid = UUID()
}

struct CommentView: View  {
    var commentModel: UserCommentModel
    
    var body: some View {
        
        HStack(spacing: 8) {
            if let userImageUrl = commentModel.userImageUrl {
                KingFisherImage(url: URL(string: userImageUrl))
                    .placeholder({
                        Image("profile")
                            .clipShape(Circle())
                    })
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
            
            VStack(spacing: 5) {
                Text(commentModel.username ?? "Unknown")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(commentModel.comment ?? "")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 2)
        }
        .padding(.vertical, 5)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.9))
    }
}
