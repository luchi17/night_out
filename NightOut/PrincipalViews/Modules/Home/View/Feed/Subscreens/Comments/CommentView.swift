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
            CircleImage(
                imageUrl: commentModel.userImageUrl,
                size: 40,
                border: false
            )
            .padding(.leading, 5)
            
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
        .shadow(color: Color.blackColor.opacity(0.2), radius: 5, x: 0, y: 2)
        .background(Color.blackColor)
    }
}
