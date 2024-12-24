import Combine

protocol ClubUseCase {
    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never>
    func getClubName(profileId: String) -> AnyPublisher<String?, Never>
}

struct ClubUseCaseImpl: ClubUseCase {
    private let repository: ClubRepository

    init(repository: ClubRepository) {
        self.repository = repository
    }

    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never> {
        return repository
            .observeAssistance(profileId: profileId)
            .eraseToAnyPublisher()
    }
    
    func getClubName(profileId: String) -> AnyPublisher<String?, Never> {
        return repository
            .getClubName(profileId: profileId)
            .eraseToAnyPublisher()
    }
}


