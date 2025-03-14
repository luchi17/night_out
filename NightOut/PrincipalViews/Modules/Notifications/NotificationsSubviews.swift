import SwiftUI

struct NotificationModelForView {
    var isPost: Bool
    var text: String
    var userName: String
    var fullName: String
    var type: NotificationType
    var profileImage: String?
    var postImage: String?
    var userId: String
    var postId: String
    let notificationId: String
    let isFromCompany: Bool
    let isPrivateProfile: Bool
}

struct FriendRequestNotificationView: View {
    var notification: NotificationModelForView
    var onAccept: InputClosure<(String, String)>
    var onReject: InputClosure<(String, String)>
    var goToProfile: InputClosure<NotificationModelForView>
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Imagen de perfil
            CircleImage(imageUrl: notification.profileImage)
                .onTapGesture {
                    goToProfile(notification)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.userName)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(GlobalStrings.shared.followUserText)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 5)
            .onTapGesture {
                goToProfile(notification)
            }
           
            Spacer()
            
            if notification.type == .friendRequest {
                HStack(spacing: 8) {
                    Button(action: {
                        onReject((notification.notificationId, notification.userId))
                    }) {
                        Text("X")
                            .font(.system(size: 20))
                            .frame(width: 45, height: 45)
                            .foregroundColor(.white)
                            .background(Color.red)
                    }
                    
                    Button(action: {
                        onAccept((notification.notificationId, notification.userId))
                    } ) {
                        Text("✓")
                            .font(.system(size: 20))
                            .frame(width: 45, height: 45)
                            .foregroundColor(.white)
                            .background(Color.green)
                    }
                    
                }
            }
        }
        .padding(.all, 10)
        .cornerRadius(10)
    }
}

struct DefaultNotificationView: View {
    
    var notification: NotificationModelForView
    var goToPost: InputClosure<NotificationModelForView>
    var goToProfile: InputClosure<NotificationModelForView>

    var body: some View {
        HStack(alignment: .center, spacing: 10) {

            CircleImage(imageUrl: notification.profileImage)
            
            Text(notification.text)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)
                .onTapGesture {
                    goToProfile(notification)
                }
            
            Spacer()
            
            if notification.isPost {
                if let postImage = notification.postImage {
                    AsyncImage(url: URL(string: postImage)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipped()
                            .onTapGesture {
                                goToPost(notification)
                            }
                    } placeholder: {
                        Image(systemName: "photo.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipped()
                            .onTapGesture {
                                goToPost(notification)
                            }
                    }
                    
                } else {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .onTapGesture {
                            goToPost(notification)
                        }
                }
            }
        }
        .padding(.all, 10)
        .cornerRadius(10)
    }
}

struct CircleImage: View {
    var imageUrl: String?
    var size: CGFloat = 60.0
    var border: Bool = true
    
    var body: some View {
        if let imageUrl = imageUrl {
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: size, height: size)
                    .if(border) { view in
                        view
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
            } placeholder: {
                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: size, height: size)
                    .if(border) { view in
                        view
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
            }
        } else {
            Image("profile")
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: size, height: size)
                .if(border) { view in
                    view
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
        }
    }
}


