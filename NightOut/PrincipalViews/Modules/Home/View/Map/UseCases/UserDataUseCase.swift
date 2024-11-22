import Combine
import Foundation

protocol UserDataUseCase {
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never>
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
}
