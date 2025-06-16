import SwiftUI
import Firebase

public struct PostModel: Hashable {
    var profileImageUrl: String?
    var postImage: UIImage
    var description: String?
    var location: String?
    var username: String?
    var fullName: String?
    var uid: String
    var isFromUser: Bool
    var publisherId: String
    var timestamp: Int64
    
    public init(profileImageUrl: String?, postImage: UIImage, description: String?, location: String? , username: String?, fullName: String?, uid: String, isFromUser: Bool, publisherId: String, timestamp: Int64) {
        self.profileImageUrl = profileImageUrl
        self.postImage = postImage
        self.description = description
        self.location = location
        self.username = username
        self.fullName = fullName
        self.uid = uid
        self.isFromUser = isFromUser
        self.publisherId = publisherId
        self.timestamp = timestamp
    }
}

struct PostView: View {
    var model: PostModel
    var openMaps: InputClosure<PostModel>
    var showUserOrCompanyProfile: VoidClosure
    var showPostComments: VoidClosure
    
    var body: some View {
        VStack(spacing: 0) {
            
            topView
            
            Image(uiImage: model.postImage)
            .resizable()
            .scaledToFill()
            .frame(height: 300)
            .clipped()
            .allowsHitTesting(false)
            
            bottomView
        }
        .background(Color.blackColor)
        
    }
    
    var topView: some View {
        HStack(spacing: 10) {
            CircleImage(
                imageUrl: model.profileImageUrl,
                size: 50,
                border: false
            )
            .onTapGesture {
                showUserOrCompanyProfile()
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Button {
                    showUserOrCompanyProfile()
                } label: {
                    Text(model.username ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button {
                    openMaps(model)
                } label: {
                    Text(model.location ?? "")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
    
    var bottomView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                // Descripción
                Text(model.fullName ?? "Unknown")
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text(model.description ?? "Unknown")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            Spacer()
            
            Button {
                showPostComments()
            } label: {
                Image("comment")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40, alignment: .trailing)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

