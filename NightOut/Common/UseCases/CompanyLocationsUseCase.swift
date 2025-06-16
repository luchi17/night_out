import Combine
import Foundation

protocol CompanyLocationsUseCase {
    func fetchCompanyLocations() -> AnyPublisher<CompanyUsersModel?, Never>
    func fetchAttendanceData() -> AnyPublisher<[String: Int], Never>
}

struct CompanyLocationsUseCaseImpl: CompanyLocationsUseCase {
    private let repository: LocationRepository

    init(repository: LocationRepository) {
        self.repository = repository
    }

    func fetchCompanyLocations() -> AnyPublisher<CompanyUsersModel?, Never> {
        return repository
            .fetchCompanyLocations()
            .eraseToAnyPublisher()
    }
    
    func fetchAttendanceData() -> AnyPublisher<[String: Int], Never> {
        return repository
            .fetchAttendanceData()
            .eraseToAnyPublisher()
    }
}
