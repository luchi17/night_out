import Combine
import Foundation

protocol NotificationsRepository {
    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never>
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never>
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

    
}

