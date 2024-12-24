import Combine

protocol ClubUseCase {
    func observeAssistance(clubProfileId: String) -> AnyPublisher<[String: ClubAssistance], Never>
    func getClubName(clubProfileId: String) -> AnyPublisher<String?, Never>
}

struct ClubUseCaseImpl: ClubUseCase {
    private let repository: ClubRepository

    init(repository: ClubRepository) {
        self.repository = repository
    }

    func observeAssistance(clubProfileId: String) -> AnyPublisher<[String: ClubAssistance], Never> {
        return repository
            .observeAssistance(profileId: clubProfileId)
            .eraseToAnyPublisher()
    }
    
    func getClubName(clubProfileId: String) -> AnyPublisher<String?, Never> {
        return repository
            .getClubName(profileId: clubProfileId)
            .eraseToAnyPublisher()
    }
}


