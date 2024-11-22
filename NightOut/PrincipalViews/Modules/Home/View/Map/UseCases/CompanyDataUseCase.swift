import Combine
import Foundation

protocol CompanyDataUseCase {
    func getCompanyInfo(uid: String) -> AnyPublisher<CompanyModel?, Never>
}

struct CompanyDataUseCaseImpl: CompanyDataUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func getCompanyInfo(uid: String) -> AnyPublisher<CompanyModel?, Never> {
        return repository
            .getCompanyInfo(uid: uid)
            .eraseToAnyPublisher()
    }
}
