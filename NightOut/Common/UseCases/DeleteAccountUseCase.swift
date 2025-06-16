import Combine
import FirebaseAuth

protocol DeleteAccountUseCase {
    func execute() -> AnyPublisher<String?, Never>
}

struct DeleteAccountUseCaseImpl: DeleteAccountUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<String?, Never> {
        return repository
            .deleteAccount()
            .eraseToAnyPublisher()
    }
}

