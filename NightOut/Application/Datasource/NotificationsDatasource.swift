import Combine
import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import FirebaseStorage

protocol NotificationsDatasource {
    func observeNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never>
    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never>
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never>
    func removeNotificationFromFirebase(userId: String, notificationId: String)
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
        let subject = CurrentValueSubject<[String: NotificationModel], Never>([:])
        
        let ref = FirebaseServiceImpl.shared.getNotifications().child(publisherId)
        
        ref.observeSingleEvent(of: .value) { snapshot in
            do {
                let notifs = try snapshot.data(as: [String: NotificationModel].self)
                subject.send(notifs)
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                subject.send([:])
            }
        }
        return subject.eraseToAnyPublisher()
    }
    
    func observeNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never> {
        let subject = CurrentValueSubject<[String: NotificationModel], Never>([:])
        
        let ref = FirebaseServiceImpl.shared.getNotifications().child(publisherId)
        
        ref.observe(.value) { snapshot in
            do {
                let notifs = try snapshot.data(as: [String: NotificationModel].self)
                subject.send(notifs)
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                subject.send([:])
            }
        }
        return subject.eraseToAnyPublisher()
    }
    
    func removeNotificationFromFirebase(userId: String, notificationId: String) {
        
        let ref = FirebaseServiceImpl.shared.getNotifications().child(userId).child(notificationId)
        
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
            userid: currentUserId
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

