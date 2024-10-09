import Combine
import FirebaseAuth

protocol SignupUseCase {
    func execute(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError>
}

struct SignupUseCaseImpl: SignupUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError> {
        return repository
            .signup(email: email, password: password)
            .eraseToAnyPublisher()
    }
}
