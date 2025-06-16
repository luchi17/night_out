import Combine
import Foundation

public protocol UserDataUseCase {
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never>
    func findUserByEmail(_ email: String) -> AnyPublisher<UserModel?, Never>
}

struct UserDataUseCaseImpl: UserDataUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never> {
        return repository
            .getUserInfo(uid: uid)
            .eraseToAnyPublisher()
    }
    
    func findUserByEmail(_ email: String) -> AnyPublisher<UserModel?, Never> {
        return repository
            .findUserByEmail(email)
            .eraseToAnyPublisher()
    }
}
