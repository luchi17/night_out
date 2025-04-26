import Combine
import Foundation

protocol ClubRepository {
    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never>
    func removeAssistingToClub(clubId: String) -> AnyPublisher<Bool, Never>
    func addAssistingToClub(clubId: String, clubAssistance: ClubAssistance) -> AnyPublisher<Bool, Never>
    func getAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never>
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
    
    func removeAssistingToClub(clubId: String) -> AnyPublisher<Bool, Never> {
        network
            .removeAssistingToClub(clubId: clubId)
            .eraseToAnyPublisher()
    }
    
    func addAssistingToClub(clubId: String, clubAssistance: ClubAssistance) -> AnyPublisher<Bool, Never> {
        network
            .addAssistingToClub(clubId: clubId, clubAssistance: clubAssistance)
            .eraseToAnyPublisher()
    }
    
    func getAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never> {
        network
            .getAssistance(profileId: profileId)
            .eraseToAnyPublisher()
    }
}
