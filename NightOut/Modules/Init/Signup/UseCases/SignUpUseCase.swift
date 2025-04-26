import Combine
import FirebaseAuth

protocol SignupUseCase {
    func execute(email: String, password: String) -> AnyPublisher<String, SignupNetworkError>
    func executeCompany(email: String, password: String) -> AnyPublisher<String, SignupNetworkError>
}

struct SignupUseCaseImpl: SignupUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) -> AnyPublisher<String, SignupNetworkError> {
        return repository
            .signup(email: email, password: password)
            .eraseToAnyPublisher()
    }
    
    func executeCompany(email: String, password: String) -> AnyPublisher<String, SignupNetworkError> {
        return repository
            .signupCompany(email: email, password: password)
            .eraseToAnyPublisher()
    }
}
