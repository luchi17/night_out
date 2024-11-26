import SwiftUI
import Firebase

struct PostModel: Hashable {
    var profileImageUrl: String?
    var postImage: String?
    var description: String?
    var location: String?
    var username: String?
    var publisher: String?
    var uid: String
    var isFromUser: Bool
    var publisherId: String?
}

struct PostView: View {
    var model: PostModel
    var openMaps: InputClosure<PostModel>
    var showUserOrCompanyProfile: VoidClosure
    var showPostComments: VoidClosure
    
    var body: some View {
        VStack {
            
            topView
            
            if let postImage = model.postImage {
                KingFisherImage(url: URL(string: postImage))
                    .centerCropped(width: .infinity, height: 300, placeholder: {
                        ProgressView()
                    })
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 300)
            }
            
            bottomView
        }
        .background(Color.black.opacity(0.7))
        
    }
    
    var topView: some View {
        HStack(spacing: 10) {
            // Imagen de perfil del usuario
            if let profileImageUrl = model.profileImageUrl {
                KingFisherImage(url: URL(string: profileImageUrl))
                    .placeholder(Image("placeholder"))
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 50, height: 50, alignment: .leading)
                    .onTapGesture {
                        //Show user profile
                    }
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 50, height: 50, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(model.username ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        showUserOrCompanyProfile()
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
        .padding(.vertical, 5)
    }
    
    var bottomView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                // Descripción
                Text(model.publisher ?? "Unknown")
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text(model.description ?? "Unknown")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text("View all comments: TODO")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            Spacer()
            
            Button {
                showPostComments()
            } label: {
                Image(systemName: "text.bubble")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40, alignment: .trailing)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 5)
    }
}

