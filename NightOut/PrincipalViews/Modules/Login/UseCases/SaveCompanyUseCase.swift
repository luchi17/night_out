import Combine
import FirebaseAuth

protocol SaveCompanyUseCase {
    func execute(model: CompanyModel) -> AnyPublisher<Bool, Never>
    func executeGetImageUrl(imageData: Data) -> AnyPublisher<String?, Never>
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
    
    func executeGetImageUrl(imageData: Data) -> AnyPublisher<String?, Never> {
        return repository
            .getUrlCompanyImage(imageData: imageData)
            .eraseToAnyPublisher()
    }
}

