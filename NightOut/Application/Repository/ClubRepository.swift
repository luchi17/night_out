import Combine
import Foundation

protocol ClubRepository {
    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never>
    func getClubName(profileId: String) -> AnyPublisher<String?, Never>
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
            .getAssistance(profileId: profileId)
            .eraseToAnyPublisher()
    }
    
    func getClubName(profileId: String) -> AnyPublisher<String?, Never> {
        network
            .getClubName(profileId: profileId)
            .eraseToAnyPublisher()
    }
    
}
