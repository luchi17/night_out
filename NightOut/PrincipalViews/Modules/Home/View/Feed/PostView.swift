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
    
    var body: some View {
        VStack {
            HStack {
                // Imagen de perfil del usuario
                if let profileImageUrl = model.profileImageUrl {
                    KFImage.url(URL(string: profileImageUrl))
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                        .padding()
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                        .padding()
                }

                // Nombre de usuario
                Text(model.username ?? "")
                    .font(.headline)

                Spacer()
            }
            
            if let postImage = model.postImage {
                // Imagen de la publicación
                KFImage.url(URL(string: postImage))
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .padding()
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .padding()
            }
            
            // Descripción
            Text(model.description ?? "")
                .padding()
                .foregroundColor(.gray)

            // Ubicación
            Text(model.location ?? "" )
                .font(.subheadline)
                .padding(.bottom)
        }
        .padding()
    }
}

