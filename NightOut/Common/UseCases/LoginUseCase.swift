import Combine
import FirebaseAuth
import GoogleSignIn

protocol LoginUseCase {
    func execute(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError>
    func executeApple() -> AnyPublisher<Void, Error>
    func executeGoogle() -> AnyPublisher<GIDGoogleUser, Error>
}

struct LoginUseCaseImpl: LoginUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError> {
        return repository
            .login(email: email, password: password)
            .eraseToAnyPublisher()
    }
    
    func executeApple() -> AnyPublisher<Void, Error> {
        return .empty()
    }
    
    func executeGoogle() -> AnyPublisher<GIDGoogleUser, Error> {
        return repository
            .loginGoogle()
            .eraseToAnyPublisher()
    }
}
