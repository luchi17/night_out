import SwiftUI
import Firebase
import Kingfisher

struct PostModel: Hashable {
    var profileImageUrl: String?
    var postImage: String?
    var description: String?
    var location: String?
    var username: String?
    var uid: String
}

struct PostView: View {
    var model: PostModel
    var openMaps: InputClosure<String> //username --> find location
    var showUserProfile: InputClosure<String> //UID
    
    var body: some View {
        VStack {
            
            topView
            
            if let postImage = model.postImage {
                KFImage.url(URL(string: postImage))
                    .resizable()
                    .scaledToFill()
    
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
                KFImage.url(URL(string: profileImageUrl))
                    .resizable()
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
                        //Show user profile
                    }
                Button {
                    if let username = model.username {
                        openMaps(username)
                    }
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
                Text(model.description ?? "")
                    .font(.subheadline)
                    .foregroundColor(.white)

                // TODO
                Text("Unknown" )
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text("View all comments: TODO")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            Spacer()
            
            Button {
                // Show comments
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

