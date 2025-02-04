import Combine
import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import FirebaseStorage

protocol NotificationsDatasource {
    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never>
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never>
    func removeNotificationFromFirebase(notificationId: String)
    func sendNotificationToFollowers(clubName: String)
    func addNotificationClub(followerId: String, clubName: String)
}

struct NotificationsDatasourceImpl: NotificationsDatasource {
    
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { promise in
            
            let commentData = structToDictionary(model)
            let ref = FirebaseServiceImpl.shared.getNotifications().child(publisherId)
            
            ref.childByAutoId().setValue(commentData) { error, _ in
                if let error = error {
                    print("Error al guardar la notificacion en la base de datos: \(error.localizedDescription)")
                    promise(.success(false))
                } else {
                    print("Notiticacion guardada exitosamente en la base de datos")
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
        
    }
    
    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never> {
        return Future<[String: NotificationModel], Never> { promise in
            let ref = FirebaseServiceImpl.shared.getNotifications().child(publisherId)
            
            ref.getData { error, snapshot in
                guard error == nil else {
                    print("Error fetching data: \(error!.localizedDescription)")
                    promise(.success([:]))
                    return
                }
                
                do {
                    if let notifications = try snapshot?.data(as: [String: NotificationModel].self) {
                        promise(.success(notifications))
                    } else {
                        promise(.success([:]))
                    }
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                    promise(.success([:]))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func removeNotificationFromFirebase(notificationId: String) {
        
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        let ref = FirebaseServiceImpl.shared.getNotifications().child(currentUserId).child(notificationId)
        
        ref.removeValue()
    }
    
    func sendNotificationToFollowers(clubName: String) {
        
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        let myFollowersRef = FirebaseServiceImpl.shared.getFollow()
            .child(currentUserId)
            .child("Followers")
        
        myFollowersRef.observeSingleEvent(of: .value) { snapshot in
            for child in snapshot.children {
                if let followerSnapshot = child as? DataSnapshot {
                    let followerId = followerSnapshot.key
                    
                    self.addNotificationClub(followerId: followerId, clubName: clubName)
                }
            }
        } withCancel: { error in
            print("Error fetching followers: \(error.localizedDescription)")
        }
    }
    
    // Enviar notificación a cada seguidor mio con el nombre del club
    func addNotificationClub(followerId: String, clubName: String) {

        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        let notificationRef = FirebaseServiceImpl.shared
            .getNotifications()
            .child(followerId)
            .childByAutoId()
        
        let notificationModel = NotificationModel(
            ispost: false,
            postid: "",
            text: "is attending \(clubName)",
            userid: currentUserId,
            date: Date().toIsoString()
        )
        let notificationData = structToDictionary(notificationModel)
        
        notificationRef.setValue(notificationData) { error, _ in
            if let error = error {
                print("Error adding notification for \(followerId): \(error.localizedDescription)")
            } else {
                print("Notification sent to \(followerId) for club \(clubName)")
            }
        }
    }
}

