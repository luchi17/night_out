import Combine
import FirebaseAuth

protocol SaveCompanyUseCase {
    func execute(model: CompanyModel) -> AnyPublisher<Bool, Never>
}

struct SaveCompanyUseCaseImpl: SaveCompanyUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func execute(model: CompanyModel) -> AnyPublisher<Bool, Never> {
        return repository
            .saveCompany(model: model)
            .eraseToAnyPublisher()
    }
}

