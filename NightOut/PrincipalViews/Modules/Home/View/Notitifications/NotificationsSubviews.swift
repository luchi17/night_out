import SwiftUI


struct NotificationModelForView {
    var isPost: Bool
    var text: String
    var userName: String
    var type: NotificationType
    var profileImage: String?
    var postImage: String?
    var userId: String
    var postId: String
    let uid = UUID()
}


struct FriendRequestView: View {
    var notification: NotificationModelForView
    var onAccept: InputClosure<String>
    var onReject: InputClosure<String>
    var goToProfile: InputClosure<String>
    
    var body: some View {
        HStack {
            // Imagen de perfil
            CircleImage(imageUrl: notification.profileImage)
                .onTapGesture {
                    goToProfile(notification.userId)
                }
            
            VStack(alignment: .leading) {
                Text(notification.userName)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Solicitud de seguimiento")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
           
            if notification.type == .friendRequest {
                HStack {
                    Button(action: { onReject(notification.userId) }) {
                        Text("X")
                            .font(.system(size: 18))
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(20)
                    }
                    .padding(.leading)
                    
                    Button(action: { onAccept(notification.userId) } ) {
                        Text("✓")
                            .font(.system(size: 18))
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .background(Color.green)
                            .cornerRadius(20)
                    }
                    .padding(.leading)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
    }
}

struct DefaultNotificationView: View {
    
    var notification: NotificationModelForView
    var goToPost: InputClosure<String>
    var goToProfile: InputClosure<String>

    var body: some View {
        HStack(alignment: .center, spacing: 10) {

            CircleImage(imageUrl: notification.profileImage)
                .onTapGesture {
                    goToProfile(notification.userId)
                }
            
            VStack(alignment: .leading) {
                Text(notification.userName)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(notification.text)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            if notification.isPost, let postImage = notification.postImage {
                KingFisherImage(url: URL(string: postImage))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .padding(.trailing)
                    .onTapGesture {
                        goToPost(notification.postId)
                    }
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .padding(.trailing)
                    .onTapGesture {
                        goToPost(notification.postId)
                    }
                    
            }
        }
        .padding(6)
        .background(Color.black.opacity(0.5)) // Agregar un fondo oscuro para resaltar el contenido
        .cornerRadius(10)
    }
}

struct CircleImage: View {
    var imageUrl: String?
    
    var body: some View {
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            KingFisherImage(url: url)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .frame(width: 60, height: 60)
        } else {
            Image(systemName: "person.crop.circle") //person.circle.fill"
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .frame(width: 60, height: 60)
        }
    }
}


