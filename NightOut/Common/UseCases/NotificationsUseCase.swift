import Combine
import FirebaseAuth

public protocol NotificationsUseCase {
    func observeNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never>
    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never>
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never>
    func removeNotification(userId: String, notificationId: String)
    func sendNotificationToFollowers(myName: String, clubName: String)
}

struct NotificationsUseCaseImpl: NotificationsUseCase {
    private let repository: NotificationsRepository

    init(repository: NotificationsRepository) {
        self.repository = repository
    }

    func observeNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never> {
        return repository
            .observeNotifications(publisherId: publisherId)
            .eraseToAnyPublisher()
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
    
    func removeNotification(userId: String, notificationId: String) {
       repository
            .removeNotificationFromFirebase(userId:userId, notificationId: notificationId)
    }
    
    func sendNotificationToFollowers(myName: String, clubName: String) {
        repository
            .sendNotificationToFollowers(myName: myName, clubName: clubName)
    }

}


