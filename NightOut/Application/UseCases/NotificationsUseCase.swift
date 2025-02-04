import Combine
import FirebaseAuth

protocol NotificationsUseCase {
    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never>
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never>
    func removeNotification(notificationId: String)
    func sendNotificationToFollowers(clubName: String)
}

struct NotificationsUseCaseImpl: NotificationsUseCase {
    private let repository: NotificationsRepository

    init(repository: NotificationsRepository) {
        self.repository = repository
    }

    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never> {
        return repository
            .fetchNotifications(publisherId: publisherId)
            .eraseToAnyPublisher()
    }
    
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never> {
        return repository
            .addNotification(model: model, publisherId: publisherId)
            .eraseToAnyPublisher()
    }
    
    func removeNotification(notificationId: String) {
       repository
            .removeNotificationFromFirebase(notificationId: notificationId)
    }
    
    func sendNotificationToFollowers(clubName: String) {
        repository
            .sendNotificationToFollowers(clubName: clubName)
    }

}


