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
}

