import Combine
import Foundation

protocol LocationRepository {
    func fetchCompanyLocations() -> AnyPublisher<CompanyUsersModel?, Never>
    func fetchAttendanceData() -> AnyPublisher<[String: Int], Never>
}

struct LocationRepositoryImpl: LocationRepository {
    static let shared: LocationRepository = LocationRepositoryImpl()

    private let network: LocationDatasource

    init(
        network: LocationDatasource = LocationDatasourceImpl()
    ) {
        self.network = network
    }

    func fetchCompanyLocations() -> AnyPublisher<CompanyUsersModel?, Never> {
        return network
            .fetchCompanyLocations()
            .eraseToAnyPublisher()
    }
    
    func fetchAttendanceData() -> AnyPublisher<[String: Int], Never> {
        return network
            .fetchAttendanceData()
            .eraseToAnyPublisher()
    }
}

