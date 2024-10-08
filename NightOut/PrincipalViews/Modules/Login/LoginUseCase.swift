import Combine
import FirebaseAuth

protocol LoginUseCase {
    func execute(email: String, password: String) -> AnyPublisher<Void?, LoginNetworkError>
}

struct LoginUseCaseImpl: LoginUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) -> AnyPublisher<Void?, LoginNetworkError> {
        return repository
            .login(email: email, password: password)
            .eraseToAnyPublisher()
    }
}
