import Combine
import FirebaseAuth

protocol SignOutUseCase {
    func execute() -> AnyPublisher<Void, Error>
}

struct SignOutUseCaseImpl: SignOutUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<Void, Error> {
        return repository
            .signOut()
            .eraseToAnyPublisher()
    }
}
