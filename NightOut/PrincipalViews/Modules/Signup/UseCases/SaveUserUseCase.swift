import Combine
import FirebaseAuth

protocol SaveUserUseCase {
    func execute(model: UserModel) -> AnyPublisher<Bool, Never>
    func executeTerms() -> AnyPublisher<Bool, Never>
}

struct SaveUserUseCaseImpl: SaveUserUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func execute(model: UserModel) -> AnyPublisher<Bool, Never> {
        return repository
            .saveUser(model: model)
            .eraseToAnyPublisher()
    }
    
    func executeTerms() -> AnyPublisher<Bool, Never> {
        return repository
            .executeTerms()
            .eraseToAnyPublisher()
    }
}

