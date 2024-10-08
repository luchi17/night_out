import Combine
import Foundation

protocol AccountRepository {
    func login(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError>
    func signup(email: String, password: String) -> AnyPublisher<Void, Error>
}

struct AccountRepositoryImpl: AccountRepository {
    static let shared: AccountRepository = AccountRepositoryImpl()

    private let network: AccountDatasource

    init(
        network: AccountDatasource = AccountDatasourceImpl()
    ) {
        self.network = network
    }

    func login(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError> {
        return network
            .login(email: email, password: password)
            .eraseToAnyPublisher()
    }
    
    func signup(email: String, password: String) -> AnyPublisher<Void, Error> {
        return network
            .signup(email: email, password: password)
            .eraseToAnyPublisher()
    }
    
    
}
