import Combine
import Foundation

protocol NotificationsRepository {
    func observeNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never>
    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never>
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never>
    func removeNotificationFromFirebase(userId: String, notificationId: String)
    func sendNotificationToFollowers(myName: String, clubName: String)
}

struct NotificationsRepositoryImpl: NotificationsRepository {
    static let shared: NotificationsRepository = NotificationsRepositoryImpl()

    private let network: NotificationsDatasource

    init(
        network: NotificationsDatasource = NotificationsDatasourceImpl()
    ) {
        self.network = network
    }
    
    func observeNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never> {
        return network
            .observeNotifications(publisherId: publisherId)
            .eraseToAnyPublisher()
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
    
    func removeNotificationFromFirebase(userId: String, notificationId: String) {
        network
            .removeNotificationFromFirebase(userId: userId, notificationId: notificationId)
    }
    
    func sendNotificationToFollowers(myName: String, clubName: String) {
        network
            .sendNotificationToFollowers(myName: myName, clubName: clubName)
    }

    
}

