import Combine
import Foundation

protocol NotificationsRepository {
    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never>
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never>
    func removeNotificationFromFirebase(notificationId: String)
    func sendNotificationToFollowers(clubName: String)
}

struct NotificationsRepositoryImpl: NotificationsRepository {
    static let shared: NotificationsRepository = NotificationsRepositoryImpl()

    private let network: NotificationsDatasource

    init(
        network: NotificationsDatasource = NotificationsDatasourceImpl()
    ) {
        self.network = network
    }
    
    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never> {
        return network
            .fetchNotifications(publisherId: publisherId)
            .eraseToAnyPublisher()
    }
    
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never> {
        return network
            .addNotification(model: model, publisherId: publisherId)
            .eraseToAnyPublisher()
    }
    
    func removeNotificationFromFirebase(notificationId: String) {
        network
            .removeNotificationFromFirebase(notificationId: notificationId)
    }
    
    func sendNotificationToFollowers(clubName: String) {
        network
            .sendNotificationToFollowers(clubName: clubName)
    }

    
}

