import Combine
import Foundation

protocol ClubRepository {
    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never>
}

struct ClubRepositoryImpl: ClubRepository {
    
    static let shared: ClubRepository = ClubRepositoryImpl()

    private let network: ClubDataSource

    init(
        network: ClubDataSource = ClubDataSourceImpl()
    ) {
        self.network = network
    }
    
    func observeAssistance(profileId: String) -> AnyPublisher<[String : ClubAssistance], Never> {
        network
            .observeAssistance(profileId: profileId)
            .eraseToAnyPublisher()
    }
    
}
